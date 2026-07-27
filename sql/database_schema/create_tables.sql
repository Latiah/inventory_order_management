
--  Database design and schema

DROP DATABASE IF EXISTS inventory_order;
CREATE DATABASE inventory_order;
USE inventory_order;

-- customers table

CREATE TABLE customers (
    customer_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_name  VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    phone          VARCHAR(20)
);


-- products table


-- reorder_level = restock when stock drops to this
-- reorder_qty   = how many to add when restocking

CREATE TABLE products (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_name    VARCHAR(100) NOT NULL,
    category        VARCHAR(50),
    price           DECIMAL(10,2) NOT NULL,
    stock_quantity  INT UNSIGNED NOT NULL DEFAULT 0,
    reorder_level   INT NOT NULL DEFAULT 0,
    reorder_qty     INT NOT NULL DEFAULT 0
);


-- orders table

CREATE TABLE orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT NOT NULL,
    order_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount  DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- order_details table (one row per product in an order)

-- discount_pct and line_total are filled in by a trigger.

CREATE TABLE order_details (
    order_detail_id  INT AUTO_INCREMENT PRIMARY KEY,
    order_id         INT NOT NULL,
    product_id       INT NOT NULL,
    quantity         INT NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_pct     DECIMAL(5,2)  NOT NULL DEFAULT 0,
    line_total       DECIMAL(10,2) NOT NULL DEFAULT 0,
    UNIQUE KEY uq_order_product (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- inventory_logs  (history of every stock change)

CREATE TABLE inventory_logs (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_id  INT NOT NULL,
    change_qty  INT NOT NULL,
    reason      VARCHAR(50) NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- Indexes on the columns we filter and join on most.

CREATE INDEX idx_orders_customer  ON orders(customer_id);
CREATE INDEX idx_details_order    ON order_details(order_id);
CREATE INDEX idx_details_product  ON order_details(product_id);
CREATE INDEX idx_logs_product     ON inventory_logs(product_id);

SHOW TABLES;
