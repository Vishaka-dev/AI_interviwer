// Job Scraper Service - Handles web scraping of job postings

import ballerina/http;
import ballerina/io;
import ballerina/lang.'string as strings;

// Helper function to replace string
function replaceStr(string text, string find, string replacement) returns string {
    string result = "";
    int i = 0;
    int textLen = text.length();
    int findLen = find.length();
    
    while i < textLen {
        if i + findLen <= textLen {
            string segment = text.substring(i, i + findLen);
            if segment == find {
                result = result + replacement;
                i = i + findLen;
                continue;
            }
        }
        result = result + text.substring(i, i + 1);
        i = i + 1;
    }
    return result;
}

// Extract base URL (protocol + domain) from full URL
function extractBaseUrlFromUrl(string url) returns string {
    int schemeEnd = 0;
    if url.startsWith("https://") {
        schemeEnd = 8;
    } else if url.startsWith("http://") {
        schemeEnd = 7;
    }
    
    string afterScheme = url.substring(schemeEnd);
    int? slashIndex = afterScheme.indexOf("/");
    if slashIndex is int {
        return url.substring(0, schemeEnd + slashIndex);
    }
    return url;
}

// Extract text content from HTML
function extractTextFromHtmlContent(string html) returns string {
    // Simple HTML text extraction
    string text = html;
    
    // Replace common HTML entities
    text = replaceStr(text, "&nbsp;", " ");
    text = replaceStr(text, "&amp;", "&");
    text = replaceStr(text, "&lt;", "<");
    text = replaceStr(text, "&gt;", ">");
    text = replaceStr(text, "&quot;", "\"");
    text = replaceStr(text, "&#39;", "'");
    
    // Basic tag removal - character by character
    string result = "";
    boolean inTag = false;
    foreach string:Char c in text {
        if c == "<" {
            inTag = true;
            result = result + " ";
        } else if c == ">" {
            inTag = false;
        } else if !inTag {
            result = result + c.toString();
        }
    }
    
    // Normalize whitespace
    while result.includes("  ") {
        result = replaceStr(result, "  ", " ");
    }
    
    return strings:trim(result);
}

// Public function to scrape job posting
public function scrapeJobPosting(string url) returns ScrapedContent|error {
    io:println("[Scraper] Fetching job: " + url);
    
    // Extract base URL
    string baseUrl = extractBaseUrlFromUrl(url);
    
    // Create HTTP client with timeout as decimal
    decimal timeout = <decimal>getScraperTimeout();
    http:Client httpClient = check new (baseUrl, {
        timeout: timeout
    });
    
    // Get path from URL
    string path = url.substring(baseUrl.length());
    if path == "" {
        path = "/";
    }
    
    // Set headers via client config isn't easily available, so we use inline approach
    map<string|string[]> headers = {
        "User-Agent": getUserAgent(),
        "Accept": "text/html,application/xhtml+xml"
    };
    
    http:Response response = check httpClient->get(path, headers);
    
    if response.statusCode != 200 {
        return error("Failed to fetch job posting: HTTP " + response.statusCode.toString());
    }
    
    string htmlContent = check response.getTextPayload();
    string extractedText = extractTextFromHtmlContent(htmlContent);
    
    // Determine source from URL
    string src = "generic";
    if url.includes("linkedin.com") {
        src = "linkedin";
    } else if url.includes("indeed.com") {
        src = "indeed";
    } else if url.includes("glassdoor.com") {
        src = "glassdoor";
    }
    
    return {
        rawHtml: htmlContent,
        extractedText: extractedText,
        sourceUrl: url,
        metadata: {
            "source": src,
            "statusCode": response.statusCode.toString()
        }
    };
}


