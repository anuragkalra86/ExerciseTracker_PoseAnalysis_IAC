output "sqs_queue_arn" {
  description = "ARN of the main SQS queue"
  value       = aws_sqs_queue.pose_analysis_queue.arn
}

output "sqs_queue_url" {
  description = "URL of the main SQS queue"
  value       = aws_sqs_queue.pose_analysis_queue.id
}

output "sqs_dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = aws_sqs_queue.pose_analysis_dlq.arn
}

output "sqs_dlq_url" {
  description = "URL of the dead letter queue"
  value       = aws_sqs_queue.pose_analysis_dlq.id
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.pose_analysis.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.pose_analysis.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "sns_subscription_arn" {
  description = "ARN of the SNS subscription"
  value       = aws_sns_topic_subscription.video_upload_to_pose_analysis.arn
}

output "sns_topic_arn" {
  description = "ARN of the existing SNS topic"
  value       = data.aws_sns_topic.video_upload_notifications.arn
}

output "secret_arn" {
  description = "ARN pattern of the AWS secret accessible by Lambda"
  value       = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.secret_name}-*"
} 