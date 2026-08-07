
--  Database design and schema

DROP DATABASE IF EXISTS inventory_order;
CREATE DATABASE inventory_order;
USE inventory_order;

-- customers table

CREATE TABLE customers (
    customer_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_name  VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    phone          VARCHAR(20),
    UNIQUE KEY uq_customers_email (email)
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
    reorder_qty     INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_products_price         CHECK (price >= 0),
    CONSTRAINT chk_products_reorder_level CHECK (reorder_level >= 0),
    CONSTRAINT chk_products_reorder_qty   CHECK (reorder_qty >= 0)
);


-- orders table

CREATE TABLE orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT NOT NULL,
    order_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount  DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT chk_orders_total_amount CHECK (total_amount >= 0)
);


-- order_details table (one row per product in an order)

-- discount_pct and line_total are filled in by a trigger.

CREATE TABLE order_details (
    order_detail_id  INT AUTO_INCREMENT PRIMARY KEY,
    order_id         INT NOT NULL,
    product_id       INT NOT NULL,
    quantity         INT NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_pct     DECIMAL(5,2) GENERATED ALWAYS AS (
                          CASE
                              WHEN quantity >= 100 THEN 15
                              WHEN quantity >= 50  THEN 10
                              WHEN quantity >= 25  THEN 5
                              WHEN quantity >= 10  THEN 2.5
                              ELSE 0
                          END
                      ) STORED,

    -- Line total after discount, rounded to 2 decimal places.
    line_total       DECIMAL(10,2) GENERATED ALWAYS AS (
                          ROUND(quantity * unit_price * (1 - discount_pct / 100), 2)
                      ) STORED,
    UNIQUE KEY uq_order_product (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT chk_order_details_quantity   CHECK (quantity > 0),
    CONSTRAINT chk_order_details_unit_price CHECK (unit_price >= 0)
);


-- inventory_logs  (history of every stock change)

CREATE TABLE inventory_logs (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_id  INT NOT NULL,
    change_qty  INT NOT NULL,
    reason           ENUM('Opening stock', 'Order placed', 'Manual restock', 'Auto restock') NOT NULL,
    running_balance  INT UNSIGNED NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT chk_inventory_logs_change_qty CHECK (change_qty <> 0)
);



SHOW TABLES;
