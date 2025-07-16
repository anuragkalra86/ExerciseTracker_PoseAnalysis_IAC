# Exercise Tracker Pose Analysis Infrastructure

This Terraform configuration deploys AWS infrastructure for processing pose analysis requests from video uploads. The architecture includes SQS queues, Lambda functions, and SNS integration.

## Architecture Overview

```
SNS Topic (existing) → SQS Queue → Lambda Function
exercise-tracker-dev-video-upload-notifications → exercise-tracker-dev-pose-analysis → exercise-tracker-dev-pose-analysis
                                                      ↓
                                                   Dead Letter Queue
```

## Resources Created

### 1. SQS Queue (`exercise-tracker-dev-pose-analysis`)
- **Purpose**: Receives messages from SNS topic when videos are uploaded
- **Configuration**:
  - Visibility timeout: 1 hour (6x Lambda timeout)
  - Message retention: 1 day
  - Max receives before DLQ: 3 attempts
- **Dead Letter Queue**: `exercise-tracker-dev-pose-analysis-dlq`

### 2. Lambda Function (`exercise-tracker-dev-pose-analysis`)
- **Runtime**: Python 3.13
- **Memory**: 1024 MB
- **Timeout**: 10 minutes
- **Trigger**: SQS queue messages
- **Permissions**:
  - Read from SQS queues
  - Read objects from S3 bucket: `exercise-tracker-fa20651d-064c-4a95-8540-edfe2af691cd`
  - Read AWS secret: `exercise-tracker/dev/aurora/connection-string`
  - CloudWatch Logs access
  - Internet access for external API calls

### 3. SNS Subscription
- **Purpose**: Connects existing SNS topic to SQS queue
- **Protocol**: SQS
- **Source**: `exercise-tracker-dev-video-upload-notifications`

### 4. IAM Resources
- **Lambda Role**: Execution role for Lambda function
- **Lambda Policy**: Permissions for SQS, S3, and CloudWatch Logs access

## Prerequisites

1. **AWS CLI**: Configured with appropriate credentials
2. **Terraform**: Version >= 1.0
3. **Existing SNS Topic**: `exercise-tracker-dev-video-upload-notifications` must exist
4. **S3 Bucket**: `exercise-tracker-fa20651d-064c-4a95-8540-edfe2af691cd` must exist
5. **AWS Secret**: `exercise-tracker/dev/aurora/connection-string` must exist

## File Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example configuration
├── README.md                  # This file
└── lambda_function.zip        # Generated Lambda deployment package
```

## Deployment Guide

### Step 1: Prerequisites Check

Ensure you have the required tools installed:

```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform version
```

### Step 2: Configure Variables (Optional)

If you need to customize the configuration:

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration
nano terraform.tfvars
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Plan Deployment

```bash
terraform plan
```

Review the plan to ensure all resources will be created correctly.

### Step 5: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### Step 6: Verify Deployment

After successful deployment, verify the resources:

```bash
# List the outputs
terraform output

# Check SQS queue
aws sqs list-queues --region us-west-2

# Check Lambda function
aws lambda list-functions --region us-west-2 --query 'Functions[?FunctionName==`exercise-tracker-dev-pose-analysis`]'

# Check SNS subscriptions
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-west-2` | No |
| `sns_topic_name` | Existing SNS topic name | `exercise-tracker-dev-video-upload-notifications` | No |
| `sqs_queue_name` | SQS queue name | `exercise-tracker-dev-pose-analysis` | No |
| `sqs_visibility_timeout` | SQS visibility timeout (seconds) | `3600` | No |
| `sqs_message_retention` | Message retention period (seconds) | `86400` | No |
| `sqs_max_receives` | Max receives before DLQ | `3` | No |
| `lambda_function_name` | Lambda function name | `exercise-tracker-dev-pose-analysis` | No |
| `lambda_runtime` | Lambda runtime version | `python3.13` | No |
| `lambda_timeout` | Lambda timeout (seconds) | `600` | No |
| `lambda_memory_size` | Lambda memory size (MB) | `1024` | No |
| `s3_bucket_name` | S3 bucket for Lambda access | `exercise-tracker-fa20651d-064c-4a95-8540-edfe2af691cd` | No |
| `secret_name` | AWS secret for Lambda access | `exercise-tracker/dev/aurora/connection-string` | No |

## Outputs

After deployment, the following outputs are available:

- `sqs_queue_arn`: ARN of the main SQS queue
- `sqs_queue_url`: URL of the main SQS queue
- `sqs_dlq_arn`: ARN of the dead letter queue
- `sqs_dlq_url`: URL of the dead letter queue
- `lambda_function_arn`: ARN of the Lambda function
- `lambda_function_name`: Name of the Lambda function
- `lambda_role_arn`: ARN of the Lambda IAM role
- `sns_subscription_arn`: ARN of the SNS subscription
- `sns_topic_arn`: ARN of the existing SNS topic
- `secret_arn`: ARN pattern of the AWS secret accessible by Lambda

## Lambda Function Development

The Lambda function is deployed with a placeholder implementation. To update the function:

1. **Develop your pose analysis logic** in Python
2. **Update the Lambda function** either through:
   - AWS Console
   - AWS CLI
   - Terraform (by updating the `data.archive_file.lambda_zip` source)

### Lambda Function Template

The deployed Lambda function includes:

```python
import json
import boto3
import logging

def lambda_handler(event, context):
    # Initialize AWS clients
    secrets_client = boto3.client('secretsmanager')
    s3_client = boto3.client('s3')
    
    # Get database connection string from secrets
    secret_response = secrets_client.get_secret_value(
        SecretId='exercise-tracker/dev/aurora/connection-string'
    )
    connection_string = secret_response['SecretString']
    
    # Process SQS messages
    for record in event['Records']:
        message_body = json.loads(record['body'])
        # Add your pose analysis logic here
        # - Parse SNS message from SQS
        # - Extract S3 object information
        # - Download video from S3
        # - Perform pose analysis
        # - Call external API endpoints
        # - Store results in database using connection_string
```

## Monitoring and Troubleshooting

### CloudWatch Logs

Lambda logs are automatically sent to CloudWatch:

```bash
# View Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/exercise-tracker-dev-pose-analysis

# Tail logs
aws logs tail /aws/lambda/exercise-tracker-dev-pose-analysis --follow
```

### SQS Monitoring

```bash
# Check queue attributes
aws sqs get-queue-attributes --queue-url $(terraform output -raw sqs_queue_url) --attribute-names All

# Check dead letter queue
aws sqs get-queue-attributes --queue-url $(terraform output -raw sqs_dlq_url) --attribute-names All
```

### Common Issues

1. **SNS Topic Not Found**: Ensure the SNS topic exists in the specified region
2. **S3 Permissions**: Verify the S3 bucket exists and Lambda has read permissions
3. **Secret Not Found**: Ensure the AWS secret exists and Lambda has read permissions
4. **Lambda Timeout**: Adjust timeout if pose analysis takes longer than 10 minutes
5. **Memory Issues**: Increase Lambda memory if processing large videos
6. **SQS Visibility Timeout**: Must be greater than Lambda timeout (currently 6x Lambda timeout)

## Security Considerations

1. **IAM Permissions**: Follow principle of least privilege
2. **VPC Configuration**: Lambda uses default networking (internet access)
3. **Dead Letter Queue**: Monitor for failed messages
4. **CloudWatch Logs**: Contains sensitive information, configure retention appropriately

## Cost Optimization

1. **Lambda Memory**: Adjust based on actual usage
2. **SQS Retention**: Configured for 1 day to minimize costs
3. **CloudWatch Logs**: Set appropriate retention periods
4. **Dead Letter Queue**: Monitor and clean up failed messages

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This will not delete the existing SNS topic or S3 bucket as they're not managed by this Terraform configuration.

## Support

For issues or questions:

1. Check CloudWatch Logs for Lambda errors
2. Verify SQS queue messages and dead letter queue
3. Review Terraform state for resource configuration
4. Check AWS service limits and quotas

## Next Steps

1. **Implement pose analysis logic** in the Lambda function
2. **Set up monitoring** and alerting for failed messages
3. **Configure scaling** based on expected message volume
4. **Add error handling** and retry logic in Lambda function
5. **Set up CI/CD pipeline** for Lambda function updates 