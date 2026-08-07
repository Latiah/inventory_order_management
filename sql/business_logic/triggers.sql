
--  LOG INVENTORY 

USE inventory_order;

DROP TRIGGER IF EXISTS after_product_insert;
DROP TRIGGER IF EXISTS before_order_detail_insert;
DROP TRIGGER IF EXISTS after_order_detail_log_inventory;
DROP TRIGGER IF EXISTS after_order_detail_update_stock;
DROP TRIGGER IF EXISTS after_order_detail_update_total;

DELIMITER $$

-- Log the starting stock when a new product is added.
-- running_balance here is simply the opening stock itself.

CREATE TRIGGER after_product_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity > 0 THEN
        INSERT INTO inventory_logs (product_id, change_qty, reason, running_balance)
        VALUES (NEW.product_id, NEW.stock_quantity, 'Opening stock', NEW.stock_quantity);
    END IF;
END $$

-- Stamp today's product price onto the order line before it's inserted.
-- This is a genuine snapshot (products.price can change later and we
-- must keep what the customer was actually charged), so it stays a
-- trigger rather than becoming a generated column, which cannot read
-- another table. discount_pct and line_total no longer need to be set
-- here - they are GENERATED columns on order_details now (see
-- create_tables.sql) and are computed by the engine from quantity and
-- the unit_price set below.

CREATE TRIGGER before_order_detail_insert
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE current_price DECIMAL(10,2);

    SELECT price INTO current_price
    FROM products
    WHERE product_id = NEW.product_id;

    IF current_price IS NOT NULL THEN
        SET NEW.unit_price = current_price;
    END IF;
END $$

DELIMITER ;
