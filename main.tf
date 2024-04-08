provider "aws" {
  region     = "ap-south-1"

}


resource "aws_s3_bucket" "my_bucket" {
  bucket = "inputsourcebucket"              

  tags = {
    Name = "InputSourceBucket"                      
  }
}


resource "aws_s3_object" "example_object" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "employees.csv"             
  source = "/Users/ishajoshi/Desktop/big-data-pipeline/employees.csv"      
}


resource "aws_s3_bucket" "output_bucket" {
  bucket = "outputparquetbucket"

  tags = {
    Name = "OutputParquetBucket"
  }
}

resource "aws_s3_bucket" "script_bucket" {
  bucket = "scriptbucketishaa"
}


resource "aws_s3_bucket_object" "script_file" {
  bucket = aws_s3_bucket.script_bucket.bucket
  key    = "script.py"
  source = "/Users/ishajoshi/Desktop/big-data-pipeline/glue/script.py"
}

resource "aws_iam_role" "glue_crawler_role" {
  name               = "GlueCrawlerRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "glue_crawler_policy" {
  name        = "GlueCrawlerPolicy"
  description = "Policy for Glue crawler role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:*",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListAllMyBuckets",
        "s3:GetBucketAcl",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeRouteTables",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcAttribute",
        "iam:ListRolePolicies",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:CreateBucket",
      "Resource": "arn:aws:s3:::aws-glue-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::aws-glue-*/*",
        "arn:aws:s3:::*/*aws-glue-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": [
        "arn:aws:s3:::crawler-public*",
        "arn:aws:s3:::aws-glue-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*:/aws-glue/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Condition": {
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "aws-glue-service-resource"
          ]
        }
      },
      "Resource": [
        "arn:aws:ec2:*:*:network-interface/*",
        "arn:aws:ec2:*:*:security-group/*",
        "arn:aws:ec2:*:*:instance/*"
      ]
    }
  ]
}
EOF
}

     



resource "aws_iam_role_policy_attachment" "glue_crawler_policy_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_policy.arn
}

resource "aws_glue_crawler" "s3_crawler" {
  name          = "S3Crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = "sampledb"
  table_prefix  = "s3_"  # Add a prefix for the table name if needed

  s3_target {
    path = "s3://${aws_s3_bucket.my_bucket.bucket}/"
  }

  configuration = <<EOF
{
  "Version": 1.0,
  "Grouping": {
    "TableGroupingPolicy": "CombineCompatibleSchemas"
  },
  "CrawlerOutput": {
    "Partitions": {
      "AddOrUpdateBehavior": "InheritFromTable"
    }
  }
}
EOF
}

resource "aws_glue_catalog_database" "example" {
  name = "sampledb"
}

resource "aws_glue_catalog_table" "employee_table" {
  database_name = "sampledb"
  name          = "employee_table"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    "classification" = "csv"
  }
  storage_descriptor {
    columns {
      name    = "employee_id"
      type    = "bigint"
      comment = ""
    }
    columns {
      name    = "first_name"
      type    = "string"
      comment = ""
    }
    columns {
      name    = "last_name"
      type    = "string"
      comment = ""
    }
    columns {
      name    = "email"
      type    = "string"
      comment = ""
    }
    location = "s3://${aws_s3_bucket.my_bucket.bucket}/"
    input_format = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name                  = "employee_serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim" = ","
      }
    }
  }
}


resource "aws_glue_job" "example_job" {
  name          = "sample-glue-job"
  role_arn      = aws_iam_role.glue_crawler_role.arn
  command {
    name        = "glueetl"
    script_location = "s3://${aws_s3_bucket.script_bucket.bucket}/script.py" 
    python_version  = "3"
  }
  
  default_arguments = {
    "--JOB_NAME" = "sample-glue-job"
  }
}
