# App Runner service URL - use this to access your application
output "apprunner_service_url" {
  description = "URL of the App Runner service"
  value       = aws_apprunner_service.app.service_url
}

# ECR repository URL - use this for docker push
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

# App Runner service ID
output "apprunner_service_id" {
  description = "ID of the App Runner service"
  value       = aws_apprunner_service.app.service_id
}

# App Runner service ARN
output "apprunner_service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.app.arn
}

# ECR repository ARN
output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

# GitHub Actions IAM user
output "github_actions_iam_user" {
  description = "IAM user name for GitHub Actions"
  value       = aws_iam_user.github_actions.name
}

# GitHub Actions IAM user ARN
output "github_actions_iam_user_arn" {
  description = "ARN of the IAM user for GitHub Actions"
  value       = aws_iam_user.github_actions.arn
}

# GitHub repository full name
output "github_repository_full_name" {
  description = "Full name of the GitHub repository"
  value       = github_repository.app.full_name
}

# GitHub repository URL
output "github_repository_url" {
  description = "URL of the GitHub repository"
  value       = github_repository.app.html_url
}

# DynamoDB table name
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for meal data"
  value       = aws_dynamodb_table.kbju_meals.name
}

# DynamoDB table ARN
output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.kbju_meals.arn
}
