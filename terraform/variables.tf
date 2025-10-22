# AWS Region where resources will be created
variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-1"
}

# Environment name (e.g., production, staging, development)
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Application name
variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "kbju-api"
}

# ECR Repository name
variable "ecr_repository_name" {
  description = "Name of the ECR repository for Docker images"
  type        = string
  default     = "kbju-app"
}
