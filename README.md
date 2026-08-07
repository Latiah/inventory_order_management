# Inventory and Order Management System

Module 3 lab — SQL for Data Professionals.

Inventory and Order Management System for managing products, customers, orders and stock levels,
with automatic stock deduction, inventory logging, bulk discounts, customer
spending tiers and stock replenishment.

---

```bash
mysql -u root -p < src/setup_pipeline.sql
```

## The five tables

| Table | Holds |
|---|---|
| `customers` | name, email, phone |
| `products` | name, category, price, stock, reorder level |
| `orders` | one row per order — customer, date, total |
| `order_details` | one row per product in an order |
| `inventory_logs` | every stock change that has ever happened |

Diagram: `diagrams/inventory_order_erd.png`

---

## What it does automatically

Insert one row into `order_details` and five triggers handle the rest:

- looks up the current price
- applies a bulk discount based on quantity
- works out the line total
- subtracts the items from stock
- writes the change to the inventory log
- recalculates the order total

---

## The views

```sql
SELECT * FROM order_summary;      -- customer, date, total, item count
SELECT * FROM low_stock;          -- products needing a reorder
SELECT * FROM customer_spending;  -- total spent + Bronze/Silver/Gold
```

A view is a saved `SELECT`, so you can filter it like a table:

```sql
SELECT * FROM customer_spending WHERE tier = 'Gold';
```

---

## Bulk discounts

Applied automatically by  one of the triggers in the`triggers.sql` file:

| Quantity | Discount |
|---|---|
| 10+ | 2.5% |
| 25+ | 5% |
| 50+ | 10% |
| 100+ | 15% |

---
