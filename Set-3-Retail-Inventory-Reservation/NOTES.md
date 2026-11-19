# Set 3 – Retail Inventory Reservation

## Run order
1. Run `setup.sql`.
2. Run `reservation.sql` to reserve stock and then run the deliberate insufficient-stock test.
3. Run `rank_report.sql` for the correlated stock comparison, category ranking and monthly sales movement.
4. Run `mongosh stock_update.js` for the single-document MongoDB stock update.

## Transaction and rollback
The reservation uses a table variable for the requested product quantities. It checks every product while taking update/serializable locks before inserting the order or changing inventory. If any item is missing or short on stock, THROW moves control to CATCH and the transaction is rolled back. The second test deliberately requests more keyboards than are available; the before/after query should show unchanged stock and no test order.

## Window functions
- ROW_NUMBER resets for each category because of PARTITION BY category_id. The first three products in each category are returned.
- LAG returns the previous month’s units sold for the same product; LEAD returns the next month’s value. The change column is current month minus previous month.

## MongoDB: transaction or atomic update?
A single-document stock decrement can use one atomic update with a guarded filter and $inc, as shown. This is enough when only the product document changes. A multi-document transaction is needed when the same operation must also create an order, create multiple order-line documents, reserve several product documents, or update payment/order state and all of those changes must succeed or fail together. Multi-document transactions add coordination and performance overhead, so prefer a single-document atomic update when the data model allows it.
