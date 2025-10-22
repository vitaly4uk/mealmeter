"""Pydantic schemas for request/response validation."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class MealCreate(BaseModel):
    """Request model for creating a new meal."""

    user_id: str = Field(..., description="User identifier")
    calories: float = Field(..., ge=0, description="Calorie count")
    protein: float = Field(..., ge=0, description="Protein in grams")
    fat: float = Field(..., ge=0, description="Fat in grams")
    carbs: float = Field(..., ge=0, description="Carbohydrates in grams")
    meal_type: Optional[str] = Field(
        None, description="Meal type (breakfast, lunch, dinner, snack)"
    )
    description: Optional[str] = Field(None, description="Meal description")


class MealResponse(BaseModel):
    """Response model for meal data."""

    user_id: str
    timestamp: datetime
    calories: float
    protein: float
    fat: float
    carbs: float
    meal_type: Optional[str] = None
    description: Optional[str] = None


class DailyStatsResponse(BaseModel):
    """Response model for daily nutrition statistics."""

    user_id: str
    date: str
    total_calories: float
    total_protein: float
    total_fat: float
    total_carbs: float
    meal_count: int
