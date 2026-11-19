-- Day 8 / Set 3: Retail Inventory Reservation
IF DB_ID('Day8RetailInventory') IS NULL CREATE DATABASE Day8RetailInventory;
GO
USE Day8RetailInventory;
GO
DROP TABLE IF EXISTS OrderLines, Orders, Products, Categories;
GO
CREATE TABLE Categories(category_id INT PRIMARY KEY,category_name VARCHAR(80) NOT NULL);
CREATE TABLE Products(
 product_id INT PRIMARY KEY,product_name VARCHAR(100) NOT NULL,
 category_id INT NOT NULL REFERENCES Categories(category_id),
 stock_quantity INT NOT NULL CHECK(stock_quantity>=0),
 unit_price DECIMAL(10,2) NOT NULL CHECK(unit_price>0)
);
CREATE TABLE Orders(
 order_id INT IDENTITY(1,1) PRIMARY KEY,customer_name VARCHAR(100) NOT NULL,
 order_date DATE NOT NULL DEFAULT CONVERT(date,GETDATE()),
 order_status VARCHAR(20) NOT NULL DEFAULT 'Reserved'
);
CREATE TABLE OrderLines(
 order_line_id INT IDENTITY(1,1) PRIMARY KEY,
 order_id INT NOT NULL REFERENCES Orders(order_id),
 product_id INT NOT NULL REFERENCES Products(product_id),
 quantity INT NOT NULL CHECK(quantity>0),
 unit_price DECIMAL(10,2) NOT NULL
);
INSERT INTO Categories VALUES(1,'Electronics'),(2,'Accessories'),(3,'Home');
INSERT INTO Products VALUES
(101,'Monitor',1,12,12000),(102,'Laptop',1,8,65000),(103,'Tablet',1,20,18000),
(201,'Keyboard',2,30,1800),(202,'Wireless Mouse',2,45,900),(203,'USB Hub',2,18,1200),
(301,'Desk Lamp',3,14,1500),(302,'Storage Box',3,25,700);
-- Historical sales make the monthly window report useful.
INSERT INTO Orders(customer_name,order_date,order_status)
VALUES('Customer A','2026-08-05','Completed'),('Customer B','2026-08-18','Completed'),
('Customer C','2026-09-09','Completed'),('Customer D','2026-09-20','Completed'),
('Customer E','2026-10-03','Completed'),('Customer F','2026-10-22','Completed');
INSERT INTO OrderLines(order_id,product_id,quantity,unit_price) VALUES
(1,101,2,12000),(1,201,5,1800),(2,102,1,65000),(2,202,4,900),
(3,101,3,12000),(3,201,8,1800),(4,103,2,18000),(4,202,6,900),
(5,101,4,12000),(5,201,10,1800),(6,102,2,65000),(6,203,7,1200);
