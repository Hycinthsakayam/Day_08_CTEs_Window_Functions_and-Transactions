-- Day 8 / Set 3: Correlated stock query, category ranking and monthly sales movement
USE Day8RetailInventory;
GO

-- Q2. Products with stock below the average stock level in their own category.
SELECT p.product_id,p.product_name,c.category_name,p.stock_quantity
FROM Products p JOIN Categories c ON c.category_id=p.category_id
WHERE p.stock_quantity < (
 SELECT AVG(CAST(p2.stock_quantity AS DECIMAL(10,2)))
 FROM Products p2
 WHERE p2.category_id=p.category_id
)
ORDER BY c.category_name,p.stock_quantity;

-- Q3. Top three products by units sold within each category.
;WITH ProductSales AS (
 SELECT p.product_id,p.product_name,p.category_id,c.category_name,
        COALESCE(SUM(CASE WHEN o.order_status='Completed' THEN ol.quantity ELSE 0 END),0) AS units_sold
 FROM Products p JOIN Categories c ON c.category_id=p.category_id
 LEFT JOIN OrderLines ol ON ol.product_id=p.product_id
 LEFT JOIN Orders o ON o.order_id=ol.order_id
 GROUP BY p.product_id,p.product_name,p.category_id,c.category_name
),
RankedProducts AS (
 SELECT *,ROW_NUMBER() OVER(PARTITION BY category_id ORDER BY units_sold DESC,product_id) AS category_position
 FROM ProductSales
)
SELECT category_name,product_name,units_sold,category_position
FROM RankedProducts
WHERE category_position<=3
ORDER BY category_name,category_position;

-- Q4. Month-on-month product sales and change using LAG and LEAD.
;WITH MonthlySales AS (
 SELECT ol.product_id,p.product_name,
        DATEFROMPARTS(YEAR(o.order_date),MONTH(o.order_date),1) AS sales_month,
        SUM(ol.quantity) AS units_sold
 FROM OrderLines ol JOIN Orders o ON o.order_id=ol.order_id
 JOIN Products p ON p.product_id=ol.product_id
 WHERE o.order_status='Completed'
 GROUP BY ol.product_id,p.product_name,DATEFROMPARTS(YEAR(o.order_date),MONTH(o.order_date),1)
),
SalesMovement AS (
 SELECT product_id,product_name,sales_month,units_sold,
        LAG(units_sold) OVER(PARTITION BY product_id ORDER BY sales_month) AS previous_month_units,
        LEAD(units_sold) OVER(PARTITION BY product_id ORDER BY sales_month) AS next_month_units
 FROM MonthlySales
)
SELECT product_name,sales_month,units_sold,previous_month_units,
       units_sold-previous_month_units AS change_from_previous_month,
       next_month_units
FROM SalesMovement
ORDER BY product_name,sales_month;
