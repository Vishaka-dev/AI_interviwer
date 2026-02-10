// Main API Gateway Service - Orchestrates all services

import ballerina/http;
import ballerina/uuid;
import ballerina/time;
import ballerina/io;
import ballerina/lang.'string as strings;

// In-memory storage for analysis results (in production, use a database)
map<AnalysisResult> analysisResults = {};

// Rate limiting: track requests per IP (simple implementation)
map<RateLimitEntry> rateLimitMap = {};
const int MAX_REQUESTS_PER_MINUTE = 10;
const int RATE_LIMIT_WINDOW_SECONDS = 60;

// Allowed job posting domains for URL validation
final string[] ALLOWED_DOMAINS = [
    "linkedin.com",
    "indeed.com",
    "glassdoor.com",
    "greenhouse.io",
    "lever.co",
    "workday.com",
    "jobs.lever.co",
    "boards.greenhouse.io"
];

type RateLimitEntry record {
    int requestCount;
    time:Utc windowStart;
};

// HTTP service for API Gateway with CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "http://127.0.0.1:3000"],
        allowCredentials: true,
        allowMethods: ["GET", "POST", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization", "Origin", "Accept"],
        maxAge: 86400
    }
}
service /api on new http:Listener(getApiPort()) {
    
    // Health check endpoint
    resource function get health() returns HealthResponse {
        return {
            status: "healthy",
            services: {
                "scraper": "available",
                "normalizer": "available",
                "llm": "available"
            }
        };
    }
    
    // Analyze job posting endpoint
    resource function post jobs/analyze(http:Request req) returns http:Response|http:InternalServerError {
        // Get client IP for rate limiting
        string|http:HeaderNotFoundError headerResult = req.getHeader("X-Forwarded-For");
        string clientIp = headerResult is string ? headerResult : "unknown";
        
        // Check rate limit
        if !checkRateLimit(clientIp) {
            return createErrorResponse(429, "Too many requests. Please wait before trying again.");
        }
        
        // Parse request
        json|error requestJson = req.getJsonPayload();
        if requestJson is error {
            return createErrorResponse(400, "Invalid JSON payload. Please send a valid JSON object.");
        }
        
        // Extract fields from JSON
        string url = "";
        string jobDescription = "";
        
        if requestJson is map<json> {
            json? urlJson = requestJson["url"];
            if urlJson is string {
                url = strings:trim(urlJson);
            }
            
            json? descJson = requestJson["jobDescription"];
            if descJson is string {
                jobDescription = strings:trim(descJson);
            }
        }
        
        // Check if using paste mode (job description provided)
        boolean isPasteMode = jobDescription != "" && url == "manual-input";
        
        if !isPasteMode {
            // URL mode validation
            if url == "" {
                return createErrorResponse(400, "URL is required. Please provide a job posting URL or paste the job description.");
            }
            
            // Validate URL format
            ValidationResult urlValidation = validateJobUrl(url);
            if !urlValidation.isValid {
                return createErrorResponse(400, urlValidation.message);
            }
            
            // Sanitize URL
            url = sanitizeUrl(url);
        } else {
            // Paste mode validation
            if jobDescription.length() < 100 {
                return createErrorResponse(400, "Job description is too short. Please provide a complete job posting.");
            }
            if jobDescription.length() > 50000 {
                return createErrorResponse(400, "Job description is too long. Maximum 50,000 characters allowed.");
            }
            // Sanitize job description
            jobDescription = sanitizeText(jobDescription);
        }
        
        // Generate job ID
        string jobId = uuid:createType1AsString();
        
        // Create initial analysis result
        AnalysisResult result = {
            jobId: jobId,
            status: "processing",
            createdAt: time:utcToString(time:utcNow()),
            jobProfile: (),
            learningRoadmap: (),
            interviewGuide: (),
            errorMessage: (),
            completedAt: ()
        };
        analysisResults[jobId] = result;
        
        // Process asynchronously based on input mode
        if isPasteMode {
            future<()> _ = start processJobAnalysisFromDescription(jobId, jobDescription);
        } else {
            future<()> _ = start processJobAnalysis(jobId, url);
        }
        
        // Return immediate response
        AnalyzeResponse response = {
            jobId: jobId,
            status: "processing",
            message: "Job analysis started. Use GET /api/jobs/" + jobId + " to check status."
        };
        
        http:Response httpResponse = new;
        httpResponse.setJsonPayload(<json>response);
        httpResponse.setHeader("Content-Type", "application/json");
        addCorsHeaders(httpResponse);
        return httpResponse;
    }
    
    // Get analysis result endpoint
    resource function get jobs/[string jobId]() returns http:Response|http:NotFound {
        if !analysisResults.hasKey(jobId) {
            return createErrorResponse(404, "Job analysis not found");
        }
        
        AnalysisResult? resultOpt = analysisResults[jobId];
        if resultOpt is () {
            return createErrorResponse(404, "Job analysis not found");
        }
        AnalysisResult result = <AnalysisResult>resultOpt;
        
        http:Response response = new;
        response.setJsonPayload(<json>result);
        response.setHeader("Content-Type", "application/json");
        addCorsHeaders(response);
        return response;
    }
    
    // Handle OPTIONS requests for CORS - root path
    resource function options .(http:Request req) returns http:Response {
        http:Response response = new;
        addCorsHeaders(response);
        return response;
    }

    // Handle OPTIONS requests for CORS - jobs/analyze path
    resource function options jobs/analyze(http:Request req) returns http:Response {
        http:Response response = new;
        addCorsHeaders(response);
        return response;
    }

    // Handle OPTIONS requests for CORS - jobs/{jobId} path
    resource function options jobs/[string jobId](http:Request req) returns http:Response {
        http:Response response = new;
        addCorsHeaders(response);
        return response;
    }
}

// Async function to process job analysis from URL
function processJobAnalysis(string jobId, string url) {
    io:println("[API Gateway] Starting analysis for job: " + jobId);
    
    AnalysisResult? resultOpt = analysisResults[jobId];
    if resultOpt is () {
        io:println("[API Gateway] Job ID not found: " + jobId);
        return;
    }
    AnalysisResult result = <AnalysisResult>resultOpt;
    result.status = "processing";
    
    // Step 1: Scrape job posting
    ScrapedContent|error scrapedContent = scrapeJobPosting(url);
    if scrapedContent is error {
        io:println("[API Gateway] Scraping failed: " + scrapedContent.message());
        result.status = "failed";
        result.errorMessage = "Failed to fetch job posting. Please try pasting the job description directly.";
        result.completedAt = time:utcToString(time:utcNow());
        return;
    }
    
    // Step 2: Normalize job data
    JobProfile|error jobProfile = normalizeJobPosting(scrapedContent);
    if jobProfile is error {
        io:println("[API Gateway] Normalization failed: " + jobProfile.message());
        result.status = "failed";
        result.errorMessage = "Failed to parse job data. Please try pasting the job description directly.";
        result.completedAt = time:utcToString(time:utcNow());
        return;
    }
    
    // Continue with common processing
    processJobProfileAnalysis(result, jobProfile, jobId);
}

// Async function to process job analysis from pasted description
function processJobAnalysisFromDescription(string jobId, string description) {
    io:println("[API Gateway] Starting analysis from pasted description for job: " + jobId);
    
    AnalysisResult? resultOpt = analysisResults[jobId];
    if resultOpt is () {
        io:println("[API Gateway] Job ID not found: " + jobId);
        return;
    }
    AnalysisResult result = <AnalysisResult>resultOpt;
    result.status = "processing";
    
    // Create scraped content from pasted description
    ScrapedContent scrapedContent = {
        rawHtml: "",
        extractedText: description,
        sourceUrl: "manual-input",
        metadata: {
            "source": "manual",
            "inputType": "pasted"
        }
    };
    
    // Normalize job data
    JobProfile|error jobProfile = normalizeJobPosting(scrapedContent);
    if jobProfile is error {
        io:println("[API Gateway] Normalization failed: " + jobProfile.message());
        result.status = "failed";
        result.errorMessage = "Failed to parse job description. Please ensure it contains job title, company, and requirements.";
        result.completedAt = time:utcToString(time:utcNow());
        return;
    }
    
    // Continue with common processing
    processJobProfileAnalysis(result, jobProfile, jobId);
}

// Common function to process job profile (generate roadmap and guide)
function processJobProfileAnalysis(AnalysisResult result, JobProfile jobProfile, string jobId) {
    result.jobProfile = jobProfile;
    
    // Step 3: Generate learning roadmap
    LearningRoadmap|error roadmap = generateLearningRoadmap(jobProfile);
    if roadmap is error {
        io:println("[API Gateway] Roadmap generation failed: " + roadmap.message());
        // Continue even if roadmap fails
    } else {
        result.learningRoadmap = roadmap;
    }
    
    // Step 4: Generate interview guide
    InterviewGuide|error guide = generateInterviewGuide(jobProfile);
    if guide is error {
        io:println("[API Gateway] Guide generation failed: " + guide.message());
        // Continue even if guide fails
    } else {
        result.interviewGuide = guide;
    }
    
    // Mark as completed
    result.status = "completed";
    result.completedAt = time:utcToString(time:utcNow());
    
    io:println("[API Gateway] Analysis completed for job: " + jobId);
}

// Helper function to create error responses
function createErrorResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    json errorPayload = {
        "error": message,
        "statusCode": statusCode
    };
    response.setJsonPayload(errorPayload);
    response.setHeader("Content-Type", "application/json");
    addCorsHeaders(response);
    return response;
}

// Helper function to add CORS headers
function addCorsHeaders(http:Response response, string? requestOrigin = ()) {
    string[] allowedOrigins = getAllowedOrigins();
    
    // Check if request origin is in allowed list
    if requestOrigin is string {
        foreach string origin in allowedOrigins {
            if strings:equalsIgnoreCaseAscii(strings:trim(origin), strings:trim(requestOrigin)) {
                response.setHeader("Access-Control-Allow-Origin", requestOrigin);
                response.setHeader("Access-Control-Allow-Credentials", "true");
                break;
            }
        }
    } else if allowedOrigins.length() > 0 {
        // Fallback to first origin for non-browser requests
        response.setHeader("Access-Control-Allow-Origin", allowedOrigins[0]);
    }
    
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
    response.setHeader("Access-Control-Max-Age", "86400");
}

// URL validation result type
type ValidationResult record {
    boolean isValid;
    string message;
};

// Validate job posting URL
function validateJobUrl(string url) returns ValidationResult {
    // Check basic URL format using string operations
    string lowerUrl = url.toLowerAscii();
    
    // Must start with http:// or https://
    if !lowerUrl.startsWith("http://") && !lowerUrl.startsWith("https://") {
        return {
            isValid: false,
            message: "Invalid URL format. URL must start with http:// or https://"
        };
    }
    
    // Check if URL is from an allowed domain
    boolean isAllowedDomain = false;
    
    foreach string domain in ALLOWED_DOMAINS {
        if lowerUrl.includes(domain) {
            isAllowedDomain = true;
            break;
        }
    }
    
    if !isAllowedDomain {
        return {
            isValid: false,
            message: "URL domain not supported. Supported job sites: LinkedIn, Indeed, Glassdoor, Greenhouse, Lever, Workday."
        };
    }
    
    // Check URL length to prevent abuse
    if url.length() > 2048 {
        return {
            isValid: false,
            message: "URL is too long. Maximum length is 2048 characters."
        };
    }
    
    return {
        isValid: true,
        message: "Valid URL"
    };
}

// Sanitize URL to prevent injection attacks  
function sanitizeUrl(string url) returns string {
    // Remove any potentially harmful characters using character-by-character approach
    string sanitized = "";
    foreach string:Char c in url {
        // Skip harmful characters: < > " ' `
        if c != "<" && c != ">" && c != "\"" && c != "'" && c != "`" {
            sanitized = sanitized + c.toString();
        }
    }
    return sanitized.trim();
}

// Sanitize text input to prevent injection attacks
function sanitizeText(string text) returns string {
    // Remove javascript: protocol by simple replacement
    string sanitized = text;
    // Loop to remove all occurrences
    while sanitized.toLowerAscii().includes("javascript:") {
        int? idx = sanitized.toLowerAscii().indexOf("javascript:");
        if idx is int {
            sanitized = sanitized.substring(0, idx) + sanitized.substring(idx + 11);
        } else {
            break;
        }
    }
    return sanitized;
}

// Rate limiting check
function checkRateLimit(string clientIp) returns boolean {
    time:Utc now = time:utcNow();
    
    if rateLimitMap.hasKey(clientIp) {
        RateLimitEntry? entryOpt = rateLimitMap[clientIp];
        if entryOpt is RateLimitEntry {
            // Check if window has expired
            time:Seconds diff = time:utcDiffSeconds(now, entryOpt.windowStart);
            
            if diff > <decimal>RATE_LIMIT_WINDOW_SECONDS {
                // Reset window
                rateLimitMap[clientIp] = {
                    requestCount: 1,
                    windowStart: now
                };
                return true;
            }
            
            // Check if within limit
            if entryOpt.requestCount >= MAX_REQUESTS_PER_MINUTE {
                io:println("[Rate Limit] Client " + clientIp + " exceeded rate limit");
                return false;
            }
            
            // Increment counter
            entryOpt.requestCount += 1;
            rateLimitMap[clientIp] = entryOpt;
            return true;
        }
    }
    
    // New client
    rateLimitMap[clientIp] = {
        requestCount: 1,
        windowStart: now
    };
    return true;
}

