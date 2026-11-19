-- Monthly account statement using a CTE, ROW_NUMBER and LAG
USE Day8BankTransfer;
GO
DECLARE @AccountId INT=101, @StatementMonth DATE='2026-11-01';
;WITH MonthlyTransactions AS (
 SELECT transaction_id,account_id,transaction_type,amount,transaction_date,balance_after,reference_note
 FROM AccountTransactions
 WHERE account_id=@AccountId
   AND transaction_date>=@StatementMonth
   AND transaction_date<DATEADD(MONTH,1,@StatementMonth)
),
StatementWithPrevious AS (
 SELECT *,
        ROW_NUMBER() OVER(PARTITION BY account_id ORDER BY transaction_date,transaction_id) AS statement_row,
        LAG(balance_after,1,0) OVER(PARTITION BY account_id ORDER BY transaction_date,transaction_id) AS previous_balance
 FROM MonthlyTransactions
)
SELECT transaction_id,transaction_type,amount,transaction_date,
       previous_balance,balance_after,
       balance_after-previous_balance AS balance_change,
       statement_row,reference_note
FROM StatementWithPrevious
ORDER BY transaction_date,transaction_id;
