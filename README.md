# Day 8 – CTEs, Window Functions and Transactions

This is my Day 8 SQL Server 2025 and MongoDB 8.0 practice. I split the work into the three business scenarios from the assignment so I can run and check each one separately.

## What I practised
- Explicit transactions with `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`, `TRY...CATCH` and `THROW`.
- Savepoints and partial rollback.
- Transaction isolation: READ COMMITTED, SNAPSHOT and SERIALIZABLE.
- CTEs, correlated subqueries and window functions: `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`, and running `SUM() OVER`.
- MongoDB sessions, multi-document transactions and atomic `$inc` updates.

## Assignment folders

### Set 1 – Bank Funds Transfer
Account transfers, rollback proof, fee savepoint, monthly statement and MongoDB transfer.

[Open Set 1](./Set-1-Bank-Funds-Transfer/)

### Set 2 – Airline Seat Booking
Atomic seat booking, two-session concurrency test, fare ranking and MongoDB transaction.

[Open Set 2](./Set-2-Airline-Seat-Booking/)

### Set 3 – Retail Inventory Reservation
Stock reservation, insufficient-stock rollback, category ranking, monthly sales movement and MongoDB stock update.

[Open Set 3](./Set-3-Retail-Inventory-Reservation/)

## How to run
1. Open SQL Server Management Studio (SSMS).
2. For each folder, run `setup.sql` first to create its database and sample records.
3. Run the remaining `.sql` files in that folder in the order explained in its `NOTES.md`.
4. Run MongoDB scripts with `mongosh transaction.js`, `mongosh booking_txn.js`, or `mongosh stock_update.js` as appropriate.

The SQL scripts are written for SQL Server. The JavaScript files use MongoDB shell syntax. Multi-document transactions require a replica set or sharded cluster. The retail stock-only script uses a single-document atomic update and does not need a multi-document transaction.

The notes include expected observations and concurrency instructions. The scripts have been added to the repository, but they still need to be executed in SSMS and mongosh to capture actual run screenshots; no execution screenshots are claimed here.
