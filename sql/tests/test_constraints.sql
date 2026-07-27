
-- tests for constraints in the inventory_order database


USE inventory_order;

-- TEST 1: Cannot create an order for a customer who does not exist.
-- EXPECT: ERROR 1452 - foreign key constraint fails

INSERT INTO orders (customer_id) VALUES (999);

-- TEST 2: Cannot add an order line for a product that does not exist.
-- EXPECT: ERROR 1452 - foreign key constraint fails

INSERT INTO order_details (order_id, product_id, quantity) VALUES (1, 999, 1);


-- TEST 3: Stock cannot go negative.
-- EXPECT: ERROR 1690 - BIGINT UNSIGNED value is out of range
-- This is because stock_quantity is INT UNSIGNED. 

UPDATE products SET stock_quantity = stock_quantity - 99999 WHERE product_id = 1;

-- TEST 4: A customer must have a name.
-- EXPECT: ERROR 1048 - Column 'customer_name' cannot be null
-- This is the NOT NULL constraint.

INSERT INTO customers (customer_name, email) VALUES (NULL, 'nobody@example.com');

-- TEST 5: Cannot delete a customer who has orders.
-- EXPECT: ERROR 1451 - Cannot delete or update a parent row
-- This stops orders being left behind pointing at nobody.

DELETE FROM customers WHERE customer_id = 1;


-- TEST 6: Cannot delete a product that appears in an order.

-- EXPECT: ERROR 1451 - Cannot delete or update a parent row

DELETE FROM products WHERE product_id = 1;

