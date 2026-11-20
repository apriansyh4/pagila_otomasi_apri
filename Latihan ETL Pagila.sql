--
-- create schema staging

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

--staging =============================================================

CREATE TABLE staging.stg_customer (
    customer_id INTEGER,
    first_name VARCHAR(45),
    last_name VARCHAR(45),
    email VARCHAR(50),
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

CREATE TABLE staging.stg_film (
    film_id INTEGER,
    title VARCHAR(255),
    rental_rate NUMERIC(4,2),
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

CREATE TABLE staging.stg_payment (
    payment_id INTEGER,
    customer_id INTEGER,
    rental_id INTEGER,
    amount NUMERIC(5,2),
    payment_date TIMESTAMP,
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

CREATE TABLE staging.stg_rental (
    rental_id INTEGER,
    inventory_id INTEGER,
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

CREATE TABLE staging.stg_inventory (
    inventory_id INTEGER,
    film_id INTEGER,
    store_id INTEGER,
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

CREATE TABLE staging.stg_store (
    store_id INTEGER,
    address_id INTEGER,
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

CREATE TABLE staging.stg_address (
    address_id INTEGER,
    address VARCHAR(50),
    batch_id VARCHAR(30),
    extract_time TIMESTAMP
);

--full extraction ===================================================================================================

INSERT INTO staging.stg_customer
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    'B001',
    CURRENT_TIMESTAMP
FROM public.customer;

INSERT INTO staging.stg_payment
SELECT
    payment_id,
    customer_id,
    rental_id,
    amount,
    payment_date,
    'B001',
    CURRENT_TIMESTAMP
FROM public.payment;


INSERT INTO staging.stg_film
SELECT
    film_id,
    title,
    rental_rate,
    'B001',
    CURRENT_TIMESTAMP
FROM public.film;

INSERT INTO staging.stg_rental
SELECT rental_id, inventory_id,
       'B001', CURRENT_TIMESTAMP
FROM public.rental;

INSERT INTO staging.stg_inventory
SELECT inventory_id, film_id, store_id,
       'B001', CURRENT_TIMESTAMP
FROM public.inventory;

INSERT INTO staging.stg_store
SELECT store_id, address_id,
       'B001', CURRENT_TIMESTAMP
FROM public.store;

INSERT INTO staging.stg_address
SELECT address_id, address,
       'B001', CURRENT_TIMESTAMP
FROM public.address;

--validasi ===========================================================================================================

SELECT COUNT(*) FROM public.payment;

SELECT COUNT(*) FROM staging.stg_payment;

SELECT *
FROM staging.stg_payment
LIMIT 10;


-- check SQL untuk transform ==============================================================================================

--untuk stg.customer
SELECT
    customer_id,
    INITCAP(TRIM(first_name)) AS first_name,
    INITCAP(TRIM(last_name)) AS last_name,
    LOWER(TRIM(email)) AS email,
    CONCAT_WS(
        ' ',
        INITCAP(TRIM(first_name)),
        INITCAP(TRIM(last_name))
    ) AS full_name
FROM staging.stg_customer;

--stm film untuk ke dim_film
SELECT
    film_id,
    TRIM(title) AS title,
    rental_rate
FROM staging.stg_film;

--dim__store
SELECT
    s.store_id,
    TRIM(a.address) AS store_address
FROM staging.stg_store s
JOIN staging.stg_address a
    ON s.address_id = a.address_id;

-- dim_date
SELECT DISTINCT
    TO_CHAR(payment_date, 'YYYYMMDD')::INTEGER
        AS date_key,
    payment_date::DATE
        AS full_date,
    EXTRACT(DAY FROM payment_date)::INTEGER
        AS day,
    EXTRACT(MONTH FROM payment_date)::INTEGER
        AS month,
    EXTRACT(QUARTER FROM payment_date)::INTEGER
        AS quarter,
    EXTRACT(YEAR FROM payment_date)::INTEGER
        AS year
FROM staging.stg_payment
WHERE payment_date IS NOT NULL;

-- fact_payment
SELECT
    p.payment_id,
    p.payment_date,
    p.customer_id,
    i.film_id,
    i.store_id,
    p.amount
FROM staging.stg_payment p
JOIN staging.stg_rental r
    ON p.rental_id = r.rental_id
JOIN staging.stg_inventory i
    ON r.inventory_id = i.inventory_id;

-- LOAD ====================================================================================================

-- Create DW schema first

--dimensi
CREATE TABLE dw.dim_customer (
    customer_key INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL UNIQUE,
    first_name VARCHAR(45),
    last_name VARCHAR(45),
    full_name VARCHAR(100),
    email VARCHAR(50)
);

CREATE TABLE dw.dim_film (
    film_key INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    film_id INTEGER NOT NULL UNIQUE,
    title VARCHAR(255),
    rental_rate NUMERIC(4,2)
);

CREATE TABLE dw.dim_store (
    store_key INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_id INTEGER NOT NULL UNIQUE,
    store_address VARCHAR(100)
);

CREATE TABLE dw.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day INTEGER,
    month INTEGER,
    quarter INTEGER,
    year INTEGER
);

-- fact
CREATE TABLE dw.fact_payment (
    payment_id INTEGER PRIMARY KEY,
    date_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    film_key INTEGER NOT NULL,
    store_key INTEGER NOT NULL,
    revenue_amount NUMERIC(10,2) NOT NULL,
    FOREIGN KEY (date_key)
        REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (customer_key)
        REFERENCES dw.dim_customer(customer_key),
    FOREIGN KEY (film_key)
        REFERENCES dw.dim_film(film_key),
    FOREIGN KEY (store_key)
        REFERENCES dw.dim_store(store_key)
);

--LOAD===============================================================================================================
--load dim_customer

INSERT INTO dw.dim_customer (
    customer_id,
    first_name,
    last_name,
    full_name,
    email
)
SELECT
    customer_id,
    INITCAP(TRIM(first_name)),
    INITCAP(TRIM(last_name)),
    CONCAT_WS(
        ' ',
        INITCAP(TRIM(first_name)),
        INITCAP(TRIM(last_name))
    ),
    LOWER(TRIM(email))
FROM staging.stg_customer;

INSERT INTO dw.dim_film (
    film_id,
    title,
    rental_rate
)
SELECT
    film_id,
    TRIM(title),
    rental_rate
FROM staging.stg_film;

INSERT INTO dw.dim_store (
    store_id,
    store_address
)
SELECT
    s.store_id,
    TRIM(a.address)
FROM staging.stg_store s
JOIN staging.stg_address a
    ON s.address_id = a.address_id;

INSERT INTO dw.dim_date (
    date_key,
    full_date,
    day,
    month,
    quarter,
    year
)
SELECT DISTINCT
    TO_CHAR(payment_date, 'YYYYMMDD')::INTEGER,
    payment_date::DATE,
    EXTRACT(DAY FROM payment_date)::INTEGER,
    EXTRACT(MONTH FROM payment_date)::INTEGER,
    EXTRACT(QUARTER FROM payment_date)::INTEGER,
    EXTRACT(YEAR FROM payment_date)::INTEGER
FROM staging.stg_payment
WHERE payment_date IS NOT NULL;

--load fact
INSERT INTO dw.fact_payment (
    payment_id,
    date_key,
    customer_key,
    film_key,
    store_key,
    revenue_amount
)
SELECT
    p.payment_id,
    d.date_key,
    c.customer_key,
    f.film_key,
    s.store_key,
    p.amount
FROM staging.stg_payment p
JOIN staging.stg_rental r
    ON p.rental_id = r.rental_id
JOIN staging.stg_inventory i
    ON r.inventory_id = i.inventory_id
JOIN dw.dim_date d
    ON p.payment_date::DATE = d.full_date
JOIN dw.dim_customer c
    ON p.customer_id = c.customer_id
JOIN dw.dim_film f
    ON i.film_id = f.film_id
JOIN dw.dim_store s
    ON i.store_id = s.store_id;


-- VALIDATION=======================================================================================================
--row count validation 
SELECT
    (SELECT COUNT(*)
     FROM staging.stg_payment) AS source_count,

    (SELECT COUNT(*)
     FROM dw.fact_payment) AS target_count;
    
-- COMPLETENESS VALIDATION
SELECT COUNT(*) AS null_count
FROM dw.fact_payment
WHERE date_key IS NULL
   OR customer_key IS NULL
   OR film_key IS NULL
   OR store_key IS NULL
   OR revenue_amount IS NULL;
 

-- duplicate check
SELECT
    payment_id,
    COUNT(*) AS jumlah
FROM dw.fact_payment
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- ref integrity validation
SELECT COUNT(*) AS invalid_customer_key
FROM dw.fact_payment f
LEFT JOIN dw.dim_customer c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

--reconciliation ->memastikan total pendapatan di DW sama dengan total pembayaran pada sumber.
SELECT
    (SELECT SUM(amount)
     FROM staging.stg_payment) AS source_revenue,

    (SELECT SUM(revenue_amount)
     FROM dw.fact_payment) AS dw_revenue;

 -- check staging--> fact apakah ada yang tertinggal
    
    SELECT
    p.payment_id,
    p.customer_id,
    p.amount
FROM staging.stg_payment p
LEFT JOIN dw.fact_payment f
    ON p.payment_id = f.payment_id
WHERE f.payment_id IS NULL;
  

--DW ANALYSIS========================================================================================================

-- query DW: monthly total revenue
 
SELECT
    d.year,
    d.month,
    SUM(f.revenue_amount) AS total_revenue
FROM dw.fact_payment f
JOIN dw.dim_date d
    ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

--Lima film dengan pendapatan terbesar
SELECT
    fi.title,
    SUM(fp.revenue_amount) AS total_revenue
FROM dw.fact_payment fp
JOIN dw.dim_film fi
    ON fp.film_key = fi.film_key
GROUP BY fi.film_key, fi.title
ORDER BY total_revenue DESC
LIMIT 5;

--Lima pelanggan dengan pendapatan terbesar

SELECT
    c.full_name,
    SUM(f.revenue_amount) AS total_revenue
FROM dw.fact_payment f
JOIN dw.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.full_name
ORDER BY total_revenue DESC
LIMIT 5;

--Total pendapatan berdasarkan toko
SELECT
    s.store_id,
    s.store_address,
    SUM(f.revenue_amount) AS total_revenue
FROM dw.fact_payment f
JOIN dw.dim_store s
    ON f.store_key = s.store_key
GROUP BY s.store_id, s.store_address
ORDER BY total_revenue DESC;
    
  
    
    
    
    
