# AI Interviewer System - Architecture Documentation

## High-Level Architecture

```
┌─────────────────┐
│   React UI      │
│   (Frontend)    │
└────────┬────────┘
         │ HTTP/REST
         │
┌────────▼─────────────────────────────────────────────┐
│           API Gateway Service                        │
│           (main.bal - HTTP Service)                 │
└────────┬─────────────────────────────────────────────┘
         │
    ┌────┴────┬──────────────┬──────────────┐
    │         │              │              │
┌───▼───┐ ┌──▼──────┐  ┌────▼─────┐  ┌────▼──────┐
│ Job   │ │ Job     │  │ LLM      │  │ Config    │
│Scraper│ │Normalizer│ │Integration│ │Service    │
│Service│ │Service  │  │Service   │  │           │
└───────┘ └─────────┘  └──────────┘  └───────────┘
    │         │              │
    │         │              │
    └─────────┴──────────────┘
              │
         ┌────▼─────┐
         │ External │
         │   APIs   │
         │ (LLM API)│
         └──────────┘
```

## Service Boundaries

### 1. **API Gateway Service** (`main.bal`)
- **Responsibility**: HTTP endpoint management, request routing, orchestration
- **Endpoints**:
  - `POST /api/jobs/analyze` - Submit job URL and get analysis
  - `GET /api/jobs/{id}` - Retrieve analysis result
  - `GET /api/health` - Health check

### 2. **Job Scraper Service** (`services/job_scraper.bal`)
- **Responsibility**: Web scraping of job postings from LinkedIn and company career pages
- **Input**: Job posting URL
- **Output**: Raw HTML/text content
- **Extensibility**: Plugin-based scraper for different job sites

### 3. **Job Normalizer Service** (`services/job_normalizer.bal`)
- **Responsibility**: Extract and structure job data from raw content
- **Input**: Raw scraped content
- **Output**: Structured `JobProfile` record
- **Extensibility**: Multiple normalization strategies per job site type

### 4. **LLM Integration Service** (`services/llm_service.bal`)
- **Responsibility**: Communication with external LLM API (OpenAI, Anthropic, etc.)
- **Input**: Structured `JobProfile`
- **Output**: `LearningRoadmap` and `InterviewGuide`
- **Extensibility**: Pluggable LLM providers

### 5. **Configuration Service** (`services/config.bal`)
- **Responsibility**: Centralized configuration management
- **Manages**: API keys, LLM provider settings, scraper configurations

## Data Flow

```
1. User submits job URL via React UI
   ↓
2. API Gateway receives POST /api/jobs/analyze
   ↓
3. API Gateway calls Job Scraper Service
   ↓
4. Job Scraper fetches and extracts content from URL
   ↓
5. API Gateway calls Job Normalizer Service
   ↓
6. Job Normalizer parses and structures data into JobProfile
   ↓
7. API Gateway calls LLM Integration Service
   ↓
8. LLM Service sends JobProfile to external LLM API
   ↓
9. LLM Service receives and parses response
   ↓
10. API Gateway returns complete analysis to frontend
```

## Data Models

### JobProfile
```ballerina
type JobProfile record {
    string title;
    string company;
    string location;
    string description;
    string[] requiredSkills;
    string[] preferredSkills;
    string[] responsibilities;
    string experienceLevel;
    string employmentType;
    decimal? salaryMin;
    decimal? salaryMax;
    string sourceUrl;
};
```

### LearningRoadmap
```ballerina
type LearningRoadmap record {
    string overview;
    LearningPath[] paths;
    string estimatedDuration;
    Resource[] resources;
};

type LearningPath record {
    string title;
    string description;
    string[] topics;
    int order;
};

type Resource record {
    string title;
    string url;
    string type; // "course", "article", "video", "book"
};
```

### InterviewGuide
```ballerina
type InterviewGuide record {
    string overview;
    Question[] commonQuestions;
    Question[] technicalQuestions;
    Tip[] preparationTips;
    string[] keyTopics;
};

type Question record {
    string question;
    string category;
    string[] sampleAnswers;
};

type Tip record {
    string title;
    string description;
};
```

## API Endpoints

### POST /api/jobs/analyze
**Request:**
```json
{
  "url": "https://linkedin.com/jobs/view/123456",
  "userId": "optional-user-id"
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
**Response:**
```json
{
  "jobId": "uuid-here",
  "status": "completed",
  "jobProfile": { ... },
  "learningRoadmap": { ... },
  "interviewGuide": { ... },
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### GET /api/health
**Response:**
```json
{
  "status": "healthy",
  "services": {
    "scraper": "available",
    "normalizer": "available",
    "llm": "available"
  }
}
```

## Extensibility Points

1. **Scraper Plugins**: Add new scrapers by implementing `Scraper` interface
2. **Normalizer Strategies**: Add site-specific normalizers
3. **LLM Providers**: Swap LLM providers via configuration
4. **Storage**: Add database layer for persistence (currently stateless)
5. **Authentication**: Add auth middleware at API Gateway level
6. **Caching**: Add caching layer for repeated job analyses

## Technology Stack

- **Backend**: Ballerina 2201.13.1
- **Frontend**: React 19.2.3
- **HTTP Client**: Ballerina `http` module
- **JSON Processing**: Ballerina `jsonutils` module
- **LLM API**: External (OpenAI, Anthropic, etc.)

## Configuration

Environment variables:
- `LLM_API_KEY`: API key for LLM provider
- `LLM_API_URL`: Base URL for LLM API
- `LLM_MODEL`: Model name (e.g., "gpt-4", "claude-3")
- `SCRAPER_TIMEOUT`: Timeout for web scraping (seconds)
- `API_PORT`: Port for API Gateway (default: 9090)


