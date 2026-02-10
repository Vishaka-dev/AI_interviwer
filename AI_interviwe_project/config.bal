// Configuration service for managing environment variables and settings
// Uses Ballerina's modern configurable syntax for better type safety and flexibility

import ballerina/os;

// LLM Configuration (Google Gemini)
configurable string llmApiKey = ?;
configurable string llmApiUrl = "https://generativelanguage.googleapis.com";
configurable string llmModel = "gemini-1.5-flash";
configurable string llmProvider = "gemini"; // "gemini" or "openai"

// LLM Provider getter
public function getLlmProvider() returns string {
    string? envProvider = os:getEnv("LLM_PROVIDER");
    if envProvider is string && envProvider != "" {
        return envProvider;
    }
    return llmProvider;
}

// Scraper Configuration
configurable int scraperTimeout = 30;
configurable string scraperUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

// API Configuration
configurable int apiPort = 9090;
configurable string apiHost = "localhost";

// CORS Configuration
configurable string corsOrigins = "http://localhost:3000";

// LLM Configuration getters (with environment variable fallback)
public function getLlmApiKey() returns string {
    string? envKey = os:getEnv("LLM_API_KEY");
    if envKey is string && envKey != "" {
        return envKey;
    }
    return llmApiKey;
}

public function getLlmApiUrl() returns string {
    string? envUrl = os:getEnv("LLM_API_URL");
    if envUrl is string && envUrl != "" {
        return envUrl;
    }
    return llmApiUrl;
}

public function getLlmModel() returns string {
    string? envModel = os:getEnv("LLM_MODEL");
    if envModel is string && envModel != "" {
        return envModel;
    }
    return llmModel;
}

// Scraper Configuration getters
public function getScraperTimeout() returns int {
    string? envTimeout = os:getEnv("SCRAPER_TIMEOUT");
    if envTimeout is string {
        int|error timeout = int:fromString(envTimeout);
        if timeout is int {
            return timeout;
        }
    }
    return scraperTimeout;
}

public function getUserAgent() returns string {
    string? envUserAgent = os:getEnv("SCRAPER_USER_AGENT");
    if envUserAgent is string && envUserAgent != "" {
        return envUserAgent;
    }
    return scraperUserAgent;
}

// API Configuration getters
public function getApiPort() returns int {
    string? envPort = os:getEnv("API_PORT");
    if envPort is string {
        int|error port = int:fromString(envPort);
        if port is int {
            return port;
        }
    }
    return apiPort;
}

public function getApiHost() returns string {
    string? envHost = os:getEnv("API_HOST");
    if envHost is string && envHost != "" {
        return envHost;
    }
    return apiHost;
}

// CORS Configuration getter
public function getAllowedOrigins() returns string[] {
    string? envOrigins = os:getEnv("CORS_ORIGINS");
    string origins = envOrigins is string && envOrigins != "" ? envOrigins : corsOrigins;
    
    // Split by comma and trim whitespace
    string[] originList = re `,`.split(origins);
    string[] trimmedOrigins = [];
    foreach string origin in originList {
        string trimmed = origin.trim();
        if trimmed != "" {
            trimmedOrigins.push(trimmed);
        }
    }
    return trimmedOrigins;
}


