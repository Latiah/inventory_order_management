
-- INSERT SAMPLE DATA

USE inventory_order;


-- 1. INSERT DATA INTO PRODUCTS

INSERT INTO products (
    product_id,
    product_name,
    category,
    price,
    stock_quantity,
    reorder_level
)
VALUES
(1, 'Laptop', 'Electronics', 1200.00, 25, 5),

(2, 'Wireless Mouse', 'Accessories', 35.50, 100, 20),

(3, 'Mechanical Keyboard', 'Accessories', 89.99, 40, 10),

(4, 'Monitor', 'Electronics', 299.99, 15, 5),

(5, 'USB-C Cable', 'Accessories', 15.99, 200, 50),

(6, 'Office Chair', 'Furniture', 249.99, 8, 3),

(7, 'Desk Lamp', 'Furniture', 45.00, 30, 10),

(8, 'External Hard Drive', 'Storage', 129.99, 20, 5),

(9, 'Webcam', 'Electronics', 79.99, 12, 5),

(10, 'Headphones', 'Accessories', 99.99, 60, 15),

(11, 'Printer', 'Electronics', 350.00, 7, 5),

(12, 'USB Flash Drive', 'Storage', 18.50, 150, 30),

(13, 'Tablet', 'Electronics', 450.00, 18, 5),

(14, 'Smartphone', 'Electronics', 899.99, 10, 3),

(15, 'Power Bank', 'Accessories', 49.99, 35, 10);




-- 2. INSERT DATA INTO CUSTOMERS

INSERT INTO customers (
    customer_id,
    customer_name,
    email,
    phone_number
)
VALUES
(1, 'Mutoni Annet', 'mutoni.johnson@gmail.com', '0788000001'),

(2, 'Bob Alia', 'bob.alia@gmail.com', '0788000002'),

(3, 'Philip Vicky', 'philip.vicky@gmail.com', '0788006003'),

(4, 'Winny Brenda', 'winy.brenda@gmail.com', '0788090004'),

(5, 'Emma Davis', 'emma.davis@gmail.com', '0788002005'),

(6, 'Kalisa Moses', 'kalisa.moses@gmail.com', '0788900006'),

(7, 'Grace Mugwaneza', 'grace.mugwaneza@gmail.com', '0788070007'),

(8, 'Anny Christelle', 'anny.christelle@gmail.com', '0788600008'),

(9, 'Evy Umubyeyi', 'evy.umubyeyi@gmail.com', '0788040009'),

(10, 'Jackson Mugabo', 'jackson.mugabo@gmail.com', '0788060010');


SELECT * FROM products;

SELECT * FROM customers;


-- 3. INSERT DATA INTO ORDERS

INSERT INTO orders (
    order_id,
    customer_id,
    order_date,
    total_amount
)
VALUES
(101, 1, '2026-07-20', 1271.00),

(102, 2, '2026-07-21', 179.98),

(103, 1, '2026-07-22', 299.99),

(104, 3, '2026-07-23', 325.97),

(105, 4, '2026-07-24', 649.98),

(106, 5, '2026-07-24', 499.95),

(107, 6, '2026-07-25', 899.99),

(108, 7, '2026-07-25', 159.98);


-- 4. INSERT DATA INTO ORDER_DETAILS

INSERT INTO order_details (
    order_id,
    product_id,
    quantity,
    unit_price
)
VALUES
(101, 1, 1, 1200.00),
(101, 2, 2, 35.50),
(102, 3, 2, 89.99),
(103, 4, 1, 299.99),
(104, 6, 1, 249.99),
(104, 7, 1, 45.00),
(104, 5, 2, 15.99),
(105, 8, 1, 129.99),
(105, 9, 1, 79.99),
(105, 10, 1, 99.99),
(106, 11, 1, 350.00),
(106, 12, 1, 18.50),
(106, 15, 1, 49.99),
(107, 14, 1, 899.99),
(108, 15, 2, 49.99),
(108, 5, 1, 15.99);

SELECT * FROM orders;
SELECT * FROM order_details;


