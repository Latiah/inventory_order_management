
--  UPDATE INVENTORY

-- Two triggers, each doing one job:
--   - take the items out of stock
--   - recalculate the order total


USE inventory_order;

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
