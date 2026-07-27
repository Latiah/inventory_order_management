
-- Checks that stock and the inventory log behave correctly.
-- Each test prints PASS or FAIL using CASE.


USE inventory_order;

-- TEST 1: Stock went down by the right amount.
-- Laptop started at 40. Order 1 took 1, order 7 took 12.
-- 40 - 13 = 27

SELECT
    'Laptop stock is 40 - 13 = 27' AS test_name,
    (SELECT stock_quantity FROM products WHERE product_id = 1) AS actual,
    27 AS expected,
    CASE WHEN (SELECT stock_quantity FROM products WHERE product_id = 1) = 27
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 2: Restocking works and clears the low stock list.

CALL restock_all_low_stock();

SELECT
    'Nothing is low after restocking' AS test_name,
    (SELECT COUNT(*) FROM low_stock) AS actual,
    0 AS expected,
    CASE WHEN (SELECT COUNT(*) FROM low_stock) = 0
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 3: The restock was logged too.

SELECT
    'Restocking wrote 5 log rows' AS test_name,
    (SELECT COUNT(*) FROM inventory_logs WHERE reason = 'Auto restock') AS actual,
    5 AS expected,
    CASE WHEN (SELECT COUNT(*) FROM inventory_logs WHERE reason = 'Auto restock') = 5
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 4: Stock still matches the log after restocking.

SELECT
    'Stock still matches log after restock' AS test_name,
    (SELECT COUNT(*) FROM (
        SELECT p.product_id
        FROM products p
        LEFT JOIN inventory_logs l ON p.product_id = l.product_id
        GROUP BY p.product_id, p.stock_quantity
        HAVING p.stock_quantity <> IFNULL(SUM(l.change_qty), 0)
    ) AS mismatches) AS products_that_disagree,
    0 AS expected,
    CASE WHEN (SELECT COUNT(*) FROM (
        SELECT p.product_id
        FROM products p
        LEFT JOIN inventory_logs l ON p.product_id = l.product_id
        GROUP BY p.product_id, p.stock_quantity
        HAVING p.stock_quantity <> IFNULL(SUM(l.change_qty), 0)
    ) AS mismatches) = 0
    THEN 'PASS' ELSE 'FAIL' END AS result;
