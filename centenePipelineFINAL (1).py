from datetime import timedelta
import datetime
import logging
from airflow import DAG
from airflow.decorators import task
from airflow.providers.google.cloud.transfers.local_to_gcs import (
    LocalFilesystemToGCSOperator,
)
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.dates import days_ago
from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitJobOperator
from airflow import configuration as conf
from airflow.models import DagBag, TaskInstance
from airflow.models.baseoperator import chain
from airflow.operators.bash import BashOperator
from airflow.operators.dummy_operator import DummyOperator

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from google.cloud import storage


from urllib.request import urlopen
import requests
import re
import os
import time
import smtplib

DAG_ID = "CentenePipeLineFINAL_DAG"

args = {
        "start_date": days_ago(1),
        "schedule_interval": "@once",
        "retries": 2,
        "retry_delay": timedelta(seconds=60)
        }

dag = DAG(DAG_ID, default_args=args, dagrun_timeout=timedelta(minutes=200))

json_links = []
file_names = []

r = requests.get("https://www.centene.com/price-transparency-files.html")
links = re.findall(r"(/content/dam/centene/Centene%20Corporate/json/DOCUMENT/(.*?\.json))", str(r.content))
links.pop()
for link in links:
    json_links.append("https://www.centene.com"+ link[0])
    file_names.append(link[1][:-5] + ".txt")

internal_links = []
internal_names = []
for link in json_links:
    req = requests.get(link).json()
    in_network_links = re.findall(r"http://[^}]*in-network.json", str(req))
    for in_network_link in in_network_links:
        internal_links.append(in_network_link)
        internal_names.append(in_network_link[73:-5] + ".txt")


BUCKET_NAME="centene_all"
PROJECT_ID="healthcarepci"
MY_PASS="mbgkbkuyflovqvcb"

getting_file_ops = []
move_file_to_gcs_ops = []
bucket_to_bq_ops = []
execute_query_save_ops = []

for i in range(len(json_links)):
    @task(task_id=f"get_file_to_local_system_{i}",dag=dag)
    def get_file_to_local_system_func(link,filename):
        storage_client = storage.Client()
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        if(blob.exists() == False):
            os.system(f"wget -O {filename} \"{link}\"")
            blob.upload_from_filename(filename)
    
    get_file_to_local_system = get_file_to_local_system_func(json_links[i],file_names[i])

    getting_file_ops.append(get_file_to_local_system)

    #GCS to BQ
    DATASET_NAME="centene_temp"
    TABLE_NAME=file_names[i][0:-4]

    bucket_to_bq = GCSToBigQueryOperator(
        task_id=f"bucket_to_bq_{i}",
        bucket="centene_all",
        source_objects=[file_names[i]],
        source_format="NEWLINE_DELIMITED_JSON",
        destination_project_dataset_table=f"{PROJECT_ID}.{DATASET_NAME}.{TABLE_NAME}",
        write_disposition="WRITE_TRUNCATE",
        create_disposition="CREATE_IF_NEEDED",
        schema_fields=[
            {'name':'reporting_entity_name', 'type' : 'STRING', 'mode':'NULLABLE'},
            {'name':'reporting_entity_type', 'type' : 'STRING', 'mode':'NULLABLE'},
            {'name':'reporting_structure', 'type' : 'RECORD', 'mode':'REPEATED', 'fields' : [
                {'name':'allowed_amount_file', 'type' : 'RECORD', 'mode':'NULLABLE', 'fields' : [
                    {'name':'location', 'type' : 'STRING', 'mode':'NULLABLE'},
                    {'name':'description', 'type' : 'STRING', 'mode':'NULLABLE'}
                ]},
                {'name':'in_network_files', 'type' : 'RECORD', 'mode':'REPEATED', 'fields' : [
                    {'name':'location', 'type' : 'STRING', 'mode':'NULLABLE'},
                    {'name':'description', 'type' : 'STRING', 'mode':'NULLABLE'}
                ]},
                {'name':'reporting_plans', 'type' : 'RECORD', 'mode':'REPEATED', 'fields' : [
                    {'name':'plan_market_type', 'type' : 'STRING', 'mode':'NULLABLE'},
                    {'name':'plan_id_type', 'type' : 'STRING', 'mode':'NULLABLE'},
                    {'name':'plan_id', 'type' : 'STRING', 'mode':'NULLABLE'},
                    {'name':'plan_name', 'type' : 'STRING', 'mode':'NULLABLE'}
                ]}
            ]}
        ],
        dag=dag
    )

    bucket_to_bq_ops.append(bucket_to_bq)


    #Flatten index to final index table
    INDEX_TABLE_QUERY = f"SELECT p.plan_id, p.plan_id_type, p.plan_market_type, p.plan_name, r.allowed_amount_file.location as amount_file_location, i.location as rate_file_location, index_file_location FROM `{PROJECT_ID}.{DATASET_NAME}.{TABLE_NAME}` cross join unnest(reporting_structure) as r cross join unnest(reporting_plans) as p cross join unnest(in_network_files) as i cross join unnest(['{json_links[i]}']) as index_file_location"
    FINAL_DATASET_NAME = "centene_final"
    FINAL_TABLE_NAME = "final_centene_index"
    
    execute_query_save = BigQueryInsertJobOperator(
        task_id=f"execute_query_save_{i}",
        configuration={
            "query": {
                "query": INDEX_TABLE_QUERY,
                "destinationTable": {
                    "projectId": PROJECT_ID,
                    "datasetId": FINAL_DATASET_NAME,
                    "tableId": FINAL_TABLE_NAME
                },
                "useLegacySql": False,
                "writeDisposition": "WRITE_APPEND",
                "createDisposition" : "CREATE_IF_NEEDED",
                "allowLargeResults": True
            }
        },
        dag=dag
    )

    execute_query_save_ops.append(execute_query_save)

    get_file_to_local_system >> bucket_to_bq >> execute_query_save

dummy = DummyOperator(
    task_id = "dummy_operator",
    dag=dag
    )

for i in range(len(json_links)):
    execute_query_save_ops[i] >> dummy



#Rate files processing

getting_internal_file_ops = []
move_internal_file_to_gcs_ops = []
clean_up_internal_file_ops = []
pyspark_ops = []
sleep_for_internal_file_ops = []


for i in range(len(internal_links)):
    

    @task(task_id=f"get_internal_file_to_local_system_{i}",dag=dag)
    def get_internal_file_to_local_system_func(link,filename):
        # txtData = urlopen(link).read()
        # with open(filename,'wb') as f:
        #     f.write(txtData)
        # time.sleep(5)
        storage_client = storage.Client()
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        if(blob.exists() == False):
            # try:
            os.system(f"wget -O {filename} \"{link}\"")
            blob.upload_from_filename(filename)
            # except:
            #     logging.error("error")
        # dag_folder = conf.get('core','DAGS_FOLDER')
        # dagbag = DagBag(dag_folder)
        # check_dag = dagbag.get_dag(DAG_ID)
        # my_task = check_dag.get_task("get_internal_file_to_local_system_1")
        # ti = TaskInstance(my_task,execution_date=datetime.UtcNow())
        # logging.info(ti)
    
    get_internal_file_to_local_system = get_internal_file_to_local_system_func(internal_links[i],internal_names[i])

    getting_internal_file_ops.append(get_internal_file_to_local_system)

    # #sleep for some time
    # @task(task_id=f"sleep_for_internal_file_{i}",dag=dag)
    # def sleep_for_internal_file_func():
    #     time.sleep(600)
    
    # sleep_for_internal_file = sleep_for_internal_file_func()

    # sleep_for_internal_file_ops.append(sleep_for_internal_file)

    #GCS to BQ
    REGION="us-central1"
    PYSPARK_JOB={
        "reference": {"project_id": PROJECT_ID},
        "placement": {"cluster_name": "myclusty"},
        "pyspark_job": {
            "main_python_file_uri": f"gs://{BUCKET_NAME}/centeneScriptForRate.py",
            "args": [f"gs://{BUCKET_NAME}/{internal_names[i]}", f"{internal_links[i]}"],
            "jar_file_uris":["gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar"]
            }
    }
    pyspark_task = DataprocSubmitJobOperator(
        task_id=f"pyspark_task_{i}",
        job=PYSPARK_JOB,
        region=REGION,
        project_id=PROJECT_ID,
        trigger_rule='all_done',
        dag=dag
    )

    pyspark_ops.append(pyspark_task)

    # get_internal_file_to_local_system >> check_if_internal_file_present >> move_internal_file_to_gcs >> clean_up_for_internal >> sleep1_internal >> bucket_to_bq_internal >> sleep2_internal >> execute_query_save_internal
    # get_internal_file_to_local_system >> check_if_internal_file_present >> move_internal_file_to_gcs >> clean_up_for_internal >> pyspark_task
    # get_internal_file_to_local_system >> move_internal_file_to_gcs >> clean_up_for_internal >> pyspark_task

@task(task_id="print_metadata", trigger_rule="all_done", dag=dag)
def print_metadata_func():
    dag_folder = conf.get('core','DAGS_FOLDER')
    dagbag = DagBag(dag_folder)
    check_dag = dagbag.get_dag(DAG_ID)
    execution_date = check_dag.latest_execution_date
    # logging.info(execution_date)
    processed_rate_files = 0
    processed_index_files = 0
    total_index_file_size_processed = 0
    total_rate_file_size_processed = 0
    storage_client = storage.Client()
    bucket = storage_client.bucket(BUCKET_NAME)
    for i in range(len(json_links)):
        task_item = TaskInstance(execute_query_save_ops[i], execution_date)
        if(task_item.current_state() == "success"):
            processed_index_files += 1
            current_file_size = bucket.get_blob(file_names[i]).size/1048576
            total_index_file_size_processed += current_file_size
            logging.info(f"File status : Success")
            logging.info(f"Name of the file : {file_names[i]}")
            logging.info(f"Size of the file processed: {current_file_size}")
        else:
            logging.info(f"File status : Failed")
            logging.info(f"Name of the file : {file_names[i]}")

    for i in range(len(internal_links)):
        task_item = TaskInstance(pyspark_ops[i], execution_date)
        if(task_item.current_state() == "success"):
            processed_rate_files += 1
            total_rate_file_size_processed += bucket.get_blob(internal_names[i]).size/1048576
            logging.info(f"File status : Success")
            logging.info(f"Name of the file : {internal_names[i]}")
            logging.info(f"Size of the file processed: {current_file_size}")
        else:
            logging.info(f"File status : Failed")
            logging.info(f"Name of the file : {internal_names[i]}")

    
    logging.info(f"Total Index files processed successfully : {processed_index_files}")
    logging.info(f"Total Size of the Index files processed : {total_index_file_size_processed}")

    logging.info(f"Total Rate files processed successfully : {processed_rate_files}")
    logging.info(f"Total Size of the Rate files processed : {total_rate_file_size_processed}")

    dag_url = conf.get('webserver','base_url') + f"/dags/{DAG_ID}/graph"

    server = smtplib.SMTP('smtp.gmail.com',587)
    server.starttls()
    server.ehlo()
    server.login('sahuaman321@gmail.com', MY_PASS)

    msg = MIMEMultipart('alternative')
    msg['Subject'] = "Pipeline Report"
    msg['From'] = 'sahuaman321@gmail.com'
    recipients = ['aman.sahu@brillio.com', 'sarthak.mishra@brillio.com', 'alyana.vandana@brillio.com', 'lokesh.kadi@brillio.com']
    msg['To'] = ", ".join(recipients)
    text = "Hi!\nCentene Pipeline has completed its execution. Here is the report : \n"
    html = f"""
        <html>
        <head></head>
        <body>
            <p>Hi!<br>
            Centene Pipeline has completed its execution. Here is the report : <br>
            </p>
            <table border=1>
                <tr style="text-align:center">
                    <th>Number of SUCCESSFULLY processed Index files</th>
                    <th>Total size of the Index files processed</th>
                    <th>Number of FAILED Index files</th>
                    <th>Number of Successfully processed Rate files</th>
                    <th>Total size of the Rate files processed</th>
                    <th>Number of FAILED Rate files</th>
                </tr>
                <tr style="text-align:center">
                    <td>{processed_index_files}</td>
                    <td>{total_index_file_size_processed}mb</td>
                    <td>{len(json_links) - processed_index_files}</td>
                    <td>{processed_rate_files}</td>
                    <td>{total_rate_file_size_processed}mb</td>
                    <td>{len(internal_links) - processed_rate_files}</td>
                </tr>
            </table>
            <br>
            <p>For further information, Go to the <a href="{dag_url}">Pipeline</a></p>
        </body>
        </html>
    """
    part1 = MIMEText(text, 'plain')
    part2 = MIMEText(html, 'html')

    msg.attach(part1)
    msg.attach(part2)
    
    server.sendmail('sahuaman321@gmail.com', recipients, msg.as_string())

    if(processed_index_files != len(json_links) or processed_rate_files != len(internal_links)):
        critical_msg = MIMEMultipart('alternative')
        critical_msg['Subject'] = "(Urgent!) Centene Pipeline Tasks Failed"
        critical_msg['From'] = 'sahuaman321@gmail.com'
        recipients = ['aman.sahu@brillio.com', 'sarthak.mishra@brillio.com', 'alyana.vandana@brillio.com', 'lokesh.kadi@brillio.com']
        critical_msg['To'] = ", ".join(recipients)
        text = "Hi!\ Tasks have failed in Centene Pipeline.\n"
        html = f"""
            <html>
            <head></head>
            <body>
                <p>This is a high priority mail to notify that some tasks might have failed in the Centene Pipeline.</p>
                <br>
                <p>For further information, Go to the <h4><a href="{dag_url}">Pipeline</a></h4></p>
            </body>
            </html>
        """
        part1 = MIMEText(text, 'plain')
        part2 = MIMEText(html, 'html')

        critical_msg.attach(part1)
        critical_msg.attach(part2)
        
        server.sendmail('sahuaman321@gmail.com', recipients, critical_msg.as_string())
    
    server.quit()

print_metadata = print_metadata_func()


for i in range(len(internal_links)):
    dummy >> getting_internal_file_ops[i] >> pyspark_ops[i]
    if(i != len(internal_links) - 1):
        # pyspark_ops[i] >> getting_internal_file_ops[i+1]
        pyspark_ops[i] >> pyspark_ops[i+1]
    else:
        pyspark_ops[i] >> print_metadata