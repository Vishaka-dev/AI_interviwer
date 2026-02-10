# How to Run the AI Interviewer System

## Quick Start (Windows PowerShell)

### Step 1: Check Prerequisites

```powershell
# Check if Ballerina is installed
bal version

# Check if Node.js is installed
node --version
npm --version
```

If Ballerina is not installed, download from: https://ballerina.io/downloads/

### Step 2: Start the Backend (Terminal 1)

```powershell
# Navigate to project directory
cd AI_interviwe_project

# (Optional) Set environment variables for LLM API
# Skip this if you want to use mock data for testing
$env:LLM_API_KEY="your-api-key-here"
$env:API_PORT="9090"

# Run the Ballerina backend
bal run
```

**Expected Output:**
```
Compiling source
    AI_interviwe_project:0.1.0

Running executable
```

The backend will be running on `http://localhost:9090`

**Keep this terminal open!**

### Step 3: Start the Frontend (Terminal 2)

Open a **new PowerShell window**:

```powershell
# Navigate to frontend directory
cd AI_interviwe_project\frontend

# Install dependencies (only needed first time)
npm install

# Start the React development server
npm start
```

**Expected Output:**
```
Compiling...
webpack compiled successfully
```

The frontend will automatically open in your browser at `http://localhost:3000`

**Keep this terminal open too!**

### Step 4: Use the Application

1. The browser should open automatically to `http://localhost:3000`
2. If not, manually open: http://localhost:3000
3. Enter a job posting URL (e.g., a LinkedIn job URL)
4. Click "Analyze Job"
5. Wait for the analysis to complete (it will poll automatically)
6. View the results:
   - Job Profile
   - Learning Roadmap
   - Interview Guide

## Running Without LLM API Key (Mock Data)

If you don't have an LLM API key, the system will work with mock data:

```powershell
# Just run without setting LLM_API_KEY
cd AI_interviwe_project
bal run
```

The system will generate sample learning roadmaps and interview guides for testing.

## Troubleshooting

### Backend Issues

**Port 9090 already in use:**
```powershell
# Change the port
$env:API_PORT="9091"
bal run
```

**Ballerina not found:**
- Make sure Ballerina is installed and in your PATH
- Restart PowerShell after installing Ballerina

**Compilation errors:**
```powershell
# Check for syntax errors
bal build
```

### Frontend Issues

**Port 3000 already in use:**
- The React dev server will ask if you want to use a different port
- Type 'Y' to accept

**npm install fails:**
```powershell
# Clear cache and try again
npm cache clean --force
npm install
```

**Frontend can't connect to backend:**
- Make sure backend is running on port 9090
- Check that both services are running
- Verify no firewall is blocking the connection

### Testing the Backend Directly

You can test the backend API directly:

```powershell
# Health check
curl http://localhost:9090/api/health

# Or in PowerShell:
Invoke-WebRequest -Uri http://localhost:9090/api/health
```

## Stopping the Services

- **Backend**: Press `Ctrl+C` in the backend terminal
- **Frontend**: Press `Ctrl+C` in the frontend terminal

## What Happens When You Run

1. **Backend (`bal run`)**:
   - Compiles Ballerina code
   - Starts HTTP server on port 9090
   - Exposes REST API endpoints
   - Ready to process job analysis requests

2. **Frontend (`npm start`)**:
   - Compiles React code
   - Starts development server on port 3000
   - Opens browser automatically
   - Connects to backend API

3. **When you submit a job URL**:
   - Frontend sends request to backend
   - Backend scrapes the job posting
   - Backend normalizes the data
   - Backend calls LLM API (or uses mock data)
   - Frontend polls for results
   - Results are displayed

## Next Steps

- Read [ARCHITECTURE.md](./ARCHITECTURE.md) to understand the system design
- Read [README.md](./README.md) for full documentation
- Configure your LLM API key for real AI-generated content


