

USE inventory_order;


-- TEST 1: All 8 sample orders were created.

SELECT
    'Sample data created 8 orders' AS test_name,
    (SELECT COUNT(*) FROM orders) AS actual,
    8 AS expected,
    CASE WHEN (SELECT COUNT(*) FROM orders) = 8
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 2: A small order gets no discount.
-- Order 1 is 1 laptop, which is under the 10-unit threshold.

SELECT
    'Order of 1 gets 0% discount' AS test_name,
    (SELECT discount_pct FROM order_details WHERE order_id = 1) AS actual,
    0.00 AS expected,
    CASE WHEN (SELECT discount_pct FROM order_details WHERE order_id = 1) = 0
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 3: 150 units reaches the top discount band (15%).

SELECT
    'Order of 150 gets 15% discount' AS test_name,
    (SELECT discount_pct FROM order_details WHERE order_id = 3) AS actual,
    15.00 AS expected,
    CASE WHEN (SELECT discount_pct FROM order_details WHERE order_id = 3) = 15
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 4: The line total maths is right.
-- 150 notebooks at 4.75 with 15% off:
--   150 * 4.75 = 712.50
--   712.50 * 0.85 = 605.625 -> rounds to 605.63

SELECT
    'Discounted line total is 605.63' AS test_name,
    (SELECT line_total FROM order_details WHERE order_id = 3) AS actual,
    605.63 AS expected,
    CASE WHEN (SELECT line_total FROM order_details WHERE order_id = 3) = 605.63
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 5: Ordering more than we have is refused.
-- Standing Desk has 3 left. Asking for 999 should NOT create an
-- order - the procedure returns a message instead.

CALL place_order(1, 9, 999);

SELECT
    'Too-big order did not create an order' AS test_name,
    (SELECT COUNT(*) FROM orders) AS actual,
    8 AS expected,
    CASE WHEN (SELECT COUNT(*) FROM orders) = 8
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 6: Customer tiers are worked out correctly.

SELECT
    'Aline is a Gold customer' AS test_name,
    (SELECT tier FROM customer_spending WHERE customer_id = 1) AS actual,
    'Gold' AS expected,
    CASE WHEN (SELECT tier FROM customer_spending WHERE customer_id = 1) = 'Gold'
         THEN 'PASS' ELSE 'FAIL' END AS result;


-- TEST 7: A customer with no orders still appears, as Bronze.

SELECT
    'All 6 customers appear in the spending view' AS test_name,
    (SELECT COUNT(*) FROM customer_spending) AS actual,
    6 AS expected,
    CASE WHEN (SELECT COUNT(*) FROM customer_spending) = 6
         THEN 'PASS' ELSE 'FAIL' END AS result;
