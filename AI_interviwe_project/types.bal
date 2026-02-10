// Data models for the AI Interviewer system

// Job Profile - Normalized job posting data
public type JobProfile record {
    string title;
    string company;
    string? location;
    string description;
    string[] requiredSkills;
    string[] preferredSkills;
    string[]? responsibilities;
    string? experienceLevel;
    string? employmentType;
    decimal? salaryMin;
    decimal? salaryMax;
    string sourceUrl;
    map<string>? metadata;
};

// Learning Roadmap - Generated learning path
public type LearningRoadmap record {
    string overview;
    LearningPath[] paths;
    string? estimatedDuration;
    Resource[]? resources;
};

public type LearningPath record {
    string title;
    string description;
    string[] topics;
    int orderNum;
    string? estimatedTime;
};

public type Resource record {
    string title;
    string url;
    string resourceType; // "course", "article", "video", "book", "practice"
    string? description;
};

// Interview Guide - Generated interview preparation guide
public type InterviewGuide record {
    string overview;
    Question[] commonQuestions;
    Question[] technicalQuestions;
    Tip[] preparationTips;
    string[] keyTopics;
    string[]? behavioralQuestions;
};

public type Question record {
    string question;
    string category; // "technical", "behavioral", "system-design", etc.
    string[]? sampleAnswers;
    string? difficulty; // "easy", "medium", "hard"
};

public type Tip record {
    string title;
    string description;
    string? category;
};

// Analysis Result - Complete analysis response
public type AnalysisResult record {
    string jobId;
    string status; // "processing", "completed", "failed"
    JobProfile? jobProfile;
    LearningRoadmap? learningRoadmap;
    InterviewGuide? interviewGuide;
    string? errorMessage;
    string createdAt;
    string? completedAt;
};

// Request/Response types
public type AnalyzeRequest record {
    string url;
    string? userId;
};

public type AnalyzeResponse record {
    string jobId;
    string status;
    string message;
};

public type HealthResponse record {
    string status;
    map<string> services;
};

// Scraper result
public type ScrapedContent record {
    string rawHtml;
    string extractedText;
    string sourceUrl;
    map<string>? metadata;
};

