-- Day 8 / Set 2: Fare ranking and running revenue per flight
USE Day8AirlineBooking;
GO
-- Add a few bookings for report practice if the seat is still available.
-- The booking transaction file can be run first; this block only inserts unused sample seats.
INSERT INTO Bookings(passenger_id,seat_id,fare)
SELECT v.passenger_id,v.seat_id,v.fare
FROM (VALUES(2,1002,8500.00),(3,1003,7200.00),(4,2001,9000.00),(1,2002,9000.00)) v(passenger_id,seat_id,fare)
WHERE NOT EXISTS(SELECT 1 FROM Bookings b WHERE b.seat_id=v.seat_id);
UPDATE s SET seat_status='Booked'
FROM Seats s JOIN Bookings b ON b.seat_id=s.seat_id;
GO
;WITH FareRanks AS (
 SELECT f.flight_id,f.flight_number,p.passenger_name,s.seat_number,b.fare,b.booked_at,
        RANK() OVER(PARTITION BY f.flight_id ORDER BY b.fare DESC) AS fare_rank,
        DENSE_RANK() OVER(PARTITION BY f.flight_id ORDER BY b.fare DESC) AS dense_fare_rank,
        ROW_NUMBER() OVER(PARTITION BY f.flight_id ORDER BY b.fare DESC,b.booking_id) AS row_num,
        SUM(b.fare) OVER(PARTITION BY f.flight_id ORDER BY b.booked_at,b.booking_id
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue
 FROM Bookings b JOIN Passengers p ON p.passenger_id=b.passenger_id
 JOIN Seats s ON s.seat_id=b.seat_id JOIN Flights f ON f.flight_id=s.flight_id
 WHERE b.booking_status='Confirmed'
)
SELECT flight_number,passenger_name,seat_number,fare,
       fare_rank,dense_fare_rank,row_num,running_revenue
FROM FareRanks
ORDER BY flight_id,fare DESC,passenger_name;
