
--  Stored procedures


USE inventory_order;

DROP PROCEDURE IF EXISTS place_order;
DROP PROCEDURE IF EXISTS place_order_multi;

DROP PROCEDURE IF EXISTS restock_product;
DROP PROCEDURE IF EXISTS restock_all_low_stock;

DELIMITER $$

-- 1. Order with ANY NUMBER of products, placed atomically.
--
--    CALL place_order_multi(1, JSON_ARRAY(
--        JSON_OBJECT('product_id', 5, 'quantity', 3),
--        JSON_OBJECT('product_id', 8, 'quantity', 1)
--    ));


CREATE PROCEDURE place_order_multi (
    IN cust_id     INT,
    IN items_json  JSON
)
BEGIN
    DECLARE new_order_id      INT;
    DECLARE item_count        INT;
    DECLARE idx               INT DEFAULT 0;
    DECLARE v_product_id      INT;
    DECLARE v_qty             INT;
    DECLARE v_stock           INT;
    DECLARE v_new_stock       INT;
    DECLARE v_customer_exists INT;


    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF items_json IS NULL OR JSON_LENGTH(items_json) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An order must contain at least one item';
    END IF;

    SET item_count = JSON_LENGTH(items_json);

    START TRANSACTION;

    -- Validate the customer up front with a clean error, rather than
    -- letting the orders.customer_id foreign key fail later.
    SELECT COUNT(*) INTO v_customer_exists
    FROM customers
    WHERE customer_id = cust_id;

    IF v_customer_exists = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unknown customer_id - order cancelled';
    END IF;

    -- Pass 1: lock every product row this order touches and validate it
    -- (exists, has enough stock) BEFORE writing anything. Each SELECT
    -- ... FOR UPDATE takes a row lock that is held until COMMIT/ROLLBACK,
    -- so a concurrent order for the same product blocks here rather than
    -- racing us to deduct the same stock twice.
    WHILE idx < item_count DO
        SET v_product_id = JSON_EXTRACT(items_json, CONCAT('$[', idx, '].product_id')) + 0;
        SET v_qty        = JSON_EXTRACT(items_json, CONCAT('$[', idx, '].quantity')) + 0;

        IF v_qty IS NULL OR v_qty <= 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'quantity must be greater than 0 - order cancelled';
        END IF;

        SELECT stock_quantity INTO v_stock
        FROM products
        WHERE product_id = v_product_id
        FOR UPDATE;

        IF v_stock IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Unknown product_id - order cancelled';
        END IF;

        IF v_stock < v_qty THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Not enough stock for one of the products - order cancelled';
        END IF;

        SET idx = idx + 1;
    END WHILE;

    -- Pass 2: every line passed validation and every product row is
    -- still locked, so it's now safe to actually create the order and
    -- apply the stock changes.

    INSERT INTO orders (customer_id) VALUES (cust_id);
    SET new_order_id = LAST_INSERT_ID();

    SET idx = 0;
    WHILE idx < item_count DO
        SET v_product_id = JSON_EXTRACT(items_json, CONCAT('$[', idx, '].product_id')) + 0;
        SET v_qty        = JSON_EXTRACT(items_json, CONCAT('$[', idx, '].quantity')) + 0;

        INSERT INTO order_details (order_id, product_id, quantity)
        VALUES (new_order_id, v_product_id, v_qty);

        UPDATE products
        SET stock_quantity = stock_quantity - v_qty
        WHERE product_id = v_product_id;

        SELECT stock_quantity INTO v_new_stock
        FROM products
        WHERE product_id = v_product_id;

        INSERT INTO inventory_logs (product_id, change_qty, reason, running_balance)
        VALUES (v_product_id, -v_qty, 'Order placed', v_new_stock);

        SET idx = idx + 1;
    END WHILE;

    -- Total is computed once, after every line is in, from the
    -- GENERATED line_total column - no per-row recalculation trigger
    -- needed.

    UPDATE orders
    SET total_amount = (
        SELECT SUM(line_total) FROM order_details WHERE order_id = new_order_id
    )
    WHERE order_id = new_order_id;

    COMMIT;

    SELECT new_order_id AS order_created;
END $$

-- 2. Order with ONE product - thin wrapper around place_order_multi so
--    existing single-product callers don't need to change.
--
--    CALL place_order(1, 5, 3);
--    (customer 1 buys 3 of product 5)

CREATE PROCEDURE place_order (
    IN cust_id INT,
    IN prod_id INT,
    IN qty     INT
)
BEGIN
    CALL place_order_multi(
        cust_id,
        JSON_ARRAY(JSON_OBJECT('product_id', prod_id, 'quantity', qty))
    );
END $$

-- 3. Restock one product.
--    CALL restock_product(5, 50);

CREATE PROCEDURE restock_product (
    IN prod_id INT,
    IN qty     INT
)
BEGIN
    DECLARE v_exists    INT;
    DECLARE v_new_stock INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF qty IS NULL OR qty <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Restock quantity must be greater than 0';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_exists
    FROM products
    WHERE product_id = prod_id
    FOR UPDATE;

    IF v_exists = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unknown product_id - restock cancelled';
    END IF;

    UPDATE products
    SET stock_quantity = stock_quantity + qty
    WHERE product_id = prod_id;

    SELECT stock_quantity INTO v_new_stock
    FROM products
    WHERE product_id = prod_id;

    INSERT INTO inventory_logs (product_id, change_qty, reason, running_balance)
    VALUES (prod_id, qty, 'Manual restock', v_new_stock);

    COMMIT;
END $$

-- 4. Restock EVERY low product automatically.
--
--    CALL restock_all_low_stock();
--
--    Uses a cursor (rather than one bulk UPDATE + one bulk INSERT) so
--    each product's row is individually locked with FOR UPDATE and its
--    own accurate post-restock running_balance can be written to
--    inventory_logs - a set-based UPDATE can't give each row its own
--    "balance right after this specific change" value.

CREATE PROCEDURE restock_all_low_stock ()
BEGIN
    DECLARE done          INT DEFAULT FALSE;
    DECLARE v_product_id  INT;
    DECLARE v_reorder_qty INT;
    DECLARE v_new_stock   INT;

    DECLARE low_cursor CURSOR FOR
        SELECT product_id, reorder_qty
        FROM products
        WHERE stock_quantity <= reorder_level
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    OPEN low_cursor;

    restock_loop: LOOP
        FETCH low_cursor INTO v_product_id, v_reorder_qty;
        IF done THEN
            LEAVE restock_loop;
        END IF;

        UPDATE products
        SET stock_quantity = stock_quantity + v_reorder_qty
        WHERE product_id = v_product_id;

        SELECT stock_quantity INTO v_new_stock
        FROM products
        WHERE product_id = v_product_id;

        INSERT INTO inventory_logs (product_id, change_qty, reason, running_balance)
        VALUES (v_product_id, v_reorder_qty, 'Auto restock', v_new_stock);
    END LOOP;

    CLOSE low_cursor;
    COMMIT;
END $$

DELIMITER ;
