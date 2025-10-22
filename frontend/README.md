# КБЖУ Tracker Frontend

Simple, minimal frontend for tracking daily calories, protein, fat, and carbs.

## Tech Stack

- **Vite** - Fast build tool and dev server
- **Vanilla JavaScript** - No frameworks, just native JS
- **Tailwind CSS** - Utility-first CSS (via CDN)
- **Deployed to**: AWS S3 + CloudFront

## Local Development

### Prerequisites

- Node.js 20 or higher
- npm or yarn

### Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file (copy from example):
```bash
cp .env.example .env
```

3. Edit `.env` to point to your API:
```env
VITE_API_URL=https://bfipae6drt.us-east-1.awsapprunner.com
```

Or for local backend development:
```env
VITE_API_URL=http://localhost:8000
```

### Run Development Server

```bash
npm run dev
```

The app will be available at http://localhost:3000

### Build for Production

```bash
npm run build
```

The production build will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `http://localhost:8000` |

## Features

- ✅ **Real-time Stats** - View today's total calories, protein, fat, and carbs
- ✅ **Add Meals** - Simple form to log meals with nutrition info
- ✅ **Recent Meals** - Scrollable list of recent meal entries
- ✅ **Responsive Design** - Works on mobile and desktop
- ✅ **Fast Loading** - Minimal dependencies, CDN-based CSS

## Architecture

```
User Browser
    ↓
CloudFront (CDN) - Serves static files
    ↓
S3 Bucket - Stores built frontend files
    ↓
API Calls → App Runner (Backend API) → DynamoDB
```

## Current Limitations

- **Hardcoded User ID**: Currently uses `user_id=123` for all requests
- **No Authentication**: Auth will be added in future iteration
- **Basic Error Handling**: Simple alerts for errors (can be improved)
- **No Offline Support**: Requires internet connection to function

## Future Improvements

- [ ] User authentication (Auth0 or Cognito)
- [ ] Meal editing and deletion
- [ ] Daily/weekly/monthly statistics charts
- [ ] Meal templates and favorites
- [ ] Photo uploads for meals
- [ ] Nutrition goals and tracking
- [ ] PWA support for offline usage

## Deployment

The frontend is automatically deployed via GitHub Actions when changes are pushed to the `main` branch.

**Deployment flow:**
1. Push to main branch with changes in `frontend/**`
2. GitHub Actions builds the app
3. Syncs to S3 bucket
4. Invalidates CloudFront cache
5. Live in ~2 minutes

**Live URL**: Check CloudFront distribution URL in Terraform outputs

## File Structure

```
frontend/
├── src/
│   ├── main.js      # Main application logic and UI updates
│   ├── api.js       # API client for backend communication
│   └── config.js    # Configuration (API URL)
├── index.html       # Main HTML with Tailwind CSS
├── package.json     # Dependencies and scripts
├── vite.config.js   # Vite configuration
└── .env.example     # Example environment variables
```

## API Integration

The frontend communicates with the backend API:

- `GET /api/stats/{user_id}/today` - Fetch daily stats
- `POST /api/meals` - Create new meal
- `GET /api/meals/{user_id}?limit={limit}` - Fetch recent meals

All API calls are in [src/api.js](src/api.js).

## Troubleshooting

**Problem**: "Failed to load data" error on page load

**Solution**:
- Check that backend API is running
- Verify `VITE_API_URL` in `.env` is correct
- Check browser console for CORS errors

---

**Problem**: Changes not appearing after deployment

**Solution**:
- Wait 1-2 minutes for CloudFront invalidation
- Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+R)
- Check S3 bucket has latest files

---

**Problem**: Build fails in GitHub Actions

**Solution**:
- Check that `package-lock.json` is committed
- Verify Node.js version matches (20.x)
- Check GitHub Actions logs for specific error

## License

MIT
