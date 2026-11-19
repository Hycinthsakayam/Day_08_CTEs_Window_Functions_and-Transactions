-- Day 8 / Set 2: Atomic seat booking
USE Day8AirlineBooking;
GO
DECLARE @PassengerId INT=1,@SeatId INT=1001,@Fare DECIMAL(10,2)=8500,
        @SeatStatus VARCHAR(15);

BEGIN TRY
 SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
 BEGIN TRANSACTION;

 -- HOLDLOCK keeps the seat/range protected until commit. UPDLOCK avoids a read-then-write race.
 SELECT @SeatStatus=seat_status
 FROM Seats WITH(UPDLOCK,HOLDLOCK)
 WHERE seat_id=@SeatId;

 IF @SeatStatus IS NULL THROW 52000,'Seat does not exist.',1;
 IF @SeatStatus<>'Available' THROW 52001,'Seat is already booked.',1;
 IF NOT EXISTS(SELECT 1 FROM Passengers WHERE passenger_id=@PassengerId)
   THROW 52002,'Passenger is not registered.',1;

 INSERT INTO Bookings(passenger_id,seat_id,fare)
 VALUES(@PassengerId,@SeatId,@Fare);

 UPDATE Seats SET seat_status='Booked'
 WHERE seat_id=@SeatId AND seat_status='Available';
 IF @@ROWCOUNT<>1 THROW 52003,'Seat status could not be updated.',1;

 COMMIT TRANSACTION;
 PRINT 'Booking successful.';
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 PRINT CONCAT('Booking failed: ',ERROR_MESSAGE());
END CATCH;
GO
SELECT b.booking_id,p.passenger_name,f.flight_number,s.seat_number,b.fare,b.booking_status
FROM Bookings b JOIN Passengers p ON p.passenger_id=b.passenger_id
JOIN Seats s ON s.seat_id=b.seat_id JOIN Flights f ON f.flight_id=s.flight_id;
