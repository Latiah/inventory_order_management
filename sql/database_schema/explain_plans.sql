USE inventory_order;

-- 1. order_summary view: joins orders -> customers -> order_details.
--    Expect idx_orders_customer / idx_details_order to be used instead
--    of a full scan of order_details for every order.

EXPLAIN
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.total_amount,
    COUNT(od.order_detail_id)   AS number_of_products,
    IFNULL(SUM(od.quantity), 0) AS total_items
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_id, c.customer_name, o.order_date, o.total_amount;

-- 2. low_stock view: a simple filter on products, with no join, so this
--    is here mainly to confirm it's a cheap scan of the (small) products
--    table rather than something that needs a new index.

EXPLAIN
SELECT product_id, product_name, category, stock_quantity, reorder_level, reorder_qty
FROM products
WHERE stock_quantity <= reorder_level;

-- 3. customer_spending view: customers LEFT JOIN orders, aggregated per
--    customer. Expect idx_orders_customer to be used for the join.

EXPLAIN
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id)              AS total_orders,
    IFNULL(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

-- 4. Stock history for one product: joins
--    inventory_logs -> products. Expect idx_logs_product to be used
--    instead of scanning every log row ever written.

EXPLAIN
SELECT l.changed_at, p.product_name, l.change_qty, l.reason, l.running_balance
FROM inventory_logs l
JOIN products p ON l.product_id = p.product_id
WHERE p.product_name = 'Laptop'
ORDER BY l.log_id;

-- 5. Best-selling products: products LEFT
--    JOIN order_details. Expect idx_details_product to be used.

EXPLAIN
SELECT
    p.product_name,
    p.category,
    IFNULL(SUM(od.quantity), 0)   AS units_sold,
    IFNULL(SUM(od.line_total), 0) AS revenue
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_name, p.category;
