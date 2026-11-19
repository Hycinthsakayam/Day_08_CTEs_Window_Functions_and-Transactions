# Set 2 – Airline Seat Booking

## Run order
1. Run `setup.sql`.
2. Run `booking_transaction.sql` to book seat 1A.
3. Run `ranking_report.sql` to add remaining sample bookings and generate the ranked report.
4. Run `mongosh booking_txn.js` on a replica set or sharded cluster.

## Two-session concurrency test
First run `setup.sql` again to reset the sample data. Open two SSMS query windows.

**Session A** (start this first):
```sql
USE Day8AirlineBooking;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; -- repeat with SERIALIZABLE
BEGIN TRAN;
DECLARE @status varchar(15);
SELECT @status=seat_status FROM Seats WITH(UPDLOCK,HOLDLOCK) WHERE seat_id=1001;
WAITFOR DELAY '00:00:10';
IF @status='Available'
BEGIN
 INSERT INTO Bookings(passenger_id,seat_id,fare) VALUES(1,1001,8500);
 UPDATE Seats SET seat_status='Booked' WHERE seat_id=1001 AND seat_status='Available';
END
COMMIT;
```

**Session B** (run during Session A's wait):
```sql
USE Day8AirlineBooking;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; -- repeat with SERIALIZABLE
BEGIN TRAN;
DECLARE @status varchar(15);
SELECT @status=seat_status FROM Seats WITH(UPDLOCK,HOLDLOCK) WHERE seat_id=1001;
IF @status='Available'
BEGIN
 INSERT INTO Bookings(passenger_id,seat_id,fare) VALUES(2,1001,8200);
 UPDATE Seats SET seat_status='Booked' WHERE seat_id=1001 AND seat_status='Available';
END
COMMIT;
```

The supplied production-style booking uses SERIALIZABLE plus UPDLOCK/HOLDLOCK and a unique constraint on seat_id. For the experiment, remove the explicit lock hints from both sessions to observe the isolation-level difference. READ COMMITTED alone does not protect a seat across a separate read and insert; both sessions may initially read Available, and a unique constraint is the final safeguard. SERIALIZABLE holds key-range locks and forces the second session to wait; after the first commits, the second sees Booked and does not insert. The exact blocking/deadlock outcome depends on statement order and execution timing, so run both sessions to capture the actual result.

## RANK vs DENSE_RANK
For fares 9000, 9000, 8500: RANK returns 1, 1, 3 because it leaves a gap after a tie. DENSE_RANK returns 1, 1, 2 because it does not leave a gap. ROW_NUMBER always gives a unique sequence. The CTE also calculates a per-flight running revenue total using SUM() OVER ordered by booking time.
