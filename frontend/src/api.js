import { API_URL } from './config.js';

/**
 * Fetch daily stats for a user
 * @param {number} userId - User ID
 * @returns {Promise<Object>} Stats object with calories, protein, fat, carbs
 */
export async function fetchStats(userId) {
  try {
    const response = await fetch(`${API_URL}/api/stats/${userId}/today`);
    if (!response.ok) {
      throw new Error(`Failed to fetch stats: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Error fetching stats:', error);
    throw error;
  }
}

/**
 * Create a new meal
 * @param {Object} mealData - Meal data with user_id, calories, protein, fat, carbs
 * @returns {Promise<Object>} Created meal object
 */
export async function createMeal(mealData) {
  try {
    const response = await fetch(`${API_URL}/api/meals`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(mealData),
    });
    if (!response.ok) {
      throw new Error(`Failed to create meal: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Error creating meal:', error);
    throw error;
  }
}

/**
 * Fetch meals for a user
 * @param {number} userId - User ID
 * @param {number} limit - Number of meals to fetch (default: 10)
 * @returns {Promise<Array>} Array of meal objects
 */
export async function fetchMeals(userId, limit = 10) {
  try {
    const response = await fetch(`${API_URL}/api/meals/${userId}?limit=${limit}`);
    if (!response.ok) {
      throw new Error(`Failed to fetch meals: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Error fetching meals:', error);
    throw error;
  }
}
