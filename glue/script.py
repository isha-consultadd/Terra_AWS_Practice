import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node Amazon S3
#AmazonS3_node1712590443726 = glueContext.create_dynamic_frame.from_catalog(database="sampledb", table_name="employee_table", transformation_ctx="AmazonS3_node1712590443726")

# Script generated for node Select Fields
#SelectFields_node1712590461795 = SelectFields.apply(frame=AmazonS3_node1712590443726, paths=["employee_id", "first_name", "last_name", "email"], transformation_ctx="SelectFields_node1712590461795")

# Script generated for node Amazon S3
#AmazonS3_node1712590468935 = glueContext.write_dynamic_frame.from_options(frame=SelectFields_node1712590461795, connection_type="s3", format="glueparquet", connection_options={"path": "s3://outputparquetbucket", "partitionKeys": []}, format_options={"compression": "snappy"}, transformation_ctx="AmazonS3_node1712590468935")
employee_dynamic_frame = glueContext.create_dynamic_frame.from_catalog(database="sampledb", table_name="employee_table")

# Convert data types if needed (example: convert employee_id to string)
employee_dynamic_frame = ApplyMapping.apply(
    frame=employee_dynamic_frame,
    mappings=[
        ("first_name", "string", "first_name"),
        ("last_name", "string", "last_name"),
        ("email", "string", "email")
    ]
)

# Write dynamic frame to S3
glueContext.write_dynamic_frame.from_options(
    frame=employee_dynamic_frame,
    connection_type="s3",
    format="glueparquet",
    connection_options={"path": "s3://outputparquetbucket", "partitionKeys": []},
    format_options={"compression": "snappy"}
)

job.commit()


