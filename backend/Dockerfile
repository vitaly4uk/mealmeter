# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install uv for fast dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Set environment variables for uv
ENV UV_SYSTEM_PYTHON=1

# Copy dependency files first (for better layer caching)
COPY pyproject.toml uv.lock ./

# Sync dependencies using uv (faster than pip install)
RUN uv sync --no-dev --frozen

# Copy application code
COPY app ./app

# Expose port 8000 for AWS App Runner
EXPOSE 8000

# Run uvicorn server
CMD ["uv", "run", "--no-dev", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
