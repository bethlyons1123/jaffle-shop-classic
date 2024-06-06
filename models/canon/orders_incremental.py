import snowflake.snowpark as snowpark
from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.functions import col, max as snowflake_max, coalesce, lit
from snowflake.snowpark.types import StructType, StructField, StringType, IntegerType, DateType
import pandas as pd
import numpy as np

def group_orders(orders_df): 
    grouped_df = orders_df.groupby('ORDER_DATE').agg(ORDER_COUNT=('ORDER_ID', 'count')).reset_index()
    grouped_df = grouped_df.rename(columns={'ORDER_DATE': 'DATE'})
    return grouped_df

def model(dbt, session):

    # Set the model configuration
 
    dbt.config(
        materialized='incremental',
        unique_key='DATE'
    )

    # Load the reference DataFrame
    source_df = dbt.ref('stg_orders')
    
    # Define the target table name
    target_table = "canon_dev.dbt_blyons.orders_incremental"

    # Get the max order date from the target table
    target_df = session.table(target_table)
    max_order_date = target_df.select(coalesce(snowflake_max(col("DATE")), lit('2000-01-01'))).collect()[0][0]
    
    # Filter the source DataFrame for new data 
    new_data = source_df.filter(col("ORDER_DATE") > max_order_date)

    if new_data.count() == 0:
        return session.create_dataframe([], schema=StructType([
            StructField("ORDER_COUNT", IntegerType()),
            StructField("DATE", DateType())
        ]))

    pandas_df = new_data.to_pandas()

    result_df = group_orders(pandas_df)

    # Convert the resulting DataFrame back to a Snowflake DataFrame and return it
    result_snowflake_df = session.create_dataframe(result_df)
    return result_snowflake_df