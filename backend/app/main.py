"""Main FastAPI application."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Create FastAPI application instance
app = FastAPI(
    title="KBJU API",
    description="Meal tracking application for tracking calories, proteins, fats, and carbohydrates",
    version="0.1.0",
)

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint returning API information."""
    return {
        "message": "KBJU API",
        "version": "0.1.0",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for AWS App Runner."""
    return {"status": "healthy"}
