# Inventory and Order Management System

Module 3 lab — SQL for Data Professionals.

Inventory and Order Management System for managing products, customers, orders and stock levels,
with automatic stock deduction, inventory logging, bulk discounts, customer
spending tiers and stock replenishment.

---

## Quick start

```bash
mysql -u root -p < setup_all.sql
```

That builds everything and loads sample data. Then open
`sql/queries/08_queries.sql` and start running reports.

---


**The numbers are the run order.** The schema has to exist before the triggers,
the triggers before the sample data, and so on. `setup_all.sql` does 01–07 for
you.

---

## The five tables

| Table | Holds |
|---|---|
| `customers` | name, email, phone |
| `products` | name, category, price, stock, reorder level |
| `orders` | one row per order — customer, date, total |
| `order_details` | one row per product in an order |
| `inventory_logs` | every stock change that has ever happened |

Diagram: `diagrams/erd.mmd`

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

## Commands

```sql
-- Order with one product: customer 1 buys 3 of product 5
CALL place_order(1, 5, 3);

-- Order with several products
CALL start_order(2);        -- returns a new order_id, e.g. 9
CALL add_item(9, 1, 2);     -- 2 of product 1
CALL add_item(9, 7, 5);     -- 5 of product 7

-- Restocking
CALL restock_product(5, 50);      -- add 50 to product 5
CALL restock_all_low_stock();     -- top up everything that is low
```

Ordering more than there is in stock creates nothing and returns a message:

```
+------------------------------------+---------------+---------+
| message                            | you_asked_for | we_have |
+------------------------------------+---------------+---------+
| Not enough stock - order cancelled |           999 |       3 |
+------------------------------------+---------------+---------+
```

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

Applied automatically by `02_pricing_triggers.sql`:

| Quantity | Discount |
|---|---|
| 10+ | 2.5% |
| 25+ | 5% |
| 50+ | 10% |
| 100+ | 15% |

---

## Tests

25 tests across three files. The first two print PASS/FAIL:

```bash
mysql -u root -p inventory_order < sql/tests/test_order_flow.sql
mysql -u root -p inventory_order < sql/tests/test_inventory.sql
mysql -u root -p --force inventory_order < sql/tests/test_constraints.sql
```

`test_constraints.sql` is inverted — every statement in it is *meant* to fail,
so an error means the test passed. It needs `--force` because MySQL otherwise
stops at the first error.

Re-run `setup_all.sql` before testing if you've been experimenting.

---

## Known limits

- No order cancellation or returns
- Discount bands are hardcoded in the trigger rather than in a reference table
- No handling for two people buying the last item simultaneously (the
  `INT UNSIGNED` column still prevents negative stock)
