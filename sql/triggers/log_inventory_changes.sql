
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
