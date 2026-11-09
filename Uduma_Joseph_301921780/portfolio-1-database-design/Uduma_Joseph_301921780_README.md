# Portfolio 1: Database Design and Modelling

## Selected case study
**Organisation / scenario:** NaijaMart, a simulated Nigerian online retail (e-commerce) platform.
**Nature of the system:** customers browse a product catalogue, place orders, pay by card, bank transfer, USSD or wallet, and receive deliveries through courier partners.
**Users of the database:** customers (via the web app), sales/operations staff, warehouse staff, finance (payment reconciliation), and analysts.
**Major data stored:** customers and addresses, categories, products with price and stock, orders and order lines, payments, deliveries, stock movements.
**Key operations supported:** add products, place orders, update stock, process payment, track delivery, report on sales.

The same case study is used in Portfolios 2 to 5.

## Files
| File | Purpose |
|---|---|
| `Uduma_Joseph_301921780_01_schema.sql` | DDL: tables, primary/foreign keys, constraints |
| `Uduma_Joseph_301921780_02_seed_data.sql` | Generates 20,000 customers, 5,000 products, 200,000 orders, about 400,000 order lines and 200,000 payments |
| `Uduma_Joseph_301921780_er_diagram.dot` / `Uduma_Joseph_301921780_er_diagram.png` | ER diagram (Graphviz source and rendered image) |

## Keys and constraints
- **Primary keys:** surrogate `SERIAL` keys on every entity table; `order_items` uses the composite key `(order_id, product_id)` because a product appears once per order.
- **Foreign keys:** every relationship in the ER diagram is enforced. `addresses` cascades on customer delete and `order_items` cascades on order delete. Orders, payments and deliveries do not cascade, so financial history is not silently destroyed.
- **Unique:** `customers.email`, `categories.name`, `deliveries.order_id` (at most one delivery per order).
- **CHECK:** `price >= 0`, `stock_qty >= 0` (stops overselling at the database level), `quantity > 0`, `payments.amount > 0`, and allowed-value lists for order status, payment method/status and delivery status.
- **NOT NULL / DEFAULT:** applied to mandatory attributes; timestamps default to `now()`.

## Normalisation
- **1NF:** all columns are atomic. Repeating groups such as several products on one order are moved into `order_items` instead of columns like `product1, product2`.
- **2NF:** in `order_items`, `quantity` and `unit_price` depend on the whole key `(order_id, product_id)`. Product name and category are not stored there, so there is no partial dependency.
- **3NF:** non-key attributes depend only on the key. Category name lives in `categories`, not repeated on each product. Customer details live in `customers`, not on orders. Address details are in `addresses`.
- **BCNF:** every determinant in these tables is a candidate key. The only functional dependencies are key to attribute.
- **Deliberate denormalisation:** `order_items.unit_price` copies the product price at the time of sale. This is intentional: if `products.price` changes later, historical orders must not change. Without it, past invoices and revenue reports would be wrong.

## How it was tested
Schema and seed scripts were run on PostgreSQL 16 with `ON_ERROR_STOP=1` and completed without errors. Row counts after seeding are in `evidence/Uduma_Joseph_301921780_row_counts.txt`.
