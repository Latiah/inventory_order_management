
-- Result from queries


USE inventory_order;


-- 1. All order summaries

SELECT * FROM order_summary
ORDER BY order_date;


-- 2. Products that need reordering

SELECT * FROM low_stock
ORDER BY stock_quantity;


-- 3. Customer spending and tiers

SELECT * FROM customer_spending
ORDER BY total_spent DESC;

-- 4. Only the Gold customers

SELECT customer_name, total_spent, tier
FROM customer_spending
WHERE tier = 'Gold';


-- 5. Best selling products

SELECT
    p.product_name,
    p.category,
    IFNULL(SUM(od.quantity), 0)   AS units_sold,
    IFNULL(SUM(od.line_total), 0) AS revenue
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_name, p.category
ORDER BY revenue DESC;

-- 6. Sales by category

SELECT
    p.category,
    SUM(od.quantity)   AS units_sold,
    SUM(od.line_total) AS revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;


-- 7. Categories that made more than 1000

SELECT
    p.category,
    SUM(od.line_total) AS revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.category
HAVING SUM(od.line_total) > 1000
ORDER BY revenue DESC;

-- 8. Products that have never been ordered

SELECT
    p.product_name,
    p.category,
    p.stock_quantity,
    ROUND(p.stock_quantity * p.price, 2) AS money_tied_up
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
WHERE od.order_detail_id IS NULL
ORDER BY money_tied_up DESC;


-- 9. Stock history for one product

SELECT
    l.changed_at,
    p.product_name,
    l.change_qty,
    l.reason
FROM inventory_logs l
JOIN products p ON l.product_id = p.product_id
WHERE p.product_name = 'Laptop'
ORDER BY l.log_id;


-- 10. Rank customers 

SELECT
    customer_name,
    total_spent,
    tier,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_spending;

-- 11. Best selling product inside each category

WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(od.line_total) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.category
            ORDER BY SUM(od.line_total) DESC
        ) AS position_in_category
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT category, product_name, revenue
FROM product_sales
WHERE position_in_category = 1
ORDER BY revenue DESC;


-- 12. Running total of revenue, biggest order first

SELECT
    order_id,
    customer_name,
    total_amount,
    SUM(total_amount) OVER (ORDER BY total_amount DESC) AS running_total
FROM order_summary;

