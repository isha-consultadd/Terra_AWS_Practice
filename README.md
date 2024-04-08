# Big Data Ingestion Pipeline
This repository contains the code and configuration for setting up a big data ingestion pipeline on AWS using Terraform. The pipeline is designed to efficiently ingest, transform, and analyze large volumes of data stored in S3 buckets.

## Overview
The pipeline consists of several components working together to achieve the following objectives:

- **Input Data Ingestion: Data is uploaded to an S3 bucket, which triggers an event that kicks off the ingestion pipeline.

Event Trigger: An EventBridge rule captures S3 Put events and triggers a Lambda function.

Data Processing with Lambda: The Lambda function is triggered by the S3 Put event and initiates the Glue job for data transformation.

Transformation with Glue: The Glue job converts CSV data into Parquet format, optimizing it for analysis.

Output Storage: The transformed data is stored in an output S3 bucket for further analysis and querying.

Analysis with Athena: The transformed data can be analyzed using Amazon Athena by querying the Parquet data stored in the output S3 bucket.

