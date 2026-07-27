
--  LOG INVENTORY

-- Every change to stock gets written to inventory_logs.

-- Two triggers:
--   - opening stock, when a product is first added
--   - stock going out, when an order line is added

USE inventory_order;

DROP TRIGGER IF EXISTS after_product_insert;
DROP TRIGGER IF EXISTS after_order_detail_log_inventory;

DELIMITER $$


-- Log the starting stock when a new product is added.

CREATE TRIGGER after_product_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity > 0 THEN
        INSERT INTO inventory_logs (product_id, change_qty, reason)
        VALUES (NEW.product_id, NEW.stock_quantity, 'Opening stock');
    END IF;
END $$

-- Log stock going out when an order line is added.
-- change_qty is negative because stock is leaving.

CREATE TRIGGER after_order_detail_log_inventory
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    INSERT INTO inventory_logs (product_id, change_qty, reason)
    VALUES (NEW.product_id, -NEW.quantity, 'Order placed');
END $$

DELIMITER ;



-- Work out the price, discount and line total


DROP TRIGGER IF EXISTS before_order_detail_insert;

DELIMITER $$

CREATE TRIGGER before_order_detail_insert
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE current_price DECIMAL(10,2);

    -- Look up today's price for this product
    SELECT price INTO current_price
    FROM products
    WHERE product_id = NEW.product_id;

    -- Only fill things in if the product actually exists.
    IF current_price IS NOT NULL THEN
        SET NEW.unit_price = current_price;

        -- Bulk discount - the more you buy, the bigger the discount
        SET NEW.discount_pct = CASE
            WHEN NEW.quantity >= 100 THEN 15
            WHEN NEW.quantity >= 50  THEN 10
            WHEN NEW.quantity >= 25  THEN 5
            WHEN NEW.quantity >= 10  THEN 2.5
            ELSE 0
        END;

        -- Line total after the discount, rounded to 2 decimal places
        SET NEW.line_total = ROUND(
            NEW.quantity * NEW.unit_price * (1 - NEW.discount_pct / 100), 2);
    END IF;
END $$

DELIMITER ;



--  UPDATE INVENTORY

-- Two triggers, each doing one job:
--   - take the items out of stock
--   - recalculate the order total



DROP TRIGGER IF EXISTS after_order_detail_update_stock;
DROP TRIGGER IF EXISTS after_order_detail_update_total;

DELIMITER $$

-- Take the items out of stock.

CREATE TRIGGER after_order_detail_update_stock
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END $$

-- Recalculate the order total.
-- It adds the lines up again from scratch instead of doing
-- total = total + new line. If a line ever went missing, adding
-- up again still gives the right answer.

CREATE TRIGGER after_order_detail_update_total
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT SUM(line_total)
        FROM order_details
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
END $$

DELIMITER ;
