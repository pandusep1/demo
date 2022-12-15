from pyspark.sql import SparkSession
import sys

bucket_uri = sys.argv[1]
rate_file_location = sys.argv[2]

print(bucket_uri, rate_file_location)

spark = SparkSession.builder.appName('scriptForRate_amansahu').getOrCreate()

df = spark.read.option("inferSchema", "true").option("multiline","true").json(bucket_uri)
# df.show(20)

df.printSchema()

from pyspark.sql.types import *
from pyspark.sql.functions import *

def flatten(df):
  # compute Complex Fields (Lists and Structs) in Schema   
  complex_fields = dict([(field.name, field.dataType)
                            for field in df.schema.fields
                            if type(field.dataType) == ArrayType or  type(field.dataType) == StructType])
  while len(complex_fields)!=0:
    col_name=list(complex_fields.keys())[0]
    print ("Processing :"+col_name+" Type : "+str(type(complex_fields[col_name])))

  # if StructType then convert all sub element to columns.
  # i.e. flatten structs
    if (type(complex_fields[col_name]) == StructType):
      expanded = [col(col_name+'.'+k).alias(col_name+'_'+k) for k in [ n.name for n in  complex_fields[col_name]]]
      df=df.select("*", *expanded).drop(col_name)

  # if ArrayType then add the Array Elements as Rows using the explode function
  # i.e. explode Arrays
    elif (type(complex_fields[col_name]) == ArrayType):    
      df=df.withColumn(col_name,explode_outer(col_name))

  # recompute remaining Complex Fields in Schema       
    complex_fields = dict([(field.name, field.dataType)
                          for field in df.schema.fields
                          if type(field.dataType) == ArrayType or  type(field.dataType) == StructType])
  return df

df_flatten = flatten(df)

all_columns = []
required_columns = ['billing_code', 'billing_code_type', 'billing_code_type_version', 'description', 'name', 'negotiation_arrangement', 'billing_class', 'billing_code_modifiers', 'negotiated_rate', 'negotiated_type', 'service_codes', 'npis', 'tin_type', 'tin_value', 'rate_file_location']
all_columns = df_flatten.columns

final_list_of_columns = []

billing_code = "none"
billing_code_type = "none"
billing_code_type_version = "none"
description = "none"
name = "none"
billing_class= "none"
negotiated_rate = "none"
negotiated_type = "none"
service_codes = "none"
npi = "none"
negotiation_arrangement = "none"
tin_type = "none"
tin_value = "none"
billing_code_modifier = "none"

for i in range(len(all_columns)):
  string = all_columns[i]
  if ("in_network_billing_code" == string[-23:]):
    final_list_of_columns.append(string)
    billing_code = string   
    continue

  elif ("in_network_billing_code_type" == string[-28:]): 
    final_list_of_columns.append(string)
    billing_code_type = string      
    continue

  elif ("in_network_billing_code_type_version" == string[-36:]): 
    final_list_of_columns.append(string)
    billing_code_type_version = string    
    continue

  elif("in_network_description" == string[-22:]): 
    final_list_of_columns.append(string)
    description = string
    continue
        
  elif("in_network_name" == string[-15:]):  
    final_list_of_columns.append(string)
    name = string
    continue

  elif("billing_class" == string[-13:]):
    final_list_of_columns.append(string)
    billing_class = string
    continue

  elif("negotiated_rate" == string[-15:]):  
    final_list_of_columns.append(string)
    negotiated_rate = string
    continue

  elif("negotiated_type" == string[-15:]):
    final_list_of_columns.append(string)
    negotiated_type = string
    continue

  elif("service_code" == string[-12:]):  
    final_list_of_columns.append(string)
    service_codes = string
    continue

  elif("billing_code_modifier" == string[-21:]):
    final_list_of_columns.append(string)
    billing_code_modifier = string
    continue

  elif("tin_value" == string[-9:]):
    final_list_of_columns.append(string)
    tin_value = string
    continue

  elif("tin_type" == string[-8:]):
    final_list_of_columns.append(string)
    tin_type = string 
    continue

  elif("negotiation_arrangement" == string[-23:]):
    final_list_of_columns.append(string)
    negotiation_arrangement = string 
    continue

  elif("npi" == string[-3:]):
    final_list_of_columns.append(string)
    npi = string 
    continue

df_selected = df_flatten.select(*final_list_of_columns)

df_column = df_selected.withColumnRenamed(billing_code,"billing_code")\
                .withColumnRenamed(billing_code_type,"billing_code_type")\
                .withColumnRenamed(billing_code_type_version,"billing_code_type_version")\
                .withColumnRenamed(description,"description")\
                .withColumnRenamed(name,"name")\
                .withColumnRenamed(negotiation_arrangement,"negotiation_arrangement")\
                .withColumnRenamed(billing_class,"billing_class")\
                .withColumnRenamed(negotiated_rate,"negotiated_rate")\
                .withColumnRenamed(negotiated_type,"negotiated_type")\
                .withColumnRenamed(service_codes,"service_codes")\
                .withColumnRenamed(billing_code_modifier,"billing_code_modifiers")\
                .withColumnRenamed(tin_type,"tin_type")\
                .withColumnRenamed(tin_value,"tin_value")\
                .withColumnRenamed(npi,"npis")\
                .withColumn("rate_file_location", lit(rate_file_location))\

final_list_of_columns = df_column.columns
not_there_in_df = []
for item in required_columns :
  if item not in final_list_of_columns :
    not_there_in_df.append(item)
# print(not_there_in_df)

new_df = df_column

for item in not_there_in_df:
  new_df = new_df.withColumn(item, lit(None).cast(StringType()))

df_final =  new_df.select(col("billing_code"),
                          col("billing_code_type"),
                          col("billing_code_type_version"),
                          col("description"),
                          col("name"),
                          col("negotiation_arrangement"),
                          col("billing_class"),
                          col("negotiated_rate"),
                          col("negotiated_type"),
                          col("service_codes"),
                          col("billing_code_modifiers"),
                          col("tin_type"),
                          col("tin_value"),
                          col("npis"),
                          col("rate_file_location"))

df_final.printSchema()
df_final.show(20)

(df_final.write.format("bigquery")
  .option("temporaryGcsBucket","centene_all")
  .option("table","centene_final.final_centene_rate")
  .mode("append")
  .save())