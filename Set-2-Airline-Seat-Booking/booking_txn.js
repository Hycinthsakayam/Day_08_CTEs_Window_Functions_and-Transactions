// Day 8 / Set 2: MongoDB transactional seat booking
// Requires a replica set or sharded cluster. Run: mongosh booking_txn.js
use('day8_airline_booking');
db.passengers.deleteMany({}); db.seats.deleteMany({}); db.bookings.deleteMany({});
db.passengers.insertMany([{_id:1,name:'Aadhya'},{_id:2,name:'Bala'}]);
db.seats.insertMany([
 {_id:1001,flight_id:10,seat_number:'1A',status:'Available'},
 {_id:1002,flight_id:10,seat_number:'1B',status:'Available'}
]);

const session=db.getMongo().startSession();
try {
 const airline=session.getDatabase('day8_airline_booking');
 session.startTransaction();
 const passenger=airline.passengers.findOne({_id:1});
 if (!passenger) throw new Error('Passenger is not registered');

 const seatUpdate=airline.seats.updateOne(
   {_id:1001,status:'Available'},
   {$set:{status:'Booked',booked_by:passenger._id}}
 );
 if (seatUpdate.modifiedCount!==1) throw new Error('Seat is no longer available');

 airline.bookings.insertOne({
   passenger_id:passenger._id,seat_id:1001,flight_id:10,
   fare:8500,status:'Confirmed',booked_at:new Date()
 });
 session.commitTransaction();
 print('Seat and booking saved together');
} catch(error) {
 if(session.inTransaction()) session.abortTransaction();
 print('Booking rolled back: '+error.message);
} finally {
 session.endSession();
}
db.seats.find().forEach(print);
db.bookings.find().forEach(print);
