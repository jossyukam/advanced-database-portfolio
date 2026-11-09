-- Portfolio 1: Database Design and Modelling
-- Case study: NaijaMart (simulated Nigerian e-commerce platform)
-- DBMS: PostgreSQL 16
DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA shop;
SET search_path = shop;

CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    address_id    SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    street        VARCHAR(200) NOT NULL,
    city          VARCHAR(80)  NOT NULL,
    state         VARCHAR(50)  NOT NULL,
    is_default    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    name          VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    category_id   INT NOT NULL REFERENCES categories(category_id),
    name          VARCHAR(150) NOT NULL,
    price         NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock_qty     INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(customer_id),
    address_id    INT NOT NULL REFERENCES addresses(address_id),
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                  CHECK (status IN ('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED')),
    order_date    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    order_id      INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INT NOT NULL REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),  -- price at time of sale
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    payment_id    SERIAL PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders(order_id),
    amount        NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    method        VARCHAR(20) NOT NULL CHECK (method IN ('CARD','TRANSFER','USSD','WALLET')),
    status        VARCHAR(15) NOT NULL DEFAULT 'INITIATED'
                  CHECK (status IN ('INITIATED','SUCCESS','FAILED')),
    paid_at       TIMESTAMP
);

CREATE TABLE deliveries (
    delivery_id   SERIAL PRIMARY KEY,
    order_id      INT NOT NULL UNIQUE REFERENCES orders(order_id),
    courier       VARCHAR(60),
    status        VARCHAR(20) NOT NULL DEFAULT 'PROCESSING'
                  CHECK (status IN ('PROCESSING','IN_TRANSIT','DELIVERED','FAILED')),
    updated_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE stock_log (
    log_id        BIGSERIAL PRIMARY KEY,
    product_id    INT NOT NULL REFERENCES products(product_id),
    change_qty    INT NOT NULL,
    reason        VARCHAR(40) NOT NULL,
    logged_at     TIMESTAMP NOT NULL DEFAULT now()
);
