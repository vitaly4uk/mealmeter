# KBJU API

A minimal FastAPI application for tracking meals and nutrition (KBJU: Calories, Proteins, Fats, Carbohydrates).

## Prerequisites

- Python 3.11 or higher
- [uv](https://docs.astral.sh/uv/) - Fast Python package installer

### Installing uv

**macOS/Linux:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows:**
```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Using pip:**
```bash
pip install uv
```

## Local Development

### 1. Install Dependencies

Navigate to the backend directory and sync dependencies:

```bash
cd backend
uv sync
```

This will create a virtual environment and install all required packages.

### 2. Run the Application

Start the development server:

```bash
uv run uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

### 3. Test the Endpoints

**Root endpoint:**
```bash
curl http://localhost:8000/
```

Expected response:
```json
{
  "message": "KBJU API",
  "version": "0.1.0"
}
```

**Health check endpoint:**
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy"
}
```

**Interactive API documentation:**
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Docker

### Build the Image

```bash
docker build -t kbju-api .
```

### Run the Container

```bash
docker run -p 8000:8000 kbju-api
```

Test the containerized application:
```bash
curl http://localhost:8000/health
```

## Project Structure

```
backend/
├── app/
│   ├── __init__.py        # Package initializer
│   └── main.py            # FastAPI application with endpoints
├── pyproject.toml         # Project dependencies and configuration
├── Dockerfile             # Docker image configuration
├── .env.example           # Example environment variables
├── .gitignore             # Git ignore rules
└── README.md              # This file
```

## Environment Variables

Copy `.env.example` to `.env` and configure as needed:

```bash
cp .env.example .env
```

Currently, no environment variables are required for basic operation.

## AWS App Runner Deployment

This application is ready for deployment to AWS App Runner:

1. The `/health` endpoint is configured for health checks
2. The application listens on port 8000
3. The Dockerfile is optimized for container deployment
4. CORS is configured to allow all origins (adjust for production)

See the Terraform configuration in the `terraform/` directory for automated deployment.

## Development Commands

**Install dependencies:**
```bash
uv sync
```

**Run development server with auto-reload:**
```bash
uv run uvicorn app.main:app --reload
```

**Run on custom host/port:**
```bash
uv run uvicorn app.main:app --host 0.0.0.0 --port 8080
```

## API Endpoints

- `GET /` - API information
- `GET /health` - Health check for AWS App Runner
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)

## Next Steps

- Add database integration (PostgreSQL/DynamoDB)
- Implement authentication and authorization
- Add meal tracking endpoints
- Set up automated testing
- Configure environment-specific settings
# Test auto-deploy
