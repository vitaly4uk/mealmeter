# Terraform Infrastructure for KBJU API

This directory contains Terraform configuration for deploying the KBJU API to AWS App Runner and configuring GitHub repository with Actions secrets.

## Architecture

The infrastructure includes:

**AWS Resources:**
- **ECR Repository**: Stores Docker images for the application
- **App Runner Service**: Runs the containerized FastAPI application
- **IAM Role**: Allows App Runner to pull images from ECR
- **Health Checks**: Monitors application health via `/health` endpoint

**GitHub Resources:**
- **Repository Configuration**: Manages repository settings and topics
- **Actions Secrets**: AWS credentials for CI/CD pipeline
- **Actions Variables**: AWS region and resource names

## Prerequisites

1. **Terraform**: Install from [terraform.io](https://www.terraform.io/downloads)
2. **AWS CLI**: Configure with credentials
   ```bash
   aws configure
   ```
3. **GitHub Token**: Create a personal access token with `repo` and `admin:repo_hook` scopes
   - Go to: https://github.com/settings/tokens/new
   - Select scopes: `repo`, `admin:repo_hook`, `delete_repo`
   - Generate token and save it securely
4. **Environment Variables**: Set GitHub token
   ```bash
   export GITHUB_TOKEN="your_github_token_here"
   ```

## Quick Start

### 1. Configure Terraform Variables

```bash
cd terraform

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

Configure your variables in `terraform.tfvars`:
```hcl
# AWS Configuration
aws_region          = "us-east-1"
environment         = "production"
app_name            = "kbju-api"
ecr_repository_name = "kbju-app"

# GitHub Configuration
github_owner      = "vitaly4uk"
github_repository = "mealmeter"

# Note: NO AWS credentials needed!
# Terraform automatically creates a dedicated IAM user
# with minimal permissions for GitHub Actions
```

### 2. Set GitHub Token

```bash
# Export GitHub personal access token
export GITHUB_TOKEN="ghp_YourGitHubTokenHere"
```

### 3. Initialize Terraform

```bash
terraform init
```

This downloads the AWS and GitHub providers and initializes the backend.

### 4. Review the Plan

```bash
terraform plan
```

This shows what resources will be created without making any changes.

### 5. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to create the resources.

**What will be created:**

**AWS Resources:**
- ECR repository for Docker images
- App Runner service (0.25 vCPU, 512 MB)
- IAM role for App Runner (ECR access)
- **IAM user for GitHub Actions** (with minimal ECR push permissions)
- IAM policy for GitHub Actions (scoped to ECR only)
- Access keys for GitHub Actions IAM user

**GitHub Resources:**
- Repository configuration and settings
- Actions secrets (IAM user credentials - auto-generated)
- Actions variables (AWS region, ECR repo, service name)

### 6. Get Outputs

After successful deployment, get important values:

```bash
terraform output
```

You'll see:
- `apprunner_service_url`: Your application URL
- `ecr_repository_url`: Where to push Docker images
- `apprunner_service_id`: Service identifier

## Configuration

### Variables

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
aws_region          = "us-east-1"
environment         = "production"
app_name            = "kbju-api"
ecr_repository_name = "kbju-app"
```

Or override via command line:

```bash
terraform apply -var="environment=staging" -var="aws_region=us-west-2"
```

### Available Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `environment` | Environment name | `production` |
| `app_name` | Application name | `kbju-api` |
| `ecr_repository_name` | ECR repository name | `kbju-app` |
| `github_owner` | GitHub username/org | `vitaly4uk` |
| `github_repository` | GitHub repository name | `mealmeter` |

### Security & IAM Configuration

**Terraform automatically creates a dedicated IAM user for GitHub Actions with minimal permissions:**

```json
{
  "Permissions": [
    "ecr:GetAuthorizationToken" (global),
    "ecr:BatchCheckLayerAvailability" (scoped to your ECR repo),
    "ecr:GetDownloadUrlForLayer" (scoped to your ECR repo),
    "ecr:BatchGetImage" (scoped to your ECR repo),
    "ecr:PutImage" (scoped to your ECR repo),
    "ecr:InitiateLayerUpload" (scoped to your ECR repo),
    "ecr:UploadLayerPart" (scoped to your ECR repo),
    "ecr:CompleteLayerUpload" (scoped to your ECR repo)
  ]
}
```

**Benefits:**
- ✅ No need to manage AWS credentials manually
- ✅ Minimal permissions (least privilege principle)
- ✅ Scoped to specific ECR repository only
- ✅ Separate from your personal AWS credentials
- ✅ Easy to rotate or revoke if needed

### GitHub Configuration

The Terraform configuration will automatically:

1. **Create IAM User for GitHub Actions:**
   - Name: `kbju-api-github-actions`
   - Policy: Minimal ECR push permissions only
   - Access keys: Auto-generated

2. **Configure Repository Settings:**
   - Set repository description and topics
   - Enable vulnerability alerts
   - Configure merge strategies

3. **Create GitHub Actions Secrets:**
   - `AWS_ACCESS_KEY_ID`: From IAM user
   - `AWS_SECRET_ACCESS_KEY`: From IAM user

4. **Create GitHub Actions Variables:**
   - `AWS_REGION`: AWS region
   - `ECR_REPOSITORY`: ECR repository name
   - `APP_RUNNER_SERVICE`: App Runner service name

After Terraform apply, your GitHub Actions workflow will be fully configured and ready to deploy automatically!

## First Deployment

After creating the infrastructure, you need to push a Docker image:

### 1. Login to ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d'/' -f1)
```

### 2. Build and Tag the Image

```bash
cd ../backend
docker build -t kbju-app .
docker tag kbju-app:latest $(cd ../terraform && terraform output -raw ecr_repository_url):latest
```

### 3. Push to ECR

```bash
docker push $(cd ../terraform && terraform output -raw ecr_repository_url):latest
```

### 4. Wait for Deployment

App Runner will automatically detect the new image and deploy it. Check the status:

```bash
aws apprunner list-operations \
  --service-arn $(terraform output -raw apprunner_service_arn) \
  --region us-east-1
```

### 5. Access Your Application

```bash
curl https://$(terraform output -raw apprunner_service_url)
```

Or visit in browser:
```bash
echo "https://$(terraform output -raw apprunner_service_url)"
```

## Resource Details

### App Runner Configuration

- **CPU**: 0.25 vCPU (256 MB)
- **Memory**: 0.5 GB (512 MB)
- **Port**: 8000
- **Health Check**: HTTP GET `/health` every 10 seconds
- **Auto-deployment**: Enabled (triggers on new ECR image push)

### ECR Lifecycle Policy

The ECR repository keeps only the last 10 images to save storage costs.

## Cost Estimation

Approximate monthly costs (us-east-1):

- **App Runner**: ~$5-10/month (0.25 vCPU, 0.5 GB)
- **ECR Storage**: ~$0.10/month (per GB)
- **Data Transfer**: Varies by usage

Total: **~$5-15/month** for light usage

## Updating the Infrastructure

### Modify Resources

1. Edit the `.tf` files
2. Review changes: `terraform plan`
3. Apply changes: `terraform apply`

### Destroy Resources

⚠️ **Warning**: This will delete all resources and data!

```bash
terraform destroy
```

## Troubleshooting

### App Runner Service Not Starting

Check service status:
```bash
aws apprunner describe-service \
  --service-arn $(terraform output -raw apprunner_service_arn) \
  --region us-east-1
```

View logs:
```bash
# Get log stream names
aws logs describe-log-streams \
  --log-group-name /aws/apprunner/$(terraform output -raw app_name)/service \
  --region us-east-1

# View logs
aws logs tail /aws/apprunner/$(terraform output -raw app_name)/service \
  --follow \
  --region us-east-1
```

### ECR Authentication Issues

Refresh ECR login:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw ecr_repository_url | cut -d'/' -f1)
```

### Terraform State Issues

If state gets out of sync:
```bash
terraform refresh
terraform plan
```

## CI/CD Integration

This infrastructure works with GitHub Actions for automated deployments. See `.github/workflows/deploy-backend.yml` for the CI/CD pipeline.

## Security Notes

- ECR images are scanned on push for vulnerabilities
- App Runner service runs with minimal IAM permissions
- No VPC configuration required (App Runner handles networking)
- Health checks ensure application availability

## Next Steps

After infrastructure is deployed:

1. Set up GitHub Actions secrets for CI/CD
2. Configure custom domain (optional)
3. Add environment variables via Terraform
4. Set up monitoring and alerting
5. Configure backup and disaster recovery

## Useful Commands

```bash
# Show current outputs
terraform output

# Get specific output
terraform output apprunner_service_url

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
# Test auto-deploy
