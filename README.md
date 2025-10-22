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
├── frontend/            # Vite + Vanilla JS frontend
│   ├── src/            # Application source
│   ├── index.html      # Main HTML file
│   ├── package.json    # Dependencies
│   └── README.md       # Frontend documentation
├── terraform/          # AWS infrastructure
│   ├── main.tf        # App Runner & DynamoDB
│   ├── s3_cloudfront.tf  # S3 + CloudFront for frontend
│   ├── variables.tf   # Configuration variables
│   ├── outputs.tf     # Output values
│   └── README.md      # Infrastructure documentation
└── .github/
    └── workflows/
        ├── deploy-backend.yml   # Backend CI/CD
        └── deploy-frontend.yml  # Frontend CI/CD
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
- Backend API: http://localhost:8000
- Interactive API docs: http://localhost:8000/docs
- Frontend: http://localhost:3000

For frontend development:
```bash
cd frontend
npm install
npm run dev
```

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

2. **GitHub Secrets (Automatically Managed by Terraform)**

   **No manual setup needed!** Terraform automatically configures all GitHub Actions secrets and variables:

   **Automatically set secrets:**
   - `AWS_ACCESS_KEY_ID` - IAM user for GitHub Actions
   - `AWS_SECRET_ACCESS_KEY` - IAM user secret key
   - `API_URL` - Backend API URL (from App Runner)
   - `CLOUDFRONT_DISTRIBUTION_ID` - CloudFront distribution ID

   **Automatically set variables:**
   - `AWS_REGION` - us-east-1
   - `ECR_REPOSITORY` - ECR repository name
   - `APP_RUNNER_SERVICE` - App Runner service name
   - `S3_BUCKET_NAME` - S3 bucket for frontend

   ℹ️ **Prerequisites:**
   ```bash
   # Set GitHub token before terraform apply
   export GITHUB_TOKEN="your_github_personal_access_token"
   ```

   Create token at: GitHub → Settings → Developer settings → Personal access tokens
   Required scopes: `repo`, `admin:repo_hook`

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

## Frontend

**Live URL**: Check CloudFront distribution URL after deployment

**Local Development**:
```bash
cd frontend
npm install
npm run dev
```

See [Frontend Documentation](frontend/README.md) for details.

## API Endpoints

- `GET /` - API information
- `GET /health` - Health check endpoint
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)
- `POST /api/meals` - Create a new meal
- `GET /api/meals/{user_id}` - List user meals
- `GET /api/stats/{user_id}/today` - Get today's stats

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

Approximate monthly costs (us-east-1) for low traffic:

| Service | Configuration | Cost |
|---------|--------------|------|
| App Runner | 0.25 vCPU, 0.5 GB | ~$5-10 |
| ECR Storage | <1 GB (10 images) | ~$0.10 |
| DynamoDB | On-demand, light usage | ~$0.25 |
| S3 + CloudFront | Free tier eligible | ~$0-1 |
| Data Transfer | Light usage | ~$1 |
| **Total** | | **~$6-12/month** |

**Free Tier**: S3 and CloudFront are mostly free for first 12 months and light traffic.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 User Browser                     │
└───────┬─────────────────────────┬───────────────┘
        │                         │
        │ Static Files            │ API Calls
        ▼                         ▼
┌──────────────┐          ┌──────────────┐
│  CloudFront  │          │  App Runner  │
│     (CDN)    │          │   (Backend)  │
└──────┬───────┘          └──────┬───────┘
       │                         │
       ▼                         ▼
┌──────────────┐          ┌──────────────┐
│  S3 Bucket   │          │   DynamoDB   │
│  (Frontend)  │          │  (Database)  │
└──────────────┘          └──────────────┘

GitHub Actions CI/CD:
- Backend → ECR → App Runner (auto-deploy)
- Frontend → Build → S3 → CloudFront invalidation
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
- [Frontend Documentation](frontend/README.md) - Vite + Vanilla JS frontend
- [Infrastructure Documentation](terraform/README.md) - Terraform and AWS setup
- [Backend CI/CD](.github/workflows/deploy-backend.yml) - Backend deployment pipeline
- [Frontend CI/CD](.github/workflows/deploy-frontend.yml) - Frontend deployment pipeline

## Technologies

- **Backend**: FastAPI, Python 3.11+, DynamoDB
- **Frontend**: Vite, Vanilla JavaScript, Tailwind CSS
- **Package Manager**: uv (Python), npm (JavaScript)
- **Container**: Docker (backend only)
- **Infrastructure**: Terraform
- **Cloud**: AWS (App Runner, ECR, DynamoDB, S3, CloudFront)
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
