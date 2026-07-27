
--  Stored procedures


USE inventory_order;

DROP PROCEDURE IF EXISTS place_order;
DROP PROCEDURE IF EXISTS start_order;
DROP PROCEDURE IF EXISTS add_item;
DROP PROCEDURE IF EXISTS restock_product;
DROP PROCEDURE IF EXISTS restock_all_low_stock;

DELIMITER $$

-- 1. Order with ONE product

--    CALL place_order(1, 5, 3);
--    (customer 1 buys 3 of product 5)

CREATE PROCEDURE place_order (
    IN cust_id INT,
    IN prod_id INT,
    IN qty     INT
)
BEGIN
    DECLARE new_order_id INT;
    DECLARE available    INT;

    SELECT stock_quantity INTO available
    FROM products
    WHERE product_id = prod_id;

    -- Check stock FIRST, before creating anything.
 
    IF available < qty THEN
        SELECT 'Not enough stock - order cancelled' AS message,
               qty       AS you_asked_for,
               available AS we_have;
    ELSE
        INSERT INTO orders (customer_id) VALUES (cust_id);

        -- LAST_INSERT_ID() gives the order_id that was just created
        SET new_order_id = LAST_INSERT_ID();

        INSERT INTO order_details (order_id, product_id, quantity)
        VALUES (new_order_id, prod_id, qty);

        SELECT new_order_id AS order_created;
    END IF;
END $$

-- 2. Order with MANY products

--    The order total updates itself after every add_item.

CREATE PROCEDURE start_order (
    IN cust_id INT
)
BEGIN
    INSERT INTO orders (customer_id) VALUES (cust_id);
    SELECT LAST_INSERT_ID() AS order_created;
END $$

CREATE PROCEDURE add_item (
    IN ord_id  INT,
    IN prod_id INT,
    IN qty     INT
)
BEGIN
    DECLARE available INT;

    SELECT stock_quantity INTO available
    FROM products
    WHERE product_id = prod_id;

    IF available < qty THEN
        SELECT 'Not enough stock - item not added' AS message,
               qty       AS you_asked_for,
               available AS we_have;
    ELSE
        INSERT INTO order_details (order_id, product_id, quantity)
        VALUES (ord_id, prod_id, qty);
    END IF;
END $$


-- 3. Restock one product
--    CALL restock_product(5, 50);

CREATE PROCEDURE restock_product (
    IN prod_id INT,
    IN qty     INT
)
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity + qty
    WHERE product_id = prod_id;

    INSERT INTO inventory_logs (product_id, change_qty, reason)
    VALUES (prod_id, qty, 'Manual restock');
END $$

-- 4. Restock EVERY low product automatically

--    CALL restock_all_low_stock();

CREATE PROCEDURE restock_all_low_stock ()
BEGIN
    INSERT INTO inventory_logs (product_id, change_qty, reason)
    SELECT product_id, reorder_qty, 'Auto restock'
    FROM products
    WHERE stock_quantity <= reorder_level;

    UPDATE products
    SET stock_quantity = stock_quantity + reorder_qty
    WHERE stock_quantity <= reorder_level;
END $$

DELIMITER ;
