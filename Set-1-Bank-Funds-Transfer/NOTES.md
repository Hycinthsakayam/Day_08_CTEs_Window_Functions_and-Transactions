# Set 1 – Bank Funds Transfer

## Files and run order
1. Run `setup.sql`.
2. Run `transfer.sql`. It contains a successful transfer, a deliberate failure after debit, and a savepoint example.
3. Run `statement_cte.sql` for the monthly statement.
4. Run `mongosh transaction.js` against a MongoDB replica set or sharded cluster.

## Transaction behaviour
A transfer changes two account documents/rows. The debit and credit must commit together. If validation or either update fails, the catch block rolls back the transaction. The deliberate THROW occurs after the debit; the before/after SELECT demonstrates that rollback restores the original balance.

The savepoint is created after both sides of the transfer are posted. The simulated fee failure rolls back to that savepoint, removing only the fee insert; the transfer remains part of the outer transaction and is committed.

## Isolation levels
- **READ COMMITTED:** a query cannot read another transaction's uncommitted changes. Under the default locking implementation, shared locks are generally released after each statement, so a later statement can see a newly committed value (non-repeatable read).
- **SNAPSHOT:** each transaction reads a consistent version as of its start. It reduces reader/writer blocking but uses the version store and can produce update-conflict errors when concurrent transactions update the same row.

### Two-session exercise
Session A:
```sql
USE Day8BankTransfer;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;
SELECT balance FROM Accounts WHERE account_id=101;
WAITFOR DELAY '00:00:10';
SELECT balance FROM Accounts WHERE account_id=101;
COMMIT;
```
During the wait, run in Session B:
```sql
USE Day8BankTransfer;
UPDATE Accounts SET balance=balance-100 WHERE account_id=101;
```
With READ COMMITTED, Session A's second SELECT can see Session B's committed update. For SNAPSHOT, first enable versioning once as an administrator: `ALTER DATABASE Day8BankTransfer SET ALLOW_SNAPSHOT_ISOLATION ON;`. Then set Session A to SNAPSHOT and begin the transaction; both reads see the same transaction-start version.

## MongoDB cost
A multi-document transaction provides atomicity across accounts and the ledger, but has more coordination, locking/conflict handling, and operational overhead than a single-document update. Keep transactions short and use them only when the business operation spans documents.
