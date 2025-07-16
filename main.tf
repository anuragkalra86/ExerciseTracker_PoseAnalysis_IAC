terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for existing SNS topic
data "aws_sns_topic" "video_upload_notifications" {
  name = var.sns_topic_name
}

# Dead Letter Queue
resource "aws_sqs_queue" "pose_analysis_dlq" {
  name                      = "${var.sqs_queue_name}-dlq"
  message_retention_seconds = 1209600 # 14 days (maximum)
  
  tags = {
    Name = "${var.sqs_queue_name}-dlq"
    Type = "DeadLetterQueue"
  }
}

# Main SQS Queue
resource "aws_sqs_queue" "pose_analysis_queue" {
  name                      = var.sqs_queue_name
  visibility_timeout_seconds = var.sqs_visibility_timeout
  message_retention_seconds = var.sqs_message_retention
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.pose_analysis_dlq.arn
    maxReceiveCount     = var.sqs_max_receives
  })
  
  tags = {
    Name = var.sqs_queue_name
    Type = "MainQueue"
  }
}

# SQS Queue Policy to allow SNS to send messages
resource "aws_sqs_queue_policy" "pose_analysis_queue_policy" {
  queue_url = aws_sqs_queue.pose_analysis_queue.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.pose_analysis_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = data.aws_sns_topic.video_upload_notifications.arn
          }
        }
      }
    ]
  })
}

# SNS subscription to SQS
resource "aws_sns_topic_subscription" "video_upload_to_pose_analysis" {
  topic_arn = data.aws_sns_topic.video_upload_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.pose_analysis_queue.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.lambda_function_name}-role"
  }
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.lambda_function_name}-policy"
  description = "Policy for pose analysis lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.pose_analysis_queue.arn,
          aws_sqs_queue.pose_analysis_dlq.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.secret_name}-*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function
resource "aws_lambda_function" "pose_analysis" {
  filename         = "lambda_function.zip"
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  # Create a dummy zip file for the lambda function
  depends_on = [data.archive_file.lambda_zip]
  
  tags = {
    Name = var.lambda_function_name
  }
}

# Create a dummy lambda function file and zip it
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<EOF
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to process pose analysis requests from SQS
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Initialize AWS clients
    secrets_client = boto3.client('secretsmanager')
    s3_client = boto3.client('s3')
    
    # Get database connection string from secrets
    try:
        secret_response = secrets_client.get_secret_value(
            SecretId='exercise-tracker/dev/aurora/connection-string'
        )
        connection_string = secret_response['SecretString']
        logger.info("Successfully retrieved database connection string")
    except Exception as e:
        logger.error(f"Error retrieving secret: {e}")
        raise
    
    # Process SQS messages
    for record in event['Records']:
        # Parse SQS message
        message_body = json.loads(record['body'])
        logger.info(f"Processing message: {message_body}")
        
        # TODO: Add your pose analysis logic here
        # - Parse SNS message from SQS
        # - Extract S3 object information
        # - Download video from S3
        # - Perform pose analysis
        # - Call external API endpoints
        # - Store results in database using connection_string
        
        # Example usage:
        # response = s3_client.get_object(Bucket='your-bucket', Key='your-key')
        # Use connection_string to connect to Aurora database
        
        logger.info("Message processed successfully")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully processed messages')
    }
EOF
    filename = "lambda_function.py"
  }
}

# Lambda event source mapping for SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.pose_analysis_queue.arn
  function_name    = aws_lambda_function.pose_analysis.arn
  batch_size       = 10
  enabled          = true
} 