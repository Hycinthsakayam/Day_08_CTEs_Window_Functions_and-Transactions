-- Day 8 / Set 1: Transfer, deliberate rollback and savepoint demonstration
USE Day8BankTransfer;
GO
DECLARE @FromAccount INT=101, @ToAccount INT=102, @Amount DECIMAL(12,2)=2000,
        @BeforeFrom DECIMAL(12,2), @BeforeTo DECIMAL(12,2);

-- A successful transfer: debit and credit are one atomic unit.
BEGIN TRY
 BEGIN TRANSACTION;
 IF @FromAccount=@ToAccount THROW 51000,'Source and destination must be different accounts.',1;
 IF NOT EXISTS(SELECT 1 FROM Accounts WITH(UPDLOCK,HOLDLOCK) WHERE account_id=@FromAccount AND account_status='Active')
   THROW 51001,'Source account does not exist or is not active.',1;
 IF NOT EXISTS(SELECT 1 FROM Accounts WITH(UPDLOCK,HOLDLOCK) WHERE account_id=@ToAccount AND account_status='Active')
   THROW 51002,'Destination account does not exist or is not active.',1;
 IF (SELECT balance FROM Accounts WHERE account_id=@FromAccount)<@Amount
   THROW 51003,'Insufficient balance.',1;

 UPDATE Accounts SET balance=balance-@Amount WHERE account_id=@FromAccount;
 INSERT INTO AccountTransactions(account_id,related_account_id,transaction_type,amount,balance_after,reference_note)
 SELECT account_id,@ToAccount,'Transfer Out',@Amount,balance,'Day 8 transfer'
 FROM Accounts WHERE account_id=@FromAccount;

 UPDATE Accounts SET balance=balance+@Amount WHERE account_id=@ToAccount;
 INSERT INTO AccountTransactions(account_id,related_account_id,transaction_type,amount,balance_after,reference_note)
 SELECT account_id,@FromAccount,'Transfer In',@Amount,balance,'Day 8 transfer'
 FROM Accounts WHERE account_id=@ToAccount;
 COMMIT TRANSACTION;
 PRINT 'Transfer completed. Both account balances were updated.';
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 PRINT CONCAT('Transfer failed: ',ERROR_MESSAGE());
 THROW;
END CATCH;
GO

-- Deliberate failure after the debit. The catch block rolls the debit back.
SELECT @BeforeFrom=balance FROM Accounts WHERE account_id=101;
SELECT @BeforeTo=balance FROM Accounts WHERE account_id=102;
BEGIN TRY
 BEGIN TRANSACTION;
 UPDATE Accounts SET balance=balance-1000 WHERE account_id=101;
 IF @@ROWCOUNT<>1 THROW 51004,'Source account missing.',1;
 THROW 51005,'Intentional test failure after debit.',1;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 PRINT CONCAT('Expected rollback: ',ERROR_MESSAGE());
END CATCH;
SELECT @BeforeFrom AS source_before, a.balance AS source_after,
       @BeforeTo AS destination_before, b.balance AS destination_after
FROM Accounts a CROSS JOIN Accounts b
WHERE a.account_id=101 AND b.account_id=102;
-- The before and after values should match for this failed test.

-- Savepoint: keep the transfer, but undo only the optional fee posting.
BEGIN TRY
 BEGIN TRANSACTION;
 UPDATE Accounts SET balance=balance-500 WHERE account_id=101 AND account_status='Active' AND balance>=500;
 IF @@ROWCOUNT<>1 THROW 51006,'Transfer debit failed.',1;
 INSERT INTO AccountTransactions(account_id,related_account_id,transaction_type,amount,balance_after,reference_note)
 SELECT account_id,102,'Transfer Out',500,balance,'Savepoint transfer'
 FROM Accounts WHERE account_id=101;
 UPDATE Accounts SET balance=balance+500 WHERE account_id=102 AND account_status='Active';
 IF @@ROWCOUNT<>1 THROW 51007,'Transfer credit failed.',1;
 INSERT INTO AccountTransactions(account_id,related_account_id,transaction_type,amount,balance_after,reference_note)
 SELECT account_id,101,'Transfer In',500,balance,'Savepoint transfer'
 FROM Accounts WHERE account_id=102;

 SAVE TRANSACTION FeeStep;
 BEGIN TRY
   INSERT INTO TransferFees(transaction_id,fee_amount)
   VALUES(CONVERT(INT,SCOPE_IDENTITY()),25.00);
   -- Simulate a fee service failure after attempting to post the fee.
   THROW 51008,'Intentional fee-posting failure.',1;
 END TRY
 BEGIN CATCH
   IF XACT_STATE()=1
   BEGIN
     ROLLBACK TRANSACTION FeeStep;
     PRINT 'Fee step rolled back; the account transfer is retained.';
   END
   ELSE THROW;
 END CATCH;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
SELECT account_id,account_holder,balance FROM Accounts ORDER BY account_id;
SELECT * FROM TransferFees;
