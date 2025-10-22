"""DynamoDB models using PynamoDB."""
from datetime import date, datetime
from typing import Optional

from pynamodb.attributes import NumberAttribute, UnicodeAttribute, UTCDateTimeAttribute
from pynamodb.models import Model

from .config import settings


class MealModel(Model):
    """
    DynamoDB model for storing meal nutrition data.

    Attributes:
        user_id: User identifier (partition key)
        timestamp: ISO format timestamp (sort key)
        calories: Calorie count
        protein: Protein in grams
        fat: Fat in grams
        carbs: Carbohydrates in grams
        meal_type: Optional meal type (breakfast, lunch, dinner, snack)
        description: Optional meal description
    """

    class Meta:
        table_name = settings.dynamodb_table
        region = settings.aws_region

    # Primary keys
    user_id = UnicodeAttribute(hash_key=True)
    timestamp = UTCDateTimeAttribute(range_key=True)

    # Nutrition data
    calories = NumberAttribute()
    protein = NumberAttribute()
    fat = NumberAttribute()
    carbs = NumberAttribute()

    # Optional fields
    meal_type = UnicodeAttribute(null=True)
    description = UnicodeAttribute(null=True)

    @classmethod
    def get_daily_stats(cls, user_id: str, target_date: date) -> dict:
        """
        Get aggregated nutrition statistics for a user on a specific date.

        Args:
            user_id: User identifier
            target_date: Date to calculate stats for

        Returns:
            Dictionary with total calories, protein, fat, carbs, and meal count
        """
        # Query meals for the user on the target date
        start_datetime = datetime.combine(target_date, datetime.min.time())
        end_datetime = datetime.combine(target_date, datetime.max.time())

        meals = cls.query(
            user_id,
            cls.timestamp.between(start_datetime, end_datetime)
        )

        # Aggregate nutrition data
        total_calories = 0.0
        total_protein = 0.0
        total_fat = 0.0
        total_carbs = 0.0
        meal_count = 0

        for meal in meals:
            total_calories += float(meal.calories)
            total_protein += float(meal.protein)
            total_fat += float(meal.fat)
            total_carbs += float(meal.carbs)
            meal_count += 1

        return {
            "user_id": user_id,
            "date": target_date.isoformat(),
            "total_calories": total_calories,
            "total_protein": total_protein,
            "total_fat": total_fat,
            "total_carbs": total_carbs,
            "meal_count": meal_count,
        }
