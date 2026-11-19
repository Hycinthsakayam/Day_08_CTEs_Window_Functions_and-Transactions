-- Day 8 / Set 1: Bank Funds Transfer
IF DB_ID('Day8BankTransfer') IS NULL CREATE DATABASE Day8BankTransfer;
GO
USE Day8BankTransfer;
GO
DROP TABLE IF EXISTS AccountTransactions, TransferFees, Accounts;
GO
CREATE TABLE Accounts(
 account_id INT PRIMARY KEY,
 account_holder VARCHAR(100) NOT NULL,
 balance DECIMAL(12,2) NOT NULL CHECK(balance>=0),
 account_status VARCHAR(20) NOT NULL CHECK(account_status IN ('Active','Frozen','Closed'))
);
CREATE TABLE AccountTransactions(
 transaction_id INT IDENTITY(1,1) PRIMARY KEY,
 account_id INT NOT NULL REFERENCES Accounts(account_id),
 related_account_id INT NULL,
 transaction_type VARCHAR(20) NOT NULL,
 amount DECIMAL(12,2) NOT NULL CHECK(amount>0),
 transaction_date DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
 balance_after DECIMAL(12,2) NOT NULL,
 reference_note VARCHAR(150)
);
CREATE TABLE TransferFees(
 fee_id INT IDENTITY(1,1) PRIMARY KEY,
 transaction_id INT NOT NULL,
 fee_amount DECIMAL(10,2) NOT NULL,
 posted_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
INSERT INTO Accounts VALUES
(101,'Aarav',25000,'Active'),(102,'Diya',12000,'Active'),
(103,'Kabir',5000,'Frozen'),(104,'Mira',800,'Active');
INSERT INTO AccountTransactions(account_id,related_account_id,transaction_type,amount,balance_after,reference_note)
VALUES
(101,NULL,'Deposit',30000,25000,'Opening statement entry'),
(102,NULL,'Deposit',15000,12000,'Opening statement entry'),
(101,102,'Transfer Out',5000,25000,'Earlier sample transfer'),
(102,101,'Transfer In',5000,12000,'Earlier sample transfer');
