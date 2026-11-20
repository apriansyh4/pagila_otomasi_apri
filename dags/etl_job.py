from airflow import DAG
from airflow.operators.python import PythonOperator

from script.etl import (
    create, extract, transform_load
)

with DAG(
    "pagila_etl_job",
    description="Pagila ETL Process",
    schedule="*/5 * * * *"
) as dags:
    create = PythonOperator(
        task_id="create",
        python_callable=create
    )
    
    extract = PythonOperator(
        task_id="extract",
        python_callable=extract
    )
    
    transform_load = PythonOperator(
        task_id="transform_load",
        python_callable=transform_load
    )
    
    create >> extract >> transform_load