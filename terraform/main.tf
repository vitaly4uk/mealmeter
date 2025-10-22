terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure GitHub Provider
# Requires GITHUB_TOKEN environment variable
provider "github" {
  owner = var.github_owner
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.ecr_repository_name
    Environment = var.environment
    Application = var.app_name
  }
}

# ECR Lifecycle Policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# IAM Role for App Runner service
resource "aws_iam_role" "apprunner_service_role" {
  name = "${var.app_name}-apprunner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-apprunner-service-role"
    Environment = var.environment
  }
}

# Attach ECR access policy to App Runner role
resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# IAM Role for App Runner instance (for DynamoDB access)
resource "aws_iam_role" "apprunner_instance_role" {
  name = "${var.app_name}-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-apprunner-instance-role"
    Environment = var.environment
  }
}

# IAM Policy for DynamoDB access
resource "aws_iam_role_policy" "apprunner_dynamodb_access" {
  name = "${var.app_name}-dynamodb-access"
  role = aws_iam_role.apprunner_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DynamoDBAccess"
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = aws_dynamodb_table.kbju_meals.arn
    }]
  })
}

# App Runner Service
resource "aws_apprunner_service" "app" {
  service_name = var.app_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_service_role.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8000"

        runtime_environment_variables = {
          ENVIRONMENT      = var.environment
          AWS_REGION       = var.aws_region
          DYNAMODB_TABLE   = aws_dynamodb_table.kbju_meals.name
        }
      }
    }

    auto_deployments_enabled = true
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  instance_configuration {
    cpu               = "0.25 vCPU"
    memory            = "0.5 GB"
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  tags = {
    Name        = var.app_name
    Environment = var.environment
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "${var.app_name}-github-actions"

  tags = {
    Name        = "${var.app_name}-github-actions"
    Environment = var.environment
    Purpose     = "GitHub Actions CI/CD"
  }
}

# IAM Policy for GitHub Actions - minimal permissions
resource "aws_iam_user_policy" "github_actions" {
  name = "${var.app_name}-github-actions-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushImage"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Sid    = "S3FrontendAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })
}

# Generate access key for GitHub Actions IAM user
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# GitHub Repository
resource "github_repository" "app" {
  name        = var.github_repository
  description = "KBJU API - Meal tracking application deployed on AWS App Runner"
  visibility  = "public"

  has_issues   = true
  has_projects = false
  has_wiki     = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true

  vulnerability_alerts = true

  topics = [
    "fastapi",
    "python",
    "aws",
    "app-runner",
    "terraform",
    "github-actions",
    "docker",
    "uv"
  ]
}

# GitHub Actions Secret: AWS Access Key ID (from IAM user)
resource "github_actions_secret" "aws_access_key_id" {
  repository      = github_repository.app.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.github_actions.id
}

# GitHub Actions Secret: AWS Secret Access Key (from IAM user)
resource "github_actions_secret" "aws_secret_access_key" {
  repository      = github_repository.app.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.github_actions.secret
}

# GitHub Actions Variable: AWS Region
resource "github_actions_variable" "aws_region" {
  repository    = github_repository.app.name
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

# GitHub Actions Variable: ECR Repository
resource "github_actions_variable" "ecr_repository" {
  repository    = github_repository.app.name
  variable_name = "ECR_REPOSITORY"
  value         = var.ecr_repository_name
}

# GitHub Actions Variable: App Runner Service Name
resource "github_actions_variable" "app_runner_service" {
  repository    = github_repository.app.name
  variable_name = "APP_RUNNER_SERVICE"
  value         = var.app_name
}

# GitHub Actions Secret: API URL (from App Runner)
resource "github_actions_secret" "api_url" {
  repository      = github_repository.app.name
  secret_name     = "API_URL"
  plaintext_value = "https://${aws_apprunner_service.app.service_url}"
}

# GitHub Actions Secret: CloudFront Distribution ID
resource "github_actions_secret" "cloudfront_distribution_id" {
  repository      = github_repository.app.name
  secret_name     = "CLOUDFRONT_DISTRIBUTION_ID"
  plaintext_value = aws_cloudfront_distribution.frontend.id
}

# GitHub Actions Variable: S3 Bucket Name
resource "github_actions_variable" "s3_bucket_name" {
  repository    = github_repository.app.name
  variable_name = "S3_BUCKET_NAME"
  value         = aws_s3_bucket.frontend.id
}
