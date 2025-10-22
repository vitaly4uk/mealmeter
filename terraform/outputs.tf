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
