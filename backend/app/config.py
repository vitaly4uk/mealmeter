"""Application configuration management using pydantic-settings."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # AWS Configuration
    aws_region: str = "us-east-1"
    dynamodb_table: str = "kbju_meals"

    # Application Configuration
    environment: str = "development"


# Global settings instance
settings = Settings()
