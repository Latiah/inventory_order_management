
-- Views

USE inventory_order;

-- 1. Order summary: who ordered, when, how much, how many items

CREATE VIEW order_summary AS
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.total_amount,
    COUNT(od.order_detail_id) AS number_of_products,
    IFNULL(SUM(od.quantity), 0) AS total_items
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_id, c.customer_name, o.order_date, o.total_amount;


-- 2. Low stock: products that need reordering

CREATE VIEW low_stock AS
SELECT
    product_id,
    product_name,
    category,
    stock_quantity,
    reorder_level,
    reorder_qty,
    CASE
        WHEN stock_quantity = 0 THEN 'Out of stock'
        ELSE 'Low'
    END AS status
FROM products
WHERE stock_quantity <= reorder_level;

-- 3. Customer spending and tier

CREATE VIEW customer_spending AS
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    IFNULL(SUM(o.total_amount), 0) AS total_spent,
    CASE
        WHEN IFNULL(SUM(o.total_amount), 0) >= 5000 THEN 'Gold'
        WHEN IFNULL(SUM(o.total_amount), 0) >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;