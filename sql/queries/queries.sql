
-- Result from queries


USE inventory_order;


-- 1. All order summaries

SELECT * FROM order_summary
ORDER BY order_date;


-- 2. Orders for one customer

SELECT * FROM order_summary
WHERE customer_name = 'Aline Mukamana'
ORDER BY order_date;


-- 3. Products that need reordering

SELECT * FROM low_stock
ORDER BY stock_quantity;


-- 4. Customer spending and tiers

SELECT * FROM customer_spending
ORDER BY total_spent DESC;

-- 5. Only the Gold customers

SELECT customer_name, total_spent, tier
FROM customer_spending
WHERE tier = 'Gold';


-- 6. Best selling products

SELECT
    p.product_name,
    p.category,
    IFNULL(SUM(od.quantity), 0)   AS units_sold,
    IFNULL(SUM(od.line_total), 0) AS revenue
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_name, p.category
ORDER BY revenue DESC;

-- 7. Sales by category

SELECT
    p.category,
    SUM(od.quantity)   AS units_sold,
    SUM(od.line_total) AS revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;


-- 8. Categories that made more than 1000

SELECT
    p.category,
    SUM(od.line_total) AS revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.category
HAVING SUM(od.line_total) > 1000
ORDER BY revenue DESC;

-- 9. Products that have never been ordered

SELECT
    p.product_name,
    p.category,
    p.stock_quantity,
    ROUND(p.stock_quantity * p.price, 2) AS money_tied_up
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
WHERE od.order_detail_id IS NULL
ORDER BY money_tied_up DESC;


-- 10. Top 3 biggest orders

SELECT customer_name, order_id, total_amount
FROM order_summary
ORDER BY total_amount DESC
LIMIT 3;


-- 11. Stock history for one product

SELECT
    l.changed_at,
    p.product_name,
    l.change_qty,
    l.reason
FROM inventory_logs l
JOIN products p ON l.product_id = p.product_id
WHERE p.product_name = 'Laptop'
ORDER BY l.log_id;


-- 12. Check the stock column against the log

SELECT
    p.product_name,
    p.stock_quantity,
    IFNULL(SUM(l.change_qty), 0) AS total_from_log
FROM products p
LEFT JOIN inventory_logs l ON p.product_id = l.product_id
GROUP BY p.product_id, p.product_name, p.stock_quantity
HAVING p.stock_quantity <> IFNULL(SUM(l.change_qty), 0);


-- 13. Rank customers 

SELECT
    customer_name,
    total_spent,
    tier,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_spending;

-- 14. Best selling product inside each category

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


-- 15. Running total of revenue, biggest order first

SELECT
    order_id,
    customer_name,
    total_amount,
    SUM(total_amount) OVER (ORDER BY total_amount DESC) AS running_total
FROM order_summary;


-- 16. How much each discount level gave away

SELECT
    discount_pct,
    COUNT(*)         AS number_of_lines,
    SUM(quantity)    AS units,
    ROUND(SUM(quantity * unit_price), 2)                    AS before_discount,
    SUM(line_total)                                         AS after_discount,
    ROUND(SUM(quantity * unit_price) - SUM(line_total), 2)   AS discount_given
FROM order_details
GROUP BY discount_pct
ORDER BY discount_pct;