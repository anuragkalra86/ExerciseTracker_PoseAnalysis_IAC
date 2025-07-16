variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "sns_topic_name" {
  description = "Name of the existing SNS topic"
  type        = string
  default     = "exercise-tracker-dev-video-upload-notifications"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "exercise-tracker-dev-pose-analysis"
}

variable "sqs_visibility_timeout" {
  description = "Visibility timeout for SQS queue in seconds"
  type        = number
  default     = 3600  # 1 hour (6 times the Lambda timeout of 600 seconds)
}

variable "sqs_message_retention" {
  description = "Message retention period for SQS queue in seconds"
  type        = number
  default     = 86400 # 1 day
}

variable "sqs_max_receives" {
  description = "Maximum number of receives before message goes to DLQ"
  type        = number
  default     = 3
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "exercise-tracker-dev-pose-analysis"
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 600 # 10 minutes
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 1024
}

variable "s3_bucket_name" {
  description = "S3 bucket name that Lambda needs access to"
  type        = string
  default     = "exercise-tracker-fa20651d-064c-4a95-8540-edfe2af691cd"
}

variable "secret_name" {
  description = "AWS Secrets Manager secret name that Lambda needs access to"
  type        = string
  default     = "exercise-tracker/dev/aurora/connection-string"
} 