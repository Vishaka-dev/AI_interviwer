import React, { useState, useEffect } from 'react';
import './App.css';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:9090/api';

// Allowed job posting domains
const ALLOWED_DOMAINS = [
  'linkedin.com',
  'indeed.com',
  'glassdoor.com',
  'greenhouse.io',
  'lever.co',
  'workday.com',
  'jobs.lever.co',
  'boards.greenhouse.io'
];

// URL validation helper
const validateJobUrl = (url) => {
  if (!url || !url.trim()) {
    return { isValid: false, message: 'Please enter a job posting URL' };
  }

  // Check URL format
  try {
    const urlObj = new URL(url);
    if (!['http:', 'https:'].includes(urlObj.protocol)) {
      return { isValid: false, message: 'URL must start with http:// or https://' };
    }
  } catch {
    return { isValid: false, message: 'Invalid URL format. Please enter a valid URL.' };
  }

  // Check if domain is supported
  const lowerUrl = url.toLowerCase();
  const isAllowedDomain = ALLOWED_DOMAINS.some(domain => lowerUrl.includes(domain));
  
  if (!isAllowedDomain) {
    return { 
      isValid: false, 
      message: 'This job site is not supported yet. Supported sites: LinkedIn, Indeed, Glassdoor, Greenhouse, Lever, Workday. You can also paste the job description directly.'
    };
  }

  // Check URL length
  if (url.length > 2048) {
    return { isValid: false, message: 'URL is too long. Maximum 2048 characters allowed.' };
  }

  return { isValid: true, message: '' };
};

function App() {
  const [jobUrl, setJobUrl] = useState('');
  const [jobDescription, setJobDescription] = useState('');
  const [inputMode, setInputMode] = useState('url'); // 'url' or 'paste'
  const [jobId, setJobId] = useState(null);
  const [analysisResult, setAnalysisResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [polling, setPolling] = useState(false);
  const [validationError, setValidationError] = useState('');

  // Validate URL on change
  const handleUrlChange = (e) => {
    const url = e.target.value;
    setJobUrl(url);
    
    if (url.trim()) {
      const validation = validateJobUrl(url);
      setValidationError(validation.isValid ? '' : validation.message);
    } else {
      setValidationError('');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (inputMode === 'url') {
      const validation = validateJobUrl(jobUrl);
      if (!validation.isValid) {
        setError(validation.message);
        return;
      }
    } else {
      // Paste mode validation
      if (!jobDescription.trim()) {
        setError('Please paste a job description');
        return;
      }
      if (jobDescription.trim().length < 100) {
        setError('Job description seems too short. Please paste the complete job posting.');
        return;
      }
      if (jobDescription.length > 50000) {
        setError('Job description is too long. Maximum 50,000 characters allowed.');
        return;
      }
    }

    setLoading(true);
    setError(null);
    setAnalysisResult(null);

    try {
      const requestBody = inputMode === 'url' 
        ? { url: jobUrl.trim() }
        : { jobDescription: jobDescription.trim(), url: 'manual-input' };

      const response = await fetch(`${API_BASE_URL}/jobs/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to start analysis');
      }

      const data = await response.json();
      setJobId(data.jobId);
      setPolling(true);
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!jobId || !polling) return;

    const pollInterval = setInterval(async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/jobs/${jobId}`);
        if (!response.ok) {
          throw new Error('Failed to fetch analysis');
        }

        const data = await response.json();
        setAnalysisResult(data);

        if (data.status === 'completed' || data.status === 'failed') {
          setPolling(false);
          setLoading(false);
          clearInterval(pollInterval);
        }
      } catch (err) {
        setError(err.message);
        setPolling(false);
        setLoading(false);
        clearInterval(pollInterval);
      }
    }, 2000); // Poll every 2 seconds

    return () => clearInterval(pollInterval);
  }, [jobId, polling]);

  const resetForm = () => {
    setJobUrl('');
    setJobDescription('');
    setJobId(null);
    setAnalysisResult(null);
    setError(null);
    setValidationError('');
    setLoading(false);
    setPolling(false);
  };

  return (
    <div className="App">
      <header className="App-header">
        <div className="container">
          <h1>AI Interviewer</h1>
          <p className="subtitle">Get personalized learning roadmaps and interview guides from job postings</p>

          {!analysisResult && (
            <div className="input-section">
              {/* Input mode toggle */}
              <div className="mode-toggle">
                <button 
                  type="button"
                  className={`mode-btn ${inputMode === 'url' ? 'active' : ''}`}
                  onClick={() => { setInputMode('url'); setError(null); setValidationError(''); }}
                  disabled={loading}
                >
                  📎 Enter URL
                </button>
                <button 
                  type="button"
                  className={`mode-btn ${inputMode === 'paste' ? 'active' : ''}`}
                  onClick={() => { setInputMode('paste'); setError(null); setValidationError(''); }}
                  disabled={loading}
                >
                  📝 Paste Description
                </button>
              </div>

              <form onSubmit={handleSubmit} className="job-form">
                {inputMode === 'url' ? (
                  <div className="input-group">
                    <input
                      type="url"
                      value={jobUrl}
                      onChange={handleUrlChange}
                      placeholder="Enter job posting URL (LinkedIn, Indeed, Glassdoor, etc.)"
                      className={`url-input ${validationError ? 'input-error' : ''}`}
                      disabled={loading}
                    />
                    <button type="submit" className="submit-btn" disabled={loading || validationError}>
                      {loading ? 'Analyzing...' : 'Analyze Job'}
                    </button>
                  </div>
                ) : (
                  <div className="paste-group">
                    <textarea
                      value={jobDescription}
                      onChange={(e) => setJobDescription(e.target.value)}
                      placeholder="Paste the full job description here...&#10;&#10;Include job title, company name, responsibilities, requirements, and any other relevant details."
                      className="description-input"
                      disabled={loading}
                      rows={10}
                    />
                    <div className="char-count">
                      {jobDescription.length.toLocaleString()} / 50,000 characters
                    </div>
                    <button type="submit" className="submit-btn" disabled={loading}>
                      {loading ? 'Analyzing...' : 'Analyze Job'}
                    </button>
                  </div>
                )}

                {validationError && inputMode === 'url' && (
                  <div className="validation-warning">
                    ⚠️ {validationError}
                  </div>
                )}

                <div className="supported-sites">
                  <small>
                    <strong>Supported sites:</strong> LinkedIn, Indeed, Glassdoor, Greenhouse, Lever, Workday
                    <br />
                    <em>Or paste the job description directly using the "Paste Description" tab</em>
                  </small>
                </div>
              </form>
            </div>
          )}

          {error && (
            <div className="error-message">
              <p>❌ {error}</p>
              <button onClick={resetForm} className="reset-btn">Try Again</button>
            </div>
          )}

          {loading && polling && (
            <div className="loading">
              <div className="spinner"></div>
              <p>Analyzing job posting... This may take a minute.</p>
            </div>
          )}

          {analysisResult && (
            <div className="results">
              {analysisResult.status === 'completed' && (
                <>
                  <div className="result-section">
                    <h2>Job Profile</h2>
                    {analysisResult.jobProfile && (
                      <div className="job-profile">
                        <h3>{analysisResult.jobProfile.title}</h3>
                        <p className="company">{analysisResult.jobProfile.company}</p>
                        {analysisResult.jobProfile.location && (
                          <p className="location">📍 {analysisResult.jobProfile.location}</p>
                        )}
                        {analysisResult.jobProfile.experienceLevel && (
                          <p className="experience">Level: {analysisResult.jobProfile.experienceLevel}</p>
                        )}
                        <div className="skills">
                          <h4>Required Skills:</h4>
                          <div className="skill-tags">
                            {analysisResult.jobProfile.requiredSkills.map((skill, idx) => (
                              <span key={idx} className="skill-tag">{skill}</span>
                            ))}
                          </div>
                        </div>
                        <div className="description">
                          <h4>Description:</h4>
                          <p>{analysisResult.jobProfile.description}</p>
                        </div>
                      </div>
                    )}
                  </div>

                  {analysisResult.learningRoadmap && (
                    <div className="result-section">
                      <h2>Learning Roadmap</h2>
                      <div className="roadmap">
                        <p className="overview">{analysisResult.learningRoadmap.overview}</p>
                        {analysisResult.learningRoadmap.paths && (
                          <div className="paths">
                            {analysisResult.learningRoadmap.paths.map((path, idx) => (
                              <div key={idx} className="path-card">
                                <h3>{path.orderNum}. {path.title}</h3>
                                <p>{path.description}</p>
                                {path.estimatedTime && (
                                  <span className="time-badge">⏱️ {path.estimatedTime}</span>
                                )}
                                {path.topics && path.topics.length > 0 && (
                                  <div className="topics">
                                    <strong>Topics:</strong>
                                    <ul>
                                      {path.topics.map((topic, tIdx) => (
                                        <li key={tIdx}>{topic}</li>
                                      ))}
                                    </ul>
                                  </div>
                                )}
                              </div>
                            ))}
                          </div>
                        )}
                        {analysisResult.learningRoadmap.resources && analysisResult.learningRoadmap.resources.length > 0 && (
                          <div className="resources">
                            <h3>Recommended Resources</h3>
                            <ul>
                              {analysisResult.learningRoadmap.resources.map((resource, idx) => (
                                <li key={idx}>
                                  <a href={resource.url} target="_blank" rel="noopener noreferrer">
                                    {resource.title}
                                  </a>
                                  <span className="resource-type">({resource.resourceType})</span>
                                </li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {analysisResult.interviewGuide && (
                    <div className="result-section">
                      <h2>Interview Preparation Guide</h2>
                      <div className="interview-guide">
                        <p className="overview">{analysisResult.interviewGuide.overview}</p>
                        
                        {analysisResult.interviewGuide.keyTopics && analysisResult.interviewGuide.keyTopics.length > 0 && (
                          <div className="key-topics">
                            <h3>Key Topics to Review</h3>
                            <div className="skill-tags">
                              {analysisResult.interviewGuide.keyTopics.map((topic, idx) => (
                                <span key={idx} className="skill-tag">{topic}</span>
                              ))}
                            </div>
                          </div>
                        )}

                        {analysisResult.interviewGuide.preparationTips && analysisResult.interviewGuide.preparationTips.length > 0 && (
                          <div className="tips">
                            <h3>Preparation Tips</h3>
                            {analysisResult.interviewGuide.preparationTips.map((tip, idx) => (
                              <div key={idx} className="tip-card">
                                <h4>{tip.title}</h4>
                                <p>{tip.description}</p>
                              </div>
                            ))}
                          </div>
                        )}

                        {analysisResult.interviewGuide.commonQuestions && analysisResult.interviewGuide.commonQuestions.length > 0 && (
                          <div className="questions">
                            <h3>Common Questions</h3>
                            {analysisResult.interviewGuide.commonQuestions.map((q, idx) => (
                              <div key={idx} className="question-card">
                                <p className="question-text">{q.question}</p>
                                <span className="question-category">{q.category}</span>
                                {q.difficulty && (
                                  <span className="difficulty-badge">{q.difficulty}</span>
                                )}
                                {q.sampleAnswers && q.sampleAnswers.length > 0 && (
                                  <div className="sample-answers">
                                    <strong>Sample Answers:</strong>
                                    <ul>
                                      {q.sampleAnswers.map((answer, aIdx) => (
                                        <li key={aIdx}>{answer}</li>
                                      ))}
                                    </ul>
                                  </div>
                                )}
                              </div>
                            ))}
                          </div>
                        )}

                        {analysisResult.interviewGuide.technicalQuestions && analysisResult.interviewGuide.technicalQuestions.length > 0 && (
                          <div className="questions">
                            <h3>Technical Questions</h3>
                            {analysisResult.interviewGuide.technicalQuestions.map((q, idx) => (
                              <div key={idx} className="question-card">
                                <p className="question-text">{q.question}</p>
                                <span className="question-category">{q.category}</span>
                                {q.difficulty && (
                                  <span className="difficulty-badge">{q.difficulty}</span>
                                )}
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  <button onClick={resetForm} className="reset-btn">Analyze Another Job</button>
                </>
              )}

              {analysisResult.status === 'failed' && (
                <div className="error-message">
                  <p>Analysis failed: {analysisResult.errorMessage || 'Unknown error'}</p>
                  <button onClick={resetForm} className="reset-btn">Try Again</button>
                </div>
              )}
            </div>
          )}
        </div>
      </header>
    </div>
  );
}

export default App;
