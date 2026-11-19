-- Day 8 / Set 2: Airline Seat Booking
IF DB_ID('Day8AirlineBooking') IS NULL CREATE DATABASE Day8AirlineBooking;
GO
USE Day8AirlineBooking;
GO
DROP TABLE IF EXISTS Bookings, Seats, Flights, Passengers;
GO
CREATE TABLE Passengers(passenger_id INT PRIMARY KEY,passenger_name VARCHAR(100) NOT NULL);
CREATE TABLE Flights(flight_id INT PRIMARY KEY,flight_number VARCHAR(20) NOT NULL,flight_date DATE NOT NULL);
CREATE TABLE Seats(
 seat_id INT PRIMARY KEY,flight_id INT NOT NULL REFERENCES Flights(flight_id),
 seat_number VARCHAR(8) NOT NULL,seat_status VARCHAR(15) NOT NULL CHECK(seat_status IN ('Available','Booked')),
 CONSTRAINT UQ_Flight_Seat UNIQUE(flight_id,seat_number)
);
CREATE TABLE Bookings(
 booking_id INT IDENTITY(1,1) PRIMARY KEY,
 passenger_id INT NOT NULL REFERENCES Passengers(passenger_id),
 seat_id INT NOT NULL REFERENCES Seats(seat_id),
 fare DECIMAL(10,2) NOT NULL CHECK(fare>0),
 booked_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
 booking_status VARCHAR(15) NOT NULL DEFAULT 'Confirmed',
 CONSTRAINT UQ_Booking_Seat UNIQUE(seat_id)
);
INSERT INTO Passengers VALUES(1,'Aadhya'),(2,'Bala'),(3,'Charu'),(4,'Dev');
INSERT INTO Flights VALUES(10,'HX101','2026-12-01'),(20,'HX202','2026-12-02');
INSERT INTO Seats VALUES
(1001,10,'1A','Available'),(1002,10,'1B','Available'),(1003,10,'1C','Available'),
(2001,20,'2A','Available'),(2002,20,'2B','Available');
