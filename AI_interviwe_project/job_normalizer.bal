// Job Normalizer Service - Extracts and structures job data from raw content

import ballerina/io;
import ballerina/lang.'string as strings;

// Helper function to split string by newline
function splitByNewline(string text) returns string[] {
    string[] result = [];
    string current = "";
    
    foreach string:Char c in text {
        if c == "\n" {
            result.push(current);
            current = "";
        } else if c != "\r" {
            current = current + c.toString();
        }
    }
    
    if current != "" {
        result.push(current);
    }
    
    return result;
}

// Extract title from text
function extractTitleFromText(string text, string url) returns string {
    // Look for title patterns in text
    string lowerText = text.toLowerAscii();
    
    // Try to extract from URL first (look for jobs/view/ or jobs/ patterns)
    if url.includes("jobs/view/") {
        int? viewIndex = url.indexOf("jobs/view/");
        if viewIndex is int {
            string afterView = url.substring(viewIndex + 10);
            int? endSlash = afterView.indexOf("/");
            int? endQuestion = afterView.indexOf("?");
            int endIndex = afterView.length();
            if endSlash is int && endSlash < endIndex {
                endIndex = endSlash;
            }
            if endQuestion is int && endQuestion < endIndex {
                endIndex = endQuestion;
            }
            if endIndex > 0 {
                // Replace dashes with spaces
                string extracted = afterView.substring(0, endIndex < 100 ? endIndex : 100);
                string titleResult = "";
                foreach string:Char c in extracted {
                    if c == "-" {
                        titleResult = titleResult + " ";
                    } else {
                        titleResult = titleResult + c.toString();
                    }
                }
                if titleResult.length() > 0 {
                    return strings:trim(titleResult);
                }
            }
        }
    }
    
    // Fallback: look for common title patterns (ordered from most specific to least)
    // Network/Infrastructure roles
    if lowerText.includes("network engineer") {
        return "Network Engineer";
    } else if lowerText.includes("senior network") {
        return "Senior Network Engineer";
    } else if lowerText.includes("network administrator") {
        return "Network Administrator";
    } else if lowerText.includes("network architect") {
        return "Network Architect";
    } else if lowerText.includes("systems engineer") {
        return "Systems Engineer";
    } else if lowerText.includes("infrastructure engineer") {
        return "Infrastructure Engineer";
    } else if lowerText.includes("cloud engineer") {
        return "Cloud Engineer";
    } else if lowerText.includes("security engineer") {
        return "Security Engineer";
    } else if lowerText.includes("cybersecurity") {
        return "Cybersecurity Engineer";
    // DevOps/SRE roles
    } else if lowerText.includes("devops") {
        return "DevOps Engineer";
    } else if lowerText.includes("site reliability") || lowerText.includes("sre") {
        return "Site Reliability Engineer";
    // Software engineering roles
    } else if lowerText.includes("senior software") {
        return "Senior Software Engineer";
    } else if lowerText.includes("software engineer") {
        return "Software Engineer";
    } else if lowerText.includes("frontend developer") || lowerText.includes("front-end developer") || lowerText.includes("front end developer") {
        return "Frontend Developer";
    } else if lowerText.includes("backend developer") || lowerText.includes("back-end developer") || lowerText.includes("back end developer") {
        return "Backend Developer";
    } else if lowerText.includes("full stack") || lowerText.includes("fullstack") || lowerText.includes("full-stack") {
        return "Full Stack Developer";
    // Data roles
    } else if lowerText.includes("data engineer") {
        return "Data Engineer";
    } else if lowerText.includes("data scientist") {
        return "Data Scientist";
    } else if lowerText.includes("data analyst") {
        return "Data Analyst";
    } else if lowerText.includes("machine learning") || lowerText.includes("ml engineer") {
        return "Machine Learning Engineer";
    // Other roles
    } else if lowerText.includes("architect") {
        return "Software Architect";
    } else if lowerText.includes("developer") {
        return "Developer";
    } else if lowerText.includes("engineer") {
        return "Engineer";
    }
    
    return "Professional Position"; // Generic fallback
}

// Extract company from text
function extractCompanyFromText(string text, string url) returns string {
    // Try to extract from URL (look for company/ pattern)
    if url.includes("company/") {
        int? companyIndex = url.indexOf("company/");
        if companyIndex is int {
            string afterCompany = url.substring(companyIndex + 8);
            int? endSlash = afterCompany.indexOf("/");
            int? endQuestion = afterCompany.indexOf("?");
            int endIndex = afterCompany.length();
            if endSlash is int && endSlash < endIndex {
                endIndex = endSlash;
            }
            if endQuestion is int && endQuestion < endIndex {
                endIndex = endQuestion;
            }
            if endIndex > 0 {
                string extracted = afterCompany.substring(0, endIndex < 50 ? endIndex : 50);
                string companyResult = "";
                foreach string:Char c in extracted {
                    if c == "-" {
                        companyResult = companyResult + " ";
                    } else {
                        companyResult = companyResult + c.toString();
                    }
                }
                if companyResult.length() > 0 {
                    return strings:trim(companyResult);
                }
            }
        }
    }
    
    // Look for "at Company" patterns
    if text.includes(" at ") {
        int? atIndex = text.indexOf(" at ");
        if atIndex is int {
            string afterAt = text.substring(atIndex + 4);
            int? endSpace = afterAt.indexOf(" ");
            int endIndex = endSpace is int ? endSpace : afterAt.length();
            if endIndex > 0 {
                return strings:trim(afterAt.substring(0, endIndex < 50 ? endIndex : 50));
            }
        }
    }
    
    return "Unknown Company";
}

// Extract location from text
function extractLocationFromText(string text) returns string? {
    string lowerText = text.toLowerAscii();
    if lowerText.includes("remote") {
        return "Remote";
    } else if lowerText.includes("hybrid") {
        return "Hybrid";
    } else if lowerText.includes("onsite") || lowerText.includes("on-site") {
        return "Onsite";
    }
    return ();
}

// Extract description from text
function extractDescriptionFromText(string text) returns string {
    // Return first 2000 characters as description
    if text.length() > 2000 {
        return text.substring(0, 2000) + "...";
    }
    return text;
}

// Extract skills from text
function extractSkillsFromText(string text) returns string[] {
    string[] skills = [];
    string lowerText = text.toLowerAscii();
    
    // Common tech skills mapping [search term, display name]
    string[][] skillMappings = [
        ["javascript", "JavaScript"],
        ["typescript", "TypeScript"],
        ["python", "Python"],
        ["java ", "Java"],
        [" java", "Java"],
        ["c++", "C++"],
        ["golang", "Go"],
        [" go ", "Go"],
        ["rust", "Rust"],
        ["react", "React"],
        ["angular", "Angular"],
        ["vue.js", "Vue.js"],
        ["vue ", "Vue.js"],
        ["node.js", "Node.js"],
        ["nodejs", "Node.js"],
        ["spring", "Spring"],
        ["django", "Django"],
        ["flask", "Flask"],
        [".net", ".NET"],
        ["dotnet", ".NET"],
        ["aws", "AWS"],
        ["azure", "Azure"],
        ["gcp", "GCP"],
        ["google cloud", "GCP"],
        ["docker", "Docker"],
        ["kubernetes", "Kubernetes"],
        ["k8s", "Kubernetes"],
        ["ci/cd", "CI/CD"],
        ["sql", "SQL"],
        ["nosql", "NoSQL"],
        ["mongodb", "MongoDB"],
        ["postgresql", "PostgreSQL"],
        ["postgres", "PostgreSQL"],
        ["mysql", "MySQL"],
        ["redis", "Redis"],
        ["elasticsearch", "Elasticsearch"],
        ["kafka", "Kafka"],
        ["rabbitmq", "RabbitMQ"],
        ["git", "Git"],
        ["agile", "Agile"],
        ["scrum", "Scrum"],
        ["rest api", "REST API"],
        ["restful", "REST API"],
        ["graphql", "GraphQL"],
        ["microservices", "Microservices"],
        ["machine learning", "Machine Learning"],
        ["deep learning", "Deep Learning"],
        ["tensorflow", "TensorFlow"],
        ["pytorch", "PyTorch"],
        ["linux", "Linux"]
    ];
    
    foreach string[] mapping in skillMappings {
        if lowerText.includes(mapping[0]) {
            // Check if skill already added
            boolean found = false;
            foreach string skill in skills {
                if skill == mapping[1] {
                    found = true;
                    break;
                }
            }
            if !found {
                skills.push(mapping[1]);
            }
        }
    }
    
    return skills;
}

// Extract experience level from text
function extractExperienceLevelFromText(string text) returns string? {
    string lowerText = text.toLowerAscii();
    if lowerText.includes("senior") || lowerText.includes("sr.") || lowerText.includes("sr ") {
        return "Senior";
    } else if lowerText.includes("junior") || lowerText.includes("jr.") || lowerText.includes("jr ") {
        return "Junior";
    } else if lowerText.includes("lead") || lowerText.includes("principal") || lowerText.includes("staff") {
        return "Lead";
    } else if lowerText.includes("mid-level") || lowerText.includes("mid level") || lowerText.includes("intermediate") {
        return "Mid-level";
    } else if lowerText.includes("entry level") || lowerText.includes("entry-level") {
        return "Entry-level";
    }
    return ();
}

// Extract employment type from text
function extractEmploymentTypeFromText(string text) returns string? {
    string lowerText = text.toLowerAscii();
    if lowerText.includes("full-time") || lowerText.includes("full time") {
        return "Full-time";
    } else if lowerText.includes("part-time") || lowerText.includes("part time") {
        return "Part-time";
    } else if lowerText.includes("contract") {
        return "Contract";
    } else if lowerText.includes("internship") || lowerText.includes("intern") {
        return "Internship";
    } else if lowerText.includes("freelance") {
        return "Freelance";
    }
    return ();
}

// Extract responsibilities from text
function extractResponsibilitiesFromText(string text) returns string[]? {
    string[] responsibilities = [];
    string[] lines = splitByNewline(text);
    
    foreach string line in lines {
        string trimmedLine = strings:trim(line);
        // Look for bullet points or lines starting with common patterns
        if trimmedLine.startsWith("-") || trimmedLine.startsWith("*") {
            string cleaned = strings:trim(trimmedLine.substring(1));
            if cleaned.length() > 10 && responsibilities.length() < 10 {
                responsibilities.push(cleaned);
            }
        }
    }
    
    if responsibilities.length() > 0 {
        return responsibilities;
    }
    return ();
}

// Public function to normalize job posting
public function normalizeJobPosting(ScrapedContent content) returns JobProfile|error {
    io:println("[Normalizer] Normalizing job posting");
    
    string text = content.extractedText;
    string url = content.sourceUrl;
    
    // Get source type from metadata
    string sourceType = "generic";
    map<string>? metadata = content.metadata;
    if metadata is map<string> {
        string? src = metadata["source"];
        if src is string {
            sourceType = src;
        }
    }
    
    io:println("[Normalizer] Source type: " + sourceType);
    
    JobProfile profile = {
        title: extractTitleFromText(text, url),
        company: extractCompanyFromText(text, url),
        location: extractLocationFromText(text),
        description: extractDescriptionFromText(text),
        requiredSkills: extractSkillsFromText(text),
        preferredSkills: [],
        responsibilities: extractResponsibilitiesFromText(text),
        experienceLevel: extractExperienceLevelFromText(text),
        employmentType: extractEmploymentTypeFromText(text),
        salaryMin: (),
        salaryMax: (),
        sourceUrl: url,
        metadata: content.metadata
    };
    
    return profile;
}


