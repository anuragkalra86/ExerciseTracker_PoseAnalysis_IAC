#!/bin/bash

# Exercise Tracker Pose Analysis Infrastructure Cleanup Script
# This script destroys the Terraform infrastructure

set -e  # Exit on any error

echo "🧹 Exercise Tracker Pose Analysis Infrastructure Cleanup"
echo "======================================================"

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

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    print_warning "No terraform.tfstate file found. Nothing to destroy."
    exit 0
fi

# Show current resources
print_status "Current resources that will be destroyed:"
terraform show -json | jq -r '.values.root_module.resources[]? | select(.type != "data") | "\(.type).\(.name)"' 2>/dev/null || terraform show

echo
print_warning "⚠️  DESTRUCTIVE OPERATION ⚠️"
print_warning "This will permanently destroy the following resources:"
echo "  • SQS Queue: exercise-tracker-dev-pose-analysis (1-hour visibility timeout)"
echo "  • SQS Dead Letter Queue: exercise-tracker-dev-pose-analysis-dlq"
echo "  • Lambda Function: exercise-tracker-dev-pose-analysis (10-minute timeout)"
echo "  • SNS Subscription to SQS Queue"
echo "  • IAM Role and Policy for Lambda"
echo
print_warning "Note: This will NOT destroy the existing SNS topic or S3 bucket."
echo

read -p "Are you sure you want to destroy these resources? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Cleanup cancelled."
    exit 1
fi

# Plan destruction
print_status "Planning destruction..."
terraform plan -destroy -out=destroy.tfplan

# Confirm destruction
echo
read -p "Proceed with destruction? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Cleanup cancelled."
    rm -f destroy.tfplan
    exit 1
fi

# Destroy infrastructure
print_status "Destroying infrastructure..."
terraform apply destroy.tfplan

# Clean up plan file
rm -f destroy.tfplan

# Clean up generated files
print_status "Cleaning up generated files..."
rm -f lambda_function.zip
rm -f terraform.tfstate.backup

print_status "Cleanup completed successfully! 🧹"
echo
print_status "All resources have been destroyed."
print_status "The following files have been preserved:"
echo "  • main.tf"
echo "  • variables.tf"
echo "  • outputs.tf"
echo "  • terraform.tfvars (if exists)"
echo "  • README.md"
echo
print_status "To redeploy, run: ./deploy.sh" 