import { fetchStats, createMeal, fetchMeals } from './api.js';

// Hard-coded user ID for now (will be replaced with auth later)
const USER_ID = 123;

// DOM elements
let statsElements = {};
let mealsListElement = null;
let mealFormElement = null;

/**
 * Initialize the application
 */
async function init() {
  // Get DOM elements
  statsElements = {
    calories: document.getElementById('stat-calories'),
    protein: document.getElementById('stat-protein'),
    fat: document.getElementById('stat-fat'),
    carbs: document.getElementById('stat-carbs'),
  };
  mealsListElement = document.getElementById('meals-list');
  mealFormElement = document.getElementById('meal-form');

  // Setup form submission
  mealFormElement.addEventListener('submit', handleFormSubmit);

  // Load initial data
  await loadData();
}

/**
 * Load stats and meals
 */
async function loadData() {
  try {
    // Show loading state
    showLoading();

    // Fetch data in parallel
    const [stats, meals] = await Promise.all([
      fetchStats(USER_ID),
      fetchMeals(USER_ID, 20),
    ]);

    // Update UI
    updateStats(stats);
    updateMealsList(meals);
  } catch (error) {
    showError('Failed to load data. Please try again.');
    console.error('Error loading data:', error);
  }
}

/**
 * Handle form submission
 */
async function handleFormSubmit(event) {
  event.preventDefault();

  const formData = new FormData(event.target);
  const mealData = {
    user_id: USER_ID,
    calories: parseFloat(formData.get('calories')) || 0,
    protein: parseFloat(formData.get('protein')) || 0,
    fat: parseFloat(formData.get('fat')) || 0,
    carbs: parseFloat(formData.get('carbs')) || 0,
  };

  try {
    // Show loading state
    const submitButton = event.target.querySelector('button[type="submit"]');
    submitButton.disabled = true;
    submitButton.textContent = 'Adding...';

    // Create meal
    await createMeal(mealData);

    // Reset form
    event.target.reset();

    // Reload data
    await loadData();

    // Show success message
    showSuccess('Meal added successfully!');
  } catch (error) {
    showError('Failed to add meal. Please try again.');
    console.error('Error creating meal:', error);
  } finally {
    // Reset button
    const submitButton = event.target.querySelector('button[type="submit"]');
    submitButton.disabled = false;
    submitButton.textContent = 'Add Meal';
  }
}

/**
 * Update stats display
 */
function updateStats(stats) {
  statsElements.calories.textContent = Math.round(stats.calories || 0);
  statsElements.protein.textContent = Math.round(stats.protein || 0);
  statsElements.fat.textContent = Math.round(stats.fat || 0);
  statsElements.carbs.textContent = Math.round(stats.carbs || 0);
}

/**
 * Update meals list
 */
function updateMealsList(meals) {
  if (!meals || meals.length === 0) {
    mealsListElement.innerHTML = `
      <div class="text-center text-gray-500 py-8">
        <p class="text-lg">No meals yet today</p>
        <p class="text-sm mt-2">Add your first meal using the form above</p>
      </div>
    `;
    return;
  }

  mealsListElement.innerHTML = meals
    .map(
      (meal) => `
      <div class="bg-white border border-gray-200 rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex justify-between items-start mb-3">
          <div class="text-sm text-gray-500">
            ${formatDate(meal.timestamp)}
          </div>
          <div class="text-lg font-semibold text-gray-900">
            ${Math.round(meal.calories)} kcal
          </div>
        </div>
        <div class="grid grid-cols-3 gap-3 text-sm">
          <div>
            <span class="text-gray-600">Protein:</span>
            <span class="font-medium ml-1">${Math.round(meal.protein)}g</span>
          </div>
          <div>
            <span class="text-gray-600">Fat:</span>
            <span class="font-medium ml-1">${Math.round(meal.fat)}g</span>
          </div>
          <div>
            <span class="text-gray-600">Carbs:</span>
            <span class="font-medium ml-1">${Math.round(meal.carbs)}g</span>
          </div>
        </div>
      </div>
    `
    )
    .join('');
}

/**
 * Format timestamp to readable string
 */
function formatDate(timestamp) {
  const date = new Date(timestamp);
  const today = new Date();

  const isToday = date.toDateString() === today.toDateString();

  if (isToday) {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Show loading state
 */
function showLoading() {
  if (statsElements.calories) {
    Object.values(statsElements).forEach((el) => {
      el.textContent = '...';
    });
  }
}

/**
 * Show error message
 */
function showError(message) {
  // Simple alert for now (can be replaced with toast notification)
  alert(`❌ ${message}`);
}

/**
 * Show success message
 */
function showSuccess(message) {
  // Simple alert for now (can be replaced with toast notification)
  const toast = document.createElement('div');
  toast.className = 'fixed top-4 right-4 bg-green-500 text-white px-6 py-3 rounded-lg shadow-lg z-50';
  toast.textContent = `✅ ${message}`;
  document.body.appendChild(toast);

  setTimeout(() => {
    toast.remove();
  }, 3000);
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
