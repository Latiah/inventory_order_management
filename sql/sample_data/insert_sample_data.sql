
-- Sample data


USE inventory_order;

INSERT INTO customers (customer_name, email, phone) VALUES
('Aline Mukamana',    'aline@example.com',   '0788100001'),
('Jean-Paul Habimana','jp@example.com',      '0788100002'),
('Grace Uwase',       'grace@example.com',   '0788100003'),
('Eric Nshimiyimana', 'eric@example.com',    '0788100004'),
('Claudine Ingabire', 'claudine@example.com','0788100005'),
('Patrick Bizimana',  'patrick@example.com', NULL);


INSERT INTO products
    (product_name, category, price, stock_quantity, reorder_level, reorder_qty)
VALUES
('Laptop',           'Electronics', 899.99,  40,  10,  25),
('Monitor',          'Electronics', 219.50,  60,  15,  30),
('Keyboard',         'Electronics',  79.00, 200,  40, 100),
('Wireless Mouse',   'Electronics',  24.99, 350,  50, 150),
('Headset',          'Electronics', 149.00,  12,  20,  40),
('USB-C Cable',      'Accessories',   9.50, 800, 100, 400),
('Docking Station',  'Accessories', 129.99,   8,  15,  30),
('Office Chair',     'Furniture',   349.00,  25,   8,  20),
('Standing Desk',    'Furniture',   599.00,   5,   6,  12),
('Desk Lamp',        'Furniture',    45.00, 120,  30,  60),
('Notebook',         'Stationery',    4.75, 950, 200, 500),
('Gel Pens',         'Stationery',    6.25, 600, 150, 400),
('A4 Paper Ream',    'Stationery',    7.80,  90, 100, 300),
('Wi-Fi Router',     'Networking',  189.00,  35,  10,  25),
('Network Switch',   'Networking',   89.99,   0,   5,  20);


-- Orders with a single product

CALL place_order(1, 1, 1);     -- 1 laptop,        no discount
CALL place_order(2, 6, 30);    -- 30 cables,       5% discount
CALL place_order(3, 11, 150);  -- 150 notebooks,  15% discount
CALL place_order(4, 8, 2);     -- 2 chairs,        no discount
CALL place_order(5, 10, 12);   -- 12 lamps,      2.5% discount
CALL place_order(6, 13, 10);   -- 10 reams,      2.5% discount


-- One order with THREE different products.
-- Order 7 is created first, then items are added to it.

CALL start_order(1);
CALL add_item(7, 1, 12);       -- 12 laptops,   2.5% discount
CALL add_item(7, 8, 10);       -- 10 chairs,    2.5% discount
CALL add_item(7, 9, 2);        -- 2 desks,        no discount

-- Another multi-product order

CALL start_order(2);
CALL add_item(8, 3, 55);       -- 55 keyboards,  10% discount
CALL add_item(8, 4, 5);        -- 5 mice,         no discount
