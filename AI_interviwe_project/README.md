# AI Interviewer System

A web-based system that analyzes job postings and generates personalized learning roadmaps and interview preparation guides using AI.

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture documentation.

## Features

- **Job Scraping**: Extracts job descriptions from LinkedIn and company career pages
- **Data Normalization**: Structures job data into a standardized format
- **AI-Powered Analysis**: Generates personalized learning roadmaps and interview guides
- **Clean Service Boundaries**: Modular design with extensible services
- **Modern UI**: React-based frontend with responsive design

## Technology Stack

- **Backend**: Ballerina 2201.13.1
- **Frontend**: React 19.2.3
- **AI Integration**: External LLM API (OpenAI, Anthropic, etc.)

## Prerequisites

- Ballerina 2201.13.1 or later
- Node.js 16+ and npm
- LLM API key (optional - system works with mock data if not configured)

## Setup

### Backend Setup

1. Navigate to the project root:
```bash
cd AI_interviwe_project
```

2. Configure environment variables (create a `.env` file or set system variables):
```bash
export LLM_API_KEY=your-api-key-here
export LLM_API_URL=https://api.openai.com/v1
export LLM_MODEL=gpt-4
export API_PORT=9090
export CORS_ORIGINS=http://localhost:3000
```

3. Run the Ballerina service:
```bash
bal run
```

The API will be available at `http://localhost:9090`

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file (optional):
```bash
REACT_APP_API_URL=http://localhost:9090/api
```

4. Start the development server:
```bash
npm start
```

The frontend will be available at `http://localhost:3000`

## Usage

1. Open the frontend application in your browser
2. Choose your input method:
   - **Enter URL**: Paste a job posting URL from supported sites
   - **Paste Description**: Directly paste the job description text
3. Click "Analyze Job"
4. Wait for the analysis to complete (the system will poll for results)
5. Review the generated:
   - Job Profile (normalized job data)
   - Learning Roadmap (personalized learning path)
   - Interview Guide (preparation tips and questions)

### Supported Job Sites

- LinkedIn
- Indeed
- Glassdoor
- Greenhouse
- Lever
- Workday

> **Tip**: If URL scraping fails, use the "Paste Description" option to directly input the job posting text.

## API Endpoints

### POST /api/jobs/analyze
Submit a job URL or description for analysis.

**Request (URL mode):**
```json
{
  "url": "https://linkedin.com/jobs/view/123456"
}
```

**Request (Paste mode):**
```json
{
  "url": "manual-input",
  "jobDescription": "Full job description text here..."
}
```

**Response:**
```json
{
  "jobId": "uuid-here",
  "status": "processing",
  "message": "Job analysis started"
}
```

### GET /api/jobs/{jobId}
Retrieve analysis results.

**Response:**
```json
{
  "jobId": "uuid-here",
  "status": "completed",
  "jobProfile": { ... },
  "learningRoadmap": { ... },
  "interviewGuide": { ... }
}
```

### GET /api/health
Health check endpoint.

## Configuration

### Using Config.toml (Recommended)

Create a `Config.toml` file in the project root:

```toml
[AI_interviwe_project.services.config]
llmApiKey = "your-api-key"
llmApiUrl = "https://api.openai.com/v1"
llmModel = "gpt-4"
apiPort = 9090
corsOrigins = "http://localhost:3000,http://127.0.0.1:3000"
```

### Environment Variables

Environment variables override Config.toml values:

| Variable | Description | Default |
|----------|-------------|---------|
| `LLM_API_KEY` | API key for LLM provider | Required for AI features |
| `LLM_API_URL` | Base URL for LLM API | https://api.openai.com/v1 |
| `LLM_MODEL` | Model name | gpt-4 |
| `API_PORT` | Port for API Gateway | 9090 |
| `SCRAPER_TIMEOUT` | Timeout for web scraping (seconds) | 30 |
| `CORS_ORIGINS` | Comma-separated allowed origins | http://localhost:3000 |

## Security Features

- **URL Validation**: Only allows URLs from supported job sites
- **Rate Limiting**: 10 requests per minute per IP address
- **Input Sanitization**: Removes potentially harmful content from inputs
- **CORS Protection**: Configurable allowed origins

## Project Structure

```
AI_interviwe_project/
├── main.bal                 # API Gateway service
├── types.bal                # Data models and types
├── Config.toml              # Configuration file
├── services/
│   ├── config.bal          # Configuration service
│   ├── job_scraper.bal     # Job scraping service
│   ├── job_normalizer.bal   # Job normalization service
│   └── llm_service.bal     # LLM integration service
├── frontend/               # React frontend
│   ├── src/
│   │   ├── App.js          # Main React component
│   │   └── App.css         # Styles
│   └── package.json
├── ARCHITECTURE.md         # Architecture documentation
└── README.md              # This file
```

## Extensibility

The system is designed with extensibility in mind:

1. **Scraper Plugins**: Add new scrapers by implementing the `Scraper` interface
2. **Normalizer Strategies**: Add site-specific normalizers
3. **LLM Providers**: Swap LLM providers via configuration
4. **Storage**: Add database layer for persistence (currently in-memory)
5. **Authentication**: Add auth middleware at API Gateway level

## Limitations

- Currently uses in-memory storage (results are lost on restart)
- Web scraping may fail for sites with anti-scraping measures
- Mock data is used if LLM API key is not configured
- No authentication/authorization implemented

## Future Enhancements

- Database persistence for analysis results
- User authentication and saved analyses
- Support for more job sites
- Enhanced HTML parsing for better extraction
- Caching layer for repeated analyses
- Email notifications for completed analyses

## License

MIT License


