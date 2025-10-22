"""Main FastAPI application."""

from datetime import date, datetime

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .models import MealModel
from .schemas import DailyStatsResponse, MealCreate, MealResponse

# Create FastAPI application instance
app = FastAPI(
    title="KBJU API",
    description="Meal tracking application for tracking calories, proteins, fats, and carbohydrates",
    version="0.1.0",
)

# Configure CORS middleware
# TODO: Restrict to CloudFront domain in production
# For now, allow all origins for simplicity during development and testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (CloudFront URL will be added later)
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


@app.post("/api/meals", response_model=MealResponse, status_code=201)
async def create_meal(meal: MealCreate):
    """
    Create a new meal entry.

    Example request:
    ```json
    {
        "user_id": "user123",
        "calories": 350,
        "protein": 25,
        "fat": 15,
        "carbs": 30,
        "meal_type": "lunch",
        "description": "Grilled chicken with vegetables"
    }
    ```

    Example response:
    ```json
    {
        "user_id": "user123",
        "timestamp": "2025-10-22T12:30:00Z",
        "calories": 350,
        "protein": 25,
        "fat": 15,
        "carbs": 30,
        "meal_type": "lunch",
        "description": "Grilled chicken with vegetables"
    }
    ```
    """
    try:
        # Create meal with current timestamp
        meal_model = MealModel(
            user_id=meal.user_id,
            timestamp=datetime.utcnow(),
            calories=meal.calories,
            protein=meal.protein,
            fat=meal.fat,
            carbs=meal.carbs,
            meal_type=meal.meal_type,
            description=meal.description,
        )
        meal_model.save()

        return MealResponse(
            user_id=meal_model.user_id,
            timestamp=meal_model.timestamp,
            calories=float(meal_model.calories),
            protein=float(meal_model.protein),
            fat=float(meal_model.fat),
            carbs=float(meal_model.carbs),
            meal_type=meal_model.meal_type,
            description=meal_model.description,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to create meal: {str(e)}"
        )


@app.get("/api/meals/{user_id}", response_model=list[MealResponse])
async def list_user_meals(
    user_id: str,
    limit: int = 50,
):
    """
    List meals for a specific user.

    Args:
        user_id: User identifier
        limit: Maximum number of meals to return (default: 50)

    Example response:
    ```json
    [
        {
            "user_id": "user123",
            "timestamp": "2025-10-22T12:30:00Z",
            "calories": 350,
            "protein": 25,
            "fat": 15,
            "carbs": 30,
            "meal_type": "lunch",
            "description": "Grilled chicken with vegetables"
        }
    ]
    ```
    """
    try:
        meals = MealModel.query(user_id, limit=limit)
        return [
            MealResponse(
                user_id=meal.user_id,
                timestamp=meal.timestamp,
                calories=float(meal.calories),
                protein=float(meal.protein),
                fat=float(meal.fat),
                carbs=float(meal.carbs),
                meal_type=meal.meal_type,
                description=meal.description,
            )
            for meal in meals
        ]
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Failed to retrieve meals: {str(e)}"
        )


@app.get("/api/stats/{user_id}/today", response_model=DailyStatsResponse)
async def get_today_stats(user_id: str):
    """
    Get aggregated nutrition statistics for today.

    Example response:
    ```json
    {
        "user_id": "user123",
        "date": "2025-10-22",
        "total_calories": 1850,
        "total_protein": 120,
        "total_fat": 65,
        "total_carbs": 180,
        "meal_count": 4
    }
    ```
    """
    try:
        today = date.today()
        stats = MealModel.get_daily_stats(user_id, today)
        return DailyStatsResponse(**stats)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve daily stats: {str(e)}",
        )
