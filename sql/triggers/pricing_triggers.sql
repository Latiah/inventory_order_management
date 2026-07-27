
-- Work out the price, discount and line total

USE inventory_order;

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
