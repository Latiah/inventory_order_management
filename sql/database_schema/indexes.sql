USE inventory_order;
CREATE INDEX idx_orders_customer  ON orders(customer_id);
CREATE INDEX idx_details_order    ON order_details(order_id);
CREATE INDEX idx_details_product  ON order_details(product_id);
CREATE INDEX idx_logs_product     ON inventory_logs(product_id);