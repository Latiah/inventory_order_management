
--  Triggers


USE inventory_db;

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


CREATE TRIGGER before_order_detail_insert
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE current_price DECIMAL(10,2);

    -- Look up today's price for this product
    SELECT price INTO current_price
    FROM products
    WHERE product_id = NEW.product_id;

    SET NEW.unit_price = current_price;

    -- Bulk discount: the more you buy, the bigger the discount
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
END $$


CREATE TRIGGER after_order_detail_insert
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    -- 1. Take the items out of stock
    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;

    -- 2. Record the change in the log (negative = stock going out)
    INSERT INTO inventory_logs (product_id, change_qty, reason)
    VALUES (NEW.product_id, -NEW.quantity, 'Order placed');

    -- 3. Recalculate the order total by adding up all its lines
    UPDATE orders
    SET total_amount = (
        SELECT SUM(line_total)
        FROM order_details
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
END $$

DELIMITER ;
