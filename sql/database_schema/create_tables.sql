-- create database and tables for inventory order management system.

DROP DATABASE IF EXISTS inventory_order; 
CREATE DATABASE inventory_order;
USE inventory_order;



-- products table
CREATE TABLE products(
product_id INT(20),
product_name VARCHAR(50),
category  VARCHAR(50),
price DECIMAL(50, 2),
stock_quantity INT(10),
reorder_level INT(10),
PRIMARY KEY (product_id)
);


-- customers table
CREATE TABLE customers(
customer_id INT(20),
customer_name VARCHAR(50),
email VARCHAR(50),
phone_number VARCHAR(50),
PRIMARY KEY (customer_id),
);

-- orders table
CREATE TABLE orders(
order_id INT(20),
customer_id INT(20),
order_date DATE,
total_amount DECIMAL(50, 2),
PRIMARY KEY (order_id),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- order Details table
CREATE TABLE order_details(
order_id INT(20),
product_id INT(20),
quantity INT(10),
unit_price DECIMAL(50, 2),
PRIMARY KEY (order_id, product_id)
);


SHOW tables;
