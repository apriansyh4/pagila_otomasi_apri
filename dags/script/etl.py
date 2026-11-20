import psycopg2

from psycopg2.extras import RealDictCursor

def main():
    # Task create:
    # 1. Pastikan database pagila dari pertemuan minggu sebelumnya sudah ada
    # 2. Buatlah database baru dengan nama pagila_otomasi
    # 3. Buatlah skema staging dan dw
    # 4. Lengkapi setiap fungsi dibawah. Contohnya ada di create_staging_customer
    create() 
    
    # Task extract:
    # 1a. Dalam setiap fungsi extract terdapat query check untuk memeriksa apakah data sudah ada.
    # 1b. Lihat bahwa disana terdapat query filter 'WHERE'. Sementara value nya static dengan isi 'B001'
    # 2a. cursor.rowcount digunakan untuk memeriksa jumlah query yang ter eksekusi. Cek nilainya dengan 0
    # 2b. Apabila memang kosong, lakukan perulangan dengan membaca 'data_<nama_tabel>'. Lihat disana ada kode for ... in ... :
    # 2c. Lakukan proses insert
    # 3. Lengkapi setiap fungsi dibawah. Ganti 'pass' dengan kode yang seharusnya
    extract()
    
    # Task transform & load:
    # 1a. Pada bagian transform load adalah proses transformasi dan loading ke skema dw
    # 1b. Lihat pada 'Latihan ETL Pagila.sql' terdapat query 'INSERT ... SELECT ...'
    # 2. Lengkapi setiap fungsi dibawah. Ganti 'pass' dengan kode yang seharusnya
    transform_load()   
    
    # NOTE: INGAT YA JANGAN PAKAI AI APAPUN. BIASAKAN KETIK SENDIRI SUPAYA HAFAL DAN BELAJAR DENGAN BAIK.
    # CARA BELAJAR YANG BAIK ADALAH DENGAN MENCOBA. GOOD LUCK!

# ======================= connection =======================

def connection(dbname):
    dsn = f"host=localhost port=5433 user=postgres password=postgres dbname={dbname}"
    conn = psycopg2.connect(dsn, cursor_factory=RealDictCursor)
    cursor = conn.cursor()
    return conn, cursor

# ======================= create =======================

def create():
    conn_otomasi, cursor_otomasi = connection('pagila_otomasi2')
    
    # Prepare schema
    create_staging(conn_otomasi, cursor_otomasi)
    create_dw(conn_otomasi, cursor_otomasi) 
    
    # Create staging table
    create_staging_customer(conn_otomasi, cursor_otomasi)
    
    # Create staging table
    create_staging_film(conn_otomasi, cursor_otomasi)
    
    # Create staging  payment
    create_staging_payment(conn_otomasi, cursor_otomasi)
    
    #Create staging rental
    create_staging_rental(conn_otomasi, cursor_otomasi)
    
    #Create staging inventory
    create_staging_inventory(conn_otomasi, cursor_otomasi)
    
    #Create staging store
    create_staging_store(conn_otomasi, cursor_otomasi)
    
    #create table address
    create_staging_address(conn_otomasi, cursor_otomasi)
# ======================= extract =======================
    
def extract():
    conn_pagila, cursor_pagila = connection('pagila')
    conn_po, cursor_po = connection('pagila_otomasi')
    
    # check and insert data customer
    data_customer = extract_table_customer(conn_pagila, cursor_pagila)
    insert_data_customer(conn_po, cursor_po, data_customer)
    
    # check and insert data film
    data_film = extract_table_film(conn_pagila, cursor_pagila)
    insert_data_film(conn_po, cursor_po, data_film)
    
    # check and insert data payment
    data_payment = extract_table_payment(conn_pagila, cursor_pagila)
    insert_data_payment(conn_po, cursor_po, data_payment)
    
    # check and insert data rental
    data_rental = extract_table_rental(conn_pagila, cursor_pagila)
    insert_data_rental(conn_po, cursor_po, data_rental)
    
    #Check and insert data inventory
    data_inventory = extract_table_inventory(conn_pagila, cursor_pagila)
    insert_data_inventory(conn_po, cursor_po, data_inventory)
    
    #check and insert stoer
    data_store = extract_table_store(conn_pagila, cursor_pagila)
    insert_data_store(conn_po, cursor_po, data_store)
    
    #check and insert address
    data_address = extract_table_address(conn_pagila, cursor_pagila)
    insert_data_address(conn_po, cursor_po, data_address)

# ======================= transform - load =======================

def transform_load():
    conn_po, cursor_po = connection('pagila_otomasi')
    
    # transform & load data customer
    transform_load_customer(conn_po, cursor_po)    

# ======================= create schema staging & dw =======================

def create_staging(conn, cursor):
    query = "CREATE SCHEMA IF NOT EXISTS staging"
    cursor.execute(query)
    conn.commit()

def create_dw(conn, cursor):
    query = "CREATE SCHEMA IF NOT EXISTS dw"
    cursor.execute(query)
    conn.commit()

# ======================= create table staging =======================

def create_staging_customer(conn, cursor):
    query = """
    CREATE TABLE IF NOT EXISTS 
        staging.stg_customer (
            customer_id INTEGER,
            first_name VARCHAR(45),
            last_name VARCHAR(45),
            email VARCHAR(50),
            batch_id VARCHAR(30),
            extract_time TIMESTAMP
        ) 
    """
    cursor.execute(query)
    conn.commit()

def create_staging_film(conn, cursor):
    pass
    
def create_staging_payment(conn, cursor):
    pass
    
def create_staging_rental(conn, cursor):
    pass
    
def create_staging_inventory(conn, cursor):
    pass
    
def create_staging_store(conn, cursor):
    pass
    
def create_staging_address(conn, cursor):
    pass
    
# ======================= extract table staging =======================
    
def extract_table_customer(conn_pagila, cursor_pagila):
    query = """
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        %s,
        CURRENT_TIMESTAMP
    FROM public.customer"""
    
    cursor_pagila.execute(query, ('B001',))
    conn_pagila.commit()
    
    return cursor_pagila.fetchall()

def extract_table_film(conn_pagila, cursor_pagila):
    pass

def extract_table_payment(conn_pagila, cursor_pagila):
    pass

def extract_table_rental(conn_pagila, cursor_pagila):
    pass

def extract_table_inventory(conn_pagila, cursor_pagila):
    pass

def extract_table_store(conn_pagila, cursor_pagila):
    pass

def extract_table_address(conn_pagila, cursor_pagila):
    pass
    
# ======================= insert table staging =======================

def insert_data_customer(conn_po, cursor_po, data_customer):
    # check table customer by batch_id before inserting the data
    query_check = "SELECT * FROM staging.stg_customer WHERE batch_id = %s"
    cursor_po.execute(query_check, ('B001',))
    
    # if customer data is not exist
    if cursor_po.rowcount == 0:
        # do iteration (loop) for each row data
        for item in data_customer:
            query = """
            INSERT INTO 
                staging.stg_customer (customer_id, first_name, 
                last_name, email, batch_id, extract_time)
            VALUES (%s, %s, %s, %s, %s, %s)
            """
            cursor_po.execute(query, (
                item['customer_id'], item['first_name'], item['last_name'],
                item['email'], 'B001', 'NOW()'
            ))
            conn_po.commit()

def insert_data_film(conn_po, cursor_po, data_film):
    pass
            
def insert_data_payment(conn_po, cursor_po, data_payment):
    pass
            
def insert_data_rental (conn_po, cursor_po, data_rental):
    pass
        
def insert_data_inventory (conn_po, cursor_po, data_inventory):
    pass
        
def insert_data_store (conn_po, cursor_po, data_store):
    pass
        
def insert_data_address (conn_po, cursor_po, data_address):
    pass

# ======================= transform data & load customer =======================

def transform_load_customer(conn_po, cursor_po):
    pass
    
def transform_load_film(conn_po, cursor_po):
    pass
    
def transform_load_store(conn_po, cursor_po):
    pass
    
def transform_load_date(conn_po, cursor_po):
    pass

def transform_load_payment(conn_po, cursor_po):
    pass

    
if __name__ == '__main__':
    # 1. run 'python.exe (atau py.exe) etl.py
    # 2. pastikan bahwa tabel telah di insert / table dibuat
    main()