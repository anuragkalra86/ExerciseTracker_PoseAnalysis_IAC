#!/bin/bash

# Exercise Tracker Pose Analysis Infrastructure Deployment Script
# This script automates the deployment of the Terraform infrastructure

set -e  # Exit on any error

echo "🚀 Exercise Tracker Pose Analysis Infrastructure Deployment"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
print_status "Verifying AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure'."
    exit 1
fi

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-west-2")

print_status "AWS Account ID: $ACCOUNT_ID"
print_status "AWS Region: $AWS_REGION"

# Check if SNS topic exists
print_status "Checking if SNS topic exists..."
SNS_TOPIC="exercise-tracker-dev-video-upload-notifications"
if aws sns get-topic-attributes --topic-arn "arn:aws:sns:$AWS_REGION:$ACCOUNT_ID:$SNS_TOPIC" &> /dev/null; then
    print_status "SNS topic '$SNS_TOPIC' found."
else
    print_warning "SNS topic '$SNS_TOPIC' not found. Please ensure it exists before continuing."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
fi

# Check if S3 bucket exists
print_status "Checking if S3 bucket exists..."
S3_BUCKET="exercise-tracker-fa20651d-064c-4a95-8540-edfe2af691cd"
if aws s3api head-bucket --bucket "$S3_BUCKET" &> /dev/null; then
    print_status "S3 bucket '$S3_BUCKET' found."
else
    print_warning "S3 bucket '$S3_BUCKET' not found or not accessible."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
fi

# Check if AWS secret exists
print_status "Checking if AWS secret exists..."
SECRET_NAME="exercise-tracker/dev/aurora/connection-string"
if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" &> /dev/null; then
    print_status "AWS secret '$SECRET_NAME' found."
else
    print_warning "AWS secret '$SECRET_NAME' not found or not accessible."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan deployment
print_status "Planning deployment..."
terraform plan -out=tfplan

# Confirm deployment
echo
print_warning "Ready to deploy the following resources:"
echo "  • SQS Queue: exercise-tracker-dev-pose-analysis (1-hour visibility timeout)"
echo "  • SQS Dead Letter Queue: exercise-tracker-dev-pose-analysis-dlq"
echo "  • Lambda Function: exercise-tracker-dev-pose-analysis (10-minute timeout)"
echo "  • SNS Subscription: $SNS_TOPIC → SQS Queue"
echo "  • IAM Role and Policy for Lambda"
echo

read -p "Proceed with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Deployment cancelled."
    rm -f tfplan
    exit 1
fi

# Apply Terraform
print_status "Deploying infrastructure..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Display outputs
print_status "Deployment completed successfully!"
echo
print_status "Resource outputs:"
terraform output

# Display next steps
echo
print_status "Next steps:"
echo "1. Update the Lambda function code with your pose analysis logic"
echo "2. Test the integration by sending a message to the SNS topic"
echo "3. Monitor CloudWatch Logs for Lambda execution"
echo "4. Check SQS dead letter queue for any failed messages"
echo
print_status "To monitor Lambda logs:"
echo "aws logs tail /aws/lambda/exercise-tracker-dev-pose-analysis --follow"
echo
print_status "To check SQS queue:"
echo "aws sqs get-queue-attributes --queue-url \$(terraform output -raw sqs_queue_url) --attribute-names All"
echo
print_status "Deployment complete! 🎉" 