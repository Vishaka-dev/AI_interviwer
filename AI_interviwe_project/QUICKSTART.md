# Quick Start Guide

## Prerequisites

- Ballerina 2201.13.1 installed and in PATH
- Node.js 16+ and npm installed
- (Optional) LLM API key for AI features

## Step 1: Configure Backend

1. Copy `.env.example` to create your configuration:
   ```bash
   # On Windows PowerShell
   Copy-Item .env.example .env
   
   # On Linux/Mac
   cp .env.example .env
   ```

2. Edit `.env` and add your LLM API key (optional - system works with mock data):
   ```
   LLM_API_KEY=your-actual-api-key-here
   ```

3. Set environment variables (or use Config.toml for Ballerina):
   ```bash
   # Windows PowerShell
   $env:LLM_API_KEY="your-key-here"
   $env:API_PORT="9090"
   
   # Linux/Mac
   export LLM_API_KEY="your-key-here"
   export API_PORT="9090"
   ```

## Step 2: Start Backend

```bash
cd AI_interviwe_project
bal run
```

You should see:
```
Compiling source
    AI_interviwe_project:0.1.0

Running executable
[API Gateway] Server started on port 9090
```

## Step 3: Start Frontend

Open a new terminal:

```bash
cd AI_interviwe_project/frontend
npm install
npm start
```

The frontend will open at `http://localhost:3000`

## Step 4: Test the System

1. Open `http://localhost:3000` in your browser
2. Enter a job posting URL (e.g., a LinkedIn job URL)
3. Click "Analyze Job"
4. Wait for the analysis to complete
5. Review the generated roadmap and interview guide

## Testing with Mock Data

If you don't have an LLM API key configured, the system will use mock data. This is useful for testing the UI and workflow.

## Troubleshooting

### Backend won't start
- Check if port 9090 is available
- Verify Ballerina is installed: `bal version`
- Check for syntax errors: `bal build`

### Frontend can't connect to backend
- Ensure backend is running on port 9090
- Check CORS settings in `.env`
- Verify `REACT_APP_API_URL` in frontend `.env` (if created)

### Scraping fails
- Some websites block automated scraping
- Try a different job URL
- Check network connectivity

### LLM API errors
- Verify your API key is correct
- Check API quota/limits
- Ensure you have credits/access to the LLM service

## Next Steps

- Read [ARCHITECTURE.md](./ARCHITECTURE.md) for system design details
- Read [README.md](./README.md) for full documentation
- Customize scrapers for specific job sites
- Add database persistence for analysis results


