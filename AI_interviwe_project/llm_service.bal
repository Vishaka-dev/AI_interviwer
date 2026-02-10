// LLM Integration Service - Communicates with external LLM API

import ballerina/http;
import ballerina/io;
import ballerina/lang.value;

// Helper function to join strings with delimiter
function joinStrings(string[] arr, string delimiter) returns string {
    if arr.length() == 0 {
        return "";
    }
    string result = arr[0];
    int i = 1;
    while i < arr.length() {
        result = result + delimiter + arr[i];
        i = i + 1;
    }
    return result;
}

// Public functions to generate roadmap and interview guide
public function generateLearningRoadmap(JobProfile profile) returns LearningRoadmap|error {
    io:println("[LLM] Generating learning roadmap for: " + profile.title);
    
    string apiKey = getLlmApiKey();
    
    // If no API key, return mock data
    if apiKey == "" {
        io:println("[LLM] No API key configured, returning mock data");
        return getMockRoadmapData();
    }
    
    string apiUrl = getLlmApiUrl();
    string model = getLlmModel();
    
    // Create HTTP client
    http:Client httpClient = check new (apiUrl, {
        timeout: 60
    });
    
    // Build prompt
    string skillsList = joinStrings(profile.requiredSkills, ", ");
    string descPreview = profile.description.length() < 500 ? profile.description : profile.description.substring(0, 500);
    
    string prompt = string `Generate a personalized learning roadmap for a job position. 
        
Job Title: ${profile.title}
Company: ${profile.company}
Required Skills: ${skillsList}
Description: ${descPreview}

Please provide a structured learning roadmap in JSON format with the following structure:
{
  "overview": "Brief overview of the learning path",
  "paths": [
    {
      "title": "Path name",
      "description": "Description",
      "topics": ["topic1", "topic2"],
      "orderNum": 1,
      "estimatedTime": "2 weeks"
    }
  ],
  "estimatedDuration": "Total estimated time",
  "resources": [
    {
      "title": "Resource name",
      "url": "https://example.com",
      "resourceType": "course",
      "description": "Brief description"
    }
  ]
}`;
    
    // Call LLM
    json|error responseJson = callLlmApi(httpClient, apiKey, model, prompt);
    if responseJson is error {
        io:println("[LLM] API call failed, returning mock data: " + responseJson.message());
        return getMockRoadmapData();
    }
    
    // Parse response
    return parseRoadmapResponse(responseJson);
}

public function generateInterviewGuide(JobProfile profile) returns InterviewGuide|error {
    io:println("[LLM] Generating interview guide for: " + profile.title);
    
    string apiKey = getLlmApiKey();
    
    // If no API key, return mock data
    if apiKey == "" {
        io:println("[LLM] No API key configured, returning mock data");
        return getMockInterviewGuideData();
    }
    
    string apiUrl = getLlmApiUrl();
    string model = getLlmModel();
    
    // Create HTTP client
    http:Client httpClient = check new (apiUrl, {
        timeout: 60
    });
    
    // Build prompt
    string skillsList = joinStrings(profile.requiredSkills, ", ");
    string expLevel = profile.experienceLevel ?: "Not specified";
    
    string prompt = string `Generate an interview preparation guide for this job position.
        
Job Title: ${profile.title}
Company: ${profile.company}
Required Skills: ${skillsList}
Experience Level: ${expLevel}

Please provide a comprehensive interview guide in JSON format:
{
  "overview": "Overview of interview preparation",
  "commonQuestions": [
    {
      "question": "Question text",
      "category": "technical",
      "sampleAnswers": ["answer1"],
      "difficulty": "medium"
    }
  ],
  "technicalQuestions": [
    {
      "question": "Technical question",
      "category": "technical",
      "difficulty": "medium"
    }
  ],
  "preparationTips": [
    {
      "title": "Tip title",
      "description": "Tip description",
      "category": "general"
    }
  ],
  "keyTopics": ["topic1", "topic2"]
}`;
    
    // Call LLM
    json|error responseJson = callLlmApi(httpClient, apiKey, model, prompt);
    if responseJson is error {
        io:println("[LLM] API call failed, returning mock data: " + responseJson.message());
        return getMockInterviewGuideData();
    }
    
    // Parse response
    return parseInterviewGuideResponse(responseJson);
}

// Call LLM API (supports Groq, Gemini and OpenAI)
function callLlmApi(http:Client httpClient, string apiKey, string model, string prompt) returns json|error {
    string provider = getLlmProvider();
    
    if provider == "gemini" {
        return callGeminiApi(httpClient, apiKey, model, prompt);
    } else {
        // Both Groq and OpenAI use the same API format
        return callOpenAiApi(httpClient, apiKey, model, prompt);
    }
}

// Call Google Gemini API
function callGeminiApi(http:Client httpClient, string apiKey, string model, string prompt) returns json|error {
    string systemPrompt = "You are a helpful career advisor and technical interview coach. Provide structured, actionable advice. IMPORTANT: Return ONLY valid JSON, no markdown code blocks, no explanations before or after the JSON.";
    string fullPrompt = systemPrompt + "\n\n" + prompt;
    
    json requestPayload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": fullPrompt
                    }
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 2000
        }
    };
    
    string endpoint = "/v1beta/models/" + model + ":generateContent?key=" + apiKey;
    
    map<string|string[]> headers = {
        "Content-Type": "application/json"
    };
    
    io:println("[LLM] Calling Gemini API: " + model);
    http:Response response = check httpClient->post(endpoint, requestPayload, headers);
    
    if response.statusCode != 200 {
        string errorBody = check response.getTextPayload();
        io:println("[LLM] Gemini error response: " + errorBody);
        return error("Gemini API error: HTTP " + response.statusCode.toString() + " - " + errorBody);
    }
    
    json responseBody = check response.getJsonPayload();
    io:println("[LLM] Gemini response received");
    
    // Extract content from Gemini response format
    json|error candidatesResult = responseBody.candidates;
    if candidatesResult is error {
        return error("No candidates in Gemini response");
    }
    
    json[] candidates = [];
    if candidatesResult is json[] {
        candidates = candidatesResult;
    } else {
        return error("Invalid candidates format");
    }
    
    if candidates.length() == 0 {
        return error("No candidates in response");
    }
    
    json|error contentResult = candidates[0].content;
    if contentResult is error {
        return error("No content in candidate");
    }
    
    json|error partsResult = contentResult.parts;
    if partsResult is error {
        return error("No parts in content");
    }
    
    json[] parts = [];
    if partsResult is json[] {
        parts = partsResult;
    } else {
        return error("Invalid parts format");
    }
    
    if parts.length() == 0 {
        return error("No parts in response");
    }
    
    json|error textResult = parts[0].text;
    if textResult is error {
        return error("No text in part");
    }
    
    string content = "";
    if textResult is string {
        content = textResult;
    } else {
        return error("Invalid text type");
    }
    
    // Clean up the response - remove markdown code blocks if present
    content = cleanJsonResponse(content);
    
    // Try to parse JSON from content
    json|error parsedContent = value:fromJsonString(content);
    if parsedContent is error {
        io:println("[LLM] Failed to parse Gemini JSON response: " + parsedContent.message());
        io:println("[LLM] Raw content: " + content);
        return error("Failed to parse JSON from Gemini response");
    }
    return parsedContent;
}

// Clean JSON response from markdown code blocks
function cleanJsonResponse(string content) returns string {
    string cleaned = content.trim();
    
    // Remove ```json prefix
    if cleaned.startsWith("```json") {
        cleaned = cleaned.substring(7);
    } else if cleaned.startsWith("```") {
        cleaned = cleaned.substring(3);
    }
    
    // Remove ``` suffix
    if cleaned.endsWith("```") {
        cleaned = cleaned.substring(0, cleaned.length() - 3);
    }
    
    return cleaned.trim();
}

// Call OpenAI API
function callOpenAiApi(http:Client httpClient, string apiKey, string model, string prompt) returns json|error {
    json requestPayload = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful career advisor and technical interview coach. Provide structured, actionable advice in JSON format."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 0.7,
        "max_tokens": 2000
    };
    
    map<string|string[]> headers = {
        "Authorization": "Bearer " + apiKey,
        "Content-Type": "application/json"
    };
    
    http:Response response = check httpClient->post("/chat/completions", requestPayload, headers);
    
    if response.statusCode != 200 {
        string errorBody = check response.getTextPayload();
        io:println("[LLM] Error response: " + errorBody);
        return error("LLM API error: HTTP " + response.statusCode.toString());
    }
    
    json responseBody = check response.getJsonPayload();
    
    // Extract content from OpenAI response format
    json|error choicesResult = responseBody.choices;
    if choicesResult is error {
        return error("No choices in response");
    }
    
    json[] choices = [];
    if choicesResult is json[] {
        choices = choicesResult;
    } else {
        return error("Invalid choices format");
    }
    
    if choices.length() == 0 {
        return error("No response from LLM");
    }
    
    json|error messageResult = choices[0].message;
    if messageResult is error {
        return error("No message in response");
    }
    
    json|error contentResult = messageResult.content;
    if contentResult is error {
        return error("No content in response");
    }
    
    string content = "";
    if contentResult is string {
        content = contentResult;
    } else {
        return error("Invalid content type");
    }
    
    // Try to parse JSON from content
    json|error parsedContent = value:fromJsonString(content);
    if parsedContent is error {
        io:println("[LLM] Failed to parse JSON response, returning raw content");
        return {"rawContent": content};
    }
    return parsedContent;
}

// Parse roadmap response
function parseRoadmapResponse(json response) returns LearningRoadmap|error {
    // Check for mock indicator
    if response is map<json> {
        json|error mockVal = response.mock;
        if !(mockVal is error) && mockVal == true {
            return getMockRoadmapData();
        }
    }
    
    // Parse actual LLM response
    json|error overviewResult = response.overview;
    string overview = overviewResult is string ? overviewResult : "Learning roadmap for this position";
    
    json|error pathsResult = response.paths;
    LearningPath[] paths = [];
    
    if pathsResult is json[] {
        foreach json pathJson in pathsResult {
            json|error titleRes = pathJson.title;
            json|error descRes = pathJson.description;
            json|error topicsRes = pathJson.topics;
            json|error orderRes = pathJson.orderNum;
            json|error timeRes = pathJson.estimatedTime;
            
            string[] topics = [];
            if topicsRes is json[] {
                foreach json t in topicsRes {
                    if t is string {
                        topics.push(t);
                    }
                }
            }
            
            LearningPath path = {
                title: titleRes is string ? titleRes : "Learning Path",
                description: descRes is string ? descRes : "Description not available",
                topics: topics,
                orderNum: orderRes is int ? orderRes : 1,
                estimatedTime: timeRes is string ? timeRes : ()
            };
            paths.push(path);
        }
    }
    
    // Parse resources if available
    json|error resourcesResult = response.resources;
    Resource[]? resources = ();
    if resourcesResult is json[] {
        Resource[] resList = [];
        foreach json resJson in resourcesResult {
            json|error titleRes = resJson.title;
            json|error urlRes = resJson.url;
            json|error typeRes = resJson.resourceType;
            json|error descRes = resJson.description;
            
            Resource res = {
                title: titleRes is string ? titleRes : "Resource",
                url: urlRes is string ? urlRes : "#",
                resourceType: typeRes is string ? typeRes : "other",
                description: descRes is string ? descRes : ()
            };
            resList.push(res);
        }
        resources = resList;
    }
    
    json|error durationResult = response.estimatedDuration;
    
    return {
        overview: overview,
        paths: paths,
        estimatedDuration: durationResult is string ? durationResult : (),
        resources: resources
    };
}

// Parse interview guide response
function parseInterviewGuideResponse(json response) returns InterviewGuide|error {
    // Check for mock indicator
    if response is map<json> {
        json|error mockVal = response.mock;
        if !(mockVal is error) && mockVal == true {
            return getMockInterviewGuideData();
        }
    }
    
    // Parse actual LLM response
    json|error overviewResult = response.overview;
    string overview = overviewResult is string ? overviewResult : "Interview preparation guide";
    
    // Parse common questions
    json|error commonResult = response.commonQuestions;
    Question[] commonQuestions = [];
    if commonResult is json[] {
        foreach json qJson in commonResult {
            Question q = parseQuestionJson(qJson);
            commonQuestions.push(q);
        }
    }
    
    // Parse technical questions
    json|error techResult = response.technicalQuestions;
    Question[] technicalQuestions = [];
    if techResult is json[] {
        foreach json qJson in techResult {
            Question q = parseQuestionJson(qJson);
            technicalQuestions.push(q);
        }
    }
    
    // Parse tips
    json|error tipsResult = response.preparationTips;
    Tip[] tips = [];
    if tipsResult is json[] {
        foreach json tipJson in tipsResult {
            json|error titleRes = tipJson.title;
            json|error descRes = tipJson.description;
            json|error catRes = tipJson.category;
            
            Tip tip = {
                title: titleRes is string ? titleRes : "Tip",
                description: descRes is string ? descRes : "Description",
                category: catRes is string ? catRes : ()
            };
            tips.push(tip);
        }
    }
    
    // Parse key topics
    json|error topicsResult = response.keyTopics;
    string[] keyTopics = [];
    if topicsResult is json[] {
        foreach json t in topicsResult {
            if t is string {
                keyTopics.push(t);
            }
        }
    }
    
    return {
        overview: overview,
        commonQuestions: commonQuestions,
        technicalQuestions: technicalQuestions,
        preparationTips: tips,
        keyTopics: keyTopics,
        behavioralQuestions: ()
    };
}

// Parse question from JSON
function parseQuestionJson(json qJson) returns Question {
    json|error questionRes = qJson.question;
    json|error categoryRes = qJson.category;
    json|error answersRes = qJson.sampleAnswers;
    json|error diffRes = qJson.difficulty;
    
    string[]? sampleAnswers = ();
    if answersRes is json[] {
        string[] answers = [];
        foreach json a in answersRes {
            if a is string {
                answers.push(a);
            }
        }
        if answers.length() > 0 {
            sampleAnswers = answers;
        }
    }
    
    return {
        question: questionRes is string ? questionRes : "Question",
        category: categoryRes is string ? categoryRes : "general",
        sampleAnswers: sampleAnswers,
        difficulty: diffRes is string ? diffRes : ()
    };
}

// Get mock roadmap data
function getMockRoadmapData() returns LearningRoadmap {
    return {
        overview: "This is a mock learning roadmap. Configure LLM_API_KEY environment variable to get AI-generated content.",
        paths: [
            {
                title: "Core Skills",
                description: "Master the fundamental skills required for this position",
                topics: ["Programming fundamentals", "Data structures", "Algorithms"],
                orderNum: 1,
                estimatedTime: "4 weeks"
            },
            {
                title: "Advanced Topics",
                description: "Deep dive into advanced concepts",
                topics: ["System design", "Architecture patterns", "Performance optimization"],
                orderNum: 2,
                estimatedTime: "6 weeks"
            }
        ],
        estimatedDuration: "10 weeks",
        resources: [
            {
                title: "Example Course",
                url: "https://example.com/course",
                resourceType: "course",
                description: "A comprehensive course on the topic"
            }
        ]
    };
}

// Get mock interview guide data
function getMockInterviewGuideData() returns InterviewGuide {
    return {
        overview: "This is a mock interview guide. Configure LLM_API_KEY environment variable to get AI-generated content.",
        commonQuestions: [
            {
                question: "Tell me about yourself",
                category: "behavioral",
                sampleAnswers: ["Sample answer here"],
                difficulty: "easy"
            }
        ],
        technicalQuestions: [
            {
                question: "Explain the difference between REST and GraphQL",
                category: "technical",
                sampleAnswers: (),
                difficulty: "medium"
            }
        ],
        preparationTips: [
            {
                title: "Practice Coding",
                description: "Regular practice on coding platforms",
                category: "technical"
            }
        ],
        keyTopics: ["Algorithms", "Data Structures", "System Design"],
        behavioralQuestions: ()
    };
}

