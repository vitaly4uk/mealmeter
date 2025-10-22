# MealMeter - KBJU API

A FastAPI application for tracking meals and nutrition (KBJU: Calories, Proteins, Fats, Carbohydrates), deployed on AWS App Runner.

## Project Structure

```
mealmeter/
├── backend/              # FastAPI application
│   ├── app/             # Application code
│   ├── Dockerfile       # Container configuration
│   ├── pyproject.toml   # Python dependencies
│   └── README.md        # Backend documentation
├── terraform/           # AWS infrastructure
│   ├── main.tf         # Resource definitions
│   ├── variables.tf    # Configuration variables
│   ├── outputs.tf      # Output values
│   └── README.md       # Infrastructure documentation
└── .github/
    └── workflows/
        └── deploy-backend.yml  # CI/CD pipeline
```

## Quick Start

### 1. Local Development

```bash
# Install uv (fast Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Navigate to backend and install dependencies
cd backend
uv sync

# Run the development server
uv run uvicorn app.main:app --reload
```

Visit:
- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs

### 2. Deploy Infrastructure

```bash
# Install Terraform
# Visit https://www.terraform.io/downloads

# Configure AWS credentials
aws configure

# Deploy infrastructure
cd terraform
terraform init
terraform apply
```

### 3. Build and Push Docker Image

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d'/' -f1)

# Build and push
cd ../backend
docker build -t kbju-app .
docker tag kbju-app:latest $(cd ../terraform && terraform output -raw ecr_repository_url):latest
docker push $(cd ../terraform && terraform output -raw ecr_repository_url):latest
```

## CI/CD with GitHub Actions

### Setup

1. **Create GitHub Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/mealmeter.git
   git push -u origin main
   ```

2. **Configure GitHub Secrets**

   Go to your repository → Settings → Secrets and variables → Actions

   Add the following secrets:

   | Secret Name | Description | How to Get |
   |-------------|-------------|------------|
   | `AWS_ACCESS_KEY_ID` | AWS access key | `aws configure get aws_access_key_id` |
   | `AWS_SECRET_ACCESS_KEY` | AWS secret key | `aws configure get aws_secret_access_key` |

   **Creating AWS IAM User for GitHub Actions:**
   ```bash
   # Create IAM user
   aws iam create-user --user-name github-actions-mealmeter

   # Attach ECR and App Runner policies
   aws iam attach-user-policy \
     --user-name github-actions-mealmeter \
     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

   # Create access key
   aws iam create-access-key --user-name github-actions-mealmeter
   ```

### How It Works

The GitHub Actions workflow automatically:

1. **Triggers** on:
   - Push to `main` branch with changes in `backend/**`
   - Manual workflow dispatch

2. **Builds**:
   - Checks out code
   - Builds Docker image using `backend/Dockerfile`
   - Tags image with git commit SHA and `latest`

3. **Deploys**:
   - Pushes image to AWS ECR
   - App Runner automatically detects new image and deploys

### Manual Deployment

Trigger deployment manually from GitHub:

1. Go to **Actions** tab
2. Select **Deploy Backend to AWS App Runner**
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### Monitoring Deployments

**View workflow runs:**
- GitHub → Actions tab → Deploy Backend workflow

**Check App Runner deployment:**
```bash
aws apprunner list-operations \
  --service-arn $(cd terraform && terraform output -raw apprunner_service_arn) \
  --region us-east-1
```

**View application logs:**
```bash
aws logs tail /aws/apprunner/kbju-api/service --follow --region us-east-1
```

## API Endpoints

- `GET /` - API information
- `GET /health` - Health check endpoint
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)

## Environment Variables

Currently no environment variables are required. To add them:

**Locally** (`.env` file):
```bash
cp backend/.env.example backend/.env
# Edit backend/.env with your values
```

**AWS App Runner** (via Terraform):

Edit `terraform/main.tf` and add to `runtime_environment_variables`:
```hcl
runtime_environment_variables = {
  ENVIRONMENT = var.environment
  DATABASE_URL = var.database_url  # Add your variables
}
```

**GitHub Actions** (via secrets):

Add to `.github/workflows/deploy-backend.yml` in the image configuration step.

## Cost Estimation

Approximate monthly costs (us-east-1):

| Service | Configuration | Cost |
|---------|--------------|------|
| App Runner | 0.25 vCPU, 0.5 GB | ~$5-10 |
| ECR Storage | <1 GB (10 images) | ~$0.10 |
| Data Transfer | Light usage | ~$1 |
| **Total** | | **~$6-11/month** |

## Architecture

```
┌─────────────┐
│   GitHub    │
│   Actions   │
└──────┬──────┘
       │ Push Docker Image
       ▼
┌─────────────┐      ┌──────────────┐
│     ECR     │─────▶│  App Runner  │
│ Repository  │      │   Service    │
└─────────────┘      └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │   FastAPI    │
                     │ Application  │
                     └──────────────┘
```

## Development Workflow

1. **Make changes** in `backend/`
2. **Test locally**:
   ```bash
   cd backend
   uv run uvicorn app.main:app --reload
   ```
3. **Commit and push** to GitHub:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```
4. **GitHub Actions** automatically builds and deploys
5. **Verify** deployment at App Runner URL

## Troubleshooting

### Local Development

**Dependencies not installing:**
```bash
# Ensure uv is installed
uv --version

# Clean and reinstall
rm -rf .venv
uv sync
```

**Port already in use:**
```bash
# Use a different port
uv run uvicorn app.main:app --port 8080
```

### GitHub Actions

**Build failing:**
- Check Actions tab for error logs
- Verify Dockerfile syntax
- Ensure all files are committed

**Deployment failing:**
- Verify AWS credentials in GitHub secrets
- Check ECR repository exists (created by Terraform)
- Ensure IAM user has correct permissions

### AWS App Runner

**Service not starting:**
```bash
# Check service status
aws apprunner describe-service \
  --service-arn $(cd terraform && terraform output -raw apprunner_service_arn) \
  --region us-east-1

# View logs
aws logs tail /aws/apprunner/kbju-api/service --follow --region us-east-1
```

**Health check failing:**
- Ensure `/health` endpoint returns 200 OK
- Check application is running on port 8000
- Verify health check configuration in Terraform

## Security

- ✅ ECR images scanned on push
- ✅ IAM roles with minimal permissions
- ✅ GitHub secrets for sensitive data
- ✅ HTTPS by default (App Runner)
- ⚠️ CORS allows all origins (adjust for production)

## Next Steps

- [ ] Add database (RDS PostgreSQL or DynamoDB)
- [ ] Implement authentication (JWT tokens)
- [ ] Add meal tracking endpoints
- [ ] Set up automated testing
- [ ] Configure custom domain
- [ ] Add monitoring and alerting
- [ ] Implement logging and observability
- [ ] Add rate limiting
- [ ] Configure staging environment

## Documentation

- [Backend Documentation](backend/README.md) - FastAPI application details
- [Infrastructure Documentation](terraform/README.md) - Terraform and AWS setup
- [GitHub Actions Workflow](.github/workflows/deploy-backend.yml) - CI/CD pipeline

## Technologies

- **Backend**: FastAPI, Python 3.11+
- **Package Manager**: uv (fast Python package installer)
- **Container**: Docker
- **Infrastructure**: Terraform
- **Cloud**: AWS (App Runner, ECR)
- **CI/CD**: GitHub Actions

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Open an issue on GitHub
- Check the documentation in each directory
- Review AWS CloudWatch logs for runtime issues
