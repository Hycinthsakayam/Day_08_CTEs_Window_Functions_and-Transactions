-- Day 8 / Set 3: Reserve stock and roll back when stock is insufficient
USE Day8RetailInventory;
GO
DECLARE @CustomerName VARCHAR(100)='Sample Customer',@NewOrderId INT;
DECLARE @Requested TABLE(product_id INT PRIMARY KEY,quantity INT NOT NULL);
INSERT INTO @Requested VALUES(101,2),(201,3);

BEGIN TRY
 BEGIN TRANSACTION;

 -- Lock the products while validating and decrementing to prevent overselling.
 IF EXISTS(
   SELECT 1 FROM @Requested r
   LEFT JOIN Products p WITH(UPDLOCK,HOLDLOCK) ON p.product_id=r.product_id
   WHERE p.product_id IS NULL OR p.stock_quantity<r.quantity
 )
   THROW 53000,'Product missing or insufficient stock. No order was placed.',1;

 INSERT INTO Orders(customer_name,order_status) VALUES(@CustomerName,'Reserved');
 SET @NewOrderId=CONVERT(INT,SCOPE_IDENTITY());

 UPDATE p
 SET stock_quantity=p.stock_quantity-r.quantity
 FROM Products p JOIN @Requested r ON r.product_id=p.product_id;

 INSERT INTO OrderLines(order_id,product_id,quantity,unit_price)
 SELECT @NewOrderId,p.product_id,r.quantity,p.unit_price
 FROM @Requested r JOIN Products p ON p.product_id=r.product_id;

 COMMIT TRANSACTION;
 PRINT CONCAT('Order ',@NewOrderId,' reserved successfully.');
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 PRINT CONCAT('Reservation failed and rolled back: ',ERROR_MESSAGE());
END CATCH;
GO

-- Deliberate insufficient-stock test. The first product is valid, the second request is too large.
-- No order row or stock decrement should remain after rollback.
DECLARE @BeforeMonitor INT=(SELECT stock_quantity FROM Products WHERE product_id=101);
DECLARE @BeforeKeyboard INT=(SELECT stock_quantity FROM Products WHERE product_id=201);
DECLARE @TestOrderId INT;
DECLARE @BadRequest TABLE(product_id INT PRIMARY KEY,quantity INT NOT NULL);
INSERT INTO @BadRequest VALUES(101,1),(201,9999);
BEGIN TRY
 BEGIN TRANSACTION;
 IF EXISTS(
   SELECT 1 FROM @BadRequest r
   LEFT JOIN Products p WITH(UPDLOCK,HOLDLOCK) ON p.product_id=r.product_id
   WHERE p.product_id IS NULL OR p.stock_quantity<r.quantity
 )
   THROW 53001,'Insufficient stock in at least one requested product.',1;
 INSERT INTO Orders(customer_name,order_status) VALUES('Rollback Test','Reserved');
 SET @TestOrderId=CONVERT(INT,SCOPE_IDENTITY());
 UPDATE p SET stock_quantity=p.stock_quantity-r.quantity
 FROM Products p JOIN @BadRequest r ON r.product_id=p.product_id;
 INSERT INTO OrderLines(order_id,product_id,quantity,unit_price)
 SELECT @TestOrderId,p.product_id,r.quantity,p.unit_price
 FROM @BadRequest r JOIN Products p ON p.product_id=r.product_id;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 PRINT CONCAT('Expected rollback: ',ERROR_MESSAGE());
END CATCH;
SELECT @BeforeMonitor AS monitor_before,p1.stock_quantity AS monitor_after,
       @BeforeKeyboard AS keyboard_before,p2.stock_quantity AS keyboard_after
FROM Products p1 CROSS JOIN Products p2
WHERE p1.product_id=101 AND p2.product_id=201;
SELECT * FROM Orders WHERE customer_name='Rollback Test';
