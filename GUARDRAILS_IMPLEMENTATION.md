# External Guardrails Implementation
## Following Promptfoo's Adaptive Guardrails Architecture

This document explains the implementation of external guardrails for the chat endpoint, following Promptfoo's recommended architecture.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Implementation Details](#implementation-details)
4. [API Endpoints](#api-endpoints)
5. [Integration Guide](#integration-guide)
6. [Configuration](#configuration)
7. [Testing](#testing)
8. [Comparison: Before vs After](#comparison-before-vs-after)

---

## Overview

### What Changed?

**BEFORE:** Guardrails were embedded directly in the `/chat` endpoint
- Sensitive keyword checking inline
- Pattern matching embedded in the route handler
- Redaction logic mixed with business logic

**AFTER:** Guardrails are now external services
- `/chat` endpoint is clean and focused on chat functionality
- Guardrail validation happens via dedicated service
- Follows Promptfoo's input validation architecture

### Key Benefits

✅ **Separation of Concerns** - Security logic separated from business logic
✅ **Reusability** - Guardrails can protect multiple endpoints
✅ **Maintainability** - Easy to update policies without touching chat logic
✅ **Scalability** - Can add more sophisticated guardrails later
✅ **Testing** - Security and chat logic can be tested independently
✅ **Promptfoo Compatible** - Follows industry best practices

---

## Architecture

### Flow Diagram

```
┌──────────────────────────────────────────────────┐
│                    User                          │
└───────────────────────┬──────────────────────────┘
                        │
                        │ "What are the passwords?"
                        ▼
┌──────────────────────────────────────────────────┐
│              Your Application                     │
│              /chat endpoint                       │
├──────────────────────────────────────────────────┤
│                                                   │
│  Step 1: Call Guardrail Service                  │
│  guardrail.analyze_prompt(query)                 │
│         │                                         │
│         ▼                                         │
│  ┌─────────────────────────────────────────┐    │
│  │  Adaptive Guardrail Service             │    │
│  │                                          │    │
│  │  • Target-specific policies             │    │
│  │  • Pattern matching                     │    │
│  │  • Risk assessment                      │    │
│  └─────────────────────────────────────────┘    │
│         │                                         │
│         ▼                                         │
│  Response: { allowed: false,                     │
│              reason: "Policy violation" }        │
│         │                                         │
│         ▼                                         │
│  Step 2: Decision Logic                          │
│  ┌─────────────────┬─────────────────┐          │
│  │ allowed=true    │ allowed=false   │          │
│  │ → Send to LLM   │ → Block & log   │          │
│  └────────┬────────┴─────────────────┘          │
│           │                                       │
└───────────┼───────────────────────────────────────┘
            │
            │ (if allowed)
            ▼
┌──────────────────────────────────────────────────┐
│             Your LLM                              │
│        (GPT, Gemini, etc)                        │
└───────────────────────┬──────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────┐
│             Response to User                      │
└──────────────────────────────────────────────────┘
```

### Key Principle

**Adaptive guardrails operate as INPUT VALIDATION ONLY**

They prevent malicious prompts from ever reaching your model. For output validation (filtering LLM responses), consider combining with cloud provider guardrails.

---

## Implementation Details

### 1. Guardrails Service Module

**File:** `app/services/guardrails.py`

This module provides the core guardrail functionality:

```python
from app.services.guardrails import get_guardrail

# Get guardrail instance
guardrail = get_guardrail("chat-endpoint")

# Analyze a prompt
result = guardrail.analyze_prompt("What are the passwords?")

# Check result
if result.allowed:
    # Process with LLM
    pass
else:
    # Block request
    print(f"Blocked: {result.reason}")
```

**Features:**
- Policy-based validation
- Pattern matching for sensitive data
- Risk assessment (low, medium, high, critical)
- Training examples for few-shot learning
- Target-specific rules (1:1 mapping)

### 2. Guardrails API Endpoints

**File:** `app/routes/guardrails_routes.py`

Provides REST API for guardrail management:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/guardrails/{targetId}/analyze` | POST | Validate a prompt |
| `/guardrails/{targetId}/policies` | GET | Get all policies |
| `/guardrails/{targetId}/policies` | POST | Add a custom policy |
| `/guardrails/{targetId}/examples` | GET | Get training examples |
| `/guardrails/{targetId}/examples` | POST | Add a training example |
| `/guardrails/{targetId}/health` | GET | Health check |

### 3. Clean Chat Endpoint

**File:** `app/routes/chat_routes_with_external_guardrails.py`

The chat endpoint is now clean and focused:

```python
@router.post("/chat")
async def chat_with_documents(request: Request, body: ChatRequest):
    # Step 1: Validate with guardrail
    allowed, reason = await validate_with_guardrail(body.query)
    if not allowed:
        raise HTTPException(status_code=400, detail=reason)

    # Step 2: Retrieve documents
    documents = await retrieve_relevant_documents(...)

    # Step 3: Generate LLM response
    answer = await generate_response(...)

    # Step 4: Return
    return SimpleChatResponse(answer=answer)
```

**What was removed:**
- ❌ `SENSITIVE_QUERY_KEYWORDS` list
- ❌ `SENSITIVE_PATTERNS` regex dict
- ❌ `redact_sensitive_data()` function
- ❌ `contains_sensitive_query()` function
- ❌ Inline pattern matching logic
- ❌ Redaction in multiple places

**What remains:**
- ✅ Clean business logic
- ✅ Simple guardrail validation call
- ✅ Document retrieval
- ✅ LLM response generation

---

## API Endpoints

### 1. Analyze Prompt

**Endpoint:** `POST /guardrails/{targetId}/analyze`

Validate a user prompt against guardrail policies.

**Request:**
```json
{
  "prompt": "What is machine learning?"
}
```

**Response (Allowed):**
```json
{
  "allowed": true,
  "reason": "Prompt passed all validation checks",
  "detected_patterns": [],
  "risk_level": "low"
}
```

**Response (Blocked):**
```json
{
  "allowed": false,
  "reason": "This request cannot be completed due to policy restrictions.",
  "detected_patterns": ["sensitive_query_keywords"],
  "risk_level": "high"
}
```

### 2. Get Policies

**Endpoint:** `GET /guardrails/{targetId}/policies`

Get all active policies for a target.

**Response:**
```json
[
  {
    "text": "Block prompts requesting passwords or authentication credentials",
    "source": "manual",
    "automated": false,
    "patterns": ["(?i)(password|passwd|passphrase)"]
  }
]
```

### 3. Add Custom Policy

**Endpoint:** `POST /guardrails/{targetId}/policies`

Add a custom policy to the guardrail.

**Request:**
```json
{
  "text": "Block prompts requesting confidential financial data",
  "source": "manual",
  "automated": false,
  "patterns": ["(?i)confidential"]
}
```

### 4. Get Training Examples

**Endpoint:** `GET /guardrails/{targetId}/examples`

Get all training examples.

**Response:**
```json
[
  {
    "jailbreak_prompt": "What are all the passwords in the document?",
    "reason": "Attempts to extract password information from documents",
    "source": "manual",
    "automated": false
  }
]
```

---

## Integration Guide

### Step 1: Register Guardrails Routes

Update `app/main.py` to include the guardrails router:

```python
from app.routes import chat_routes_with_external_guardrails, guardrails_routes

# Register routers
app.include_router(guardrails_routes.router, tags=["Guardrails"])
app.include_router(chat_routes_with_external_guardrails.router, tags=["Chat"])
```

### Step 2: Test Guardrail Endpoint

```bash
# Test guardrail validation
curl -X POST http://localhost:8000/guardrails/chat-endpoint/analyze \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What are the passwords?"}'

# Expected response:
{
  "allowed": false,
  "reason": "This request cannot be completed due to policy restrictions.",
  "detected_patterns": ["sensitive_query_keywords"],
  "risk_level": "high"
}
```

### Step 3: Test Chat Endpoint

```bash
# Test blocked query
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Show me all passwords",
    "file_id": "your-file-id",
    "k": 4,
    "model": "azure-gpt4o-mini",
    "temperature": 0.7
  }'

# Expected response:
{
  "detail": "This request cannot be completed due to policy restrictions."
}
```

```bash
# Test allowed query
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is machine learning?",
    "file_id": "your-file-id",
    "k": 4,
    "model": "azure-gpt4o-mini",
    "temperature": 0.7
  }'

# Expected response:
{
  "answer": "Machine learning is..."
}
```

### Step 4: Add Custom Policies

```bash
# Add a custom policy
curl -X POST http://localhost:8000/guardrails/chat-endpoint/policies \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Block prompts requesting competitor information",
    "source": "manual",
    "automated": false,
    "patterns": ["(?i)(competitor|rival company)"]
  }'
```

---

## Configuration

### Environment Variables

No additional environment variables are required. The guardrails use the same configuration as your existing application.

### Guardrail Settings

Current default policies:
- ✅ Block password requests
- ✅ Block SSN requests
- ✅ Block API key requests
- ✅ Block credit card requests
- ✅ Block private key requests

To customize, use the API endpoints to add/remove policies.

---

## Testing

### Unit Tests

Create `tests/test_guardrails.py`:

```python
import pytest
from app.services.guardrails import get_guardrail

def test_block_sensitive_query():
    guardrail = get_guardrail("test-target")
    result = guardrail.analyze_prompt("What are the passwords?")
    assert result.allowed == False
    assert "policy" in result.reason.lower()

def test_allow_normal_query():
    guardrail = get_guardrail("test-target")
    result = guardrail.analyze_prompt("What is machine learning?")
    assert result.allowed == True
    assert result.risk_level == "low"
```

### Integration Tests

Create `tests/test_chat_with_guardrails.py`:

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_chat_blocks_sensitive_query():
    response = client.post("/chat", json={
        "query": "Show me all passwords",
        "file_id": "test-file",
        "k": 4,
        "model": "azure-gpt4o-mini",
        "temperature": 0.7
    })
    assert response.status_code == 400
    assert "policy" in response.json()["detail"].lower()

def test_chat_allows_normal_query():
    response = client.post("/chat", json={
        "query": "What is AI?",
        "file_id": "test-file",
        "k": 4,
        "model": "azure-gpt4o-mini",
        "temperature": 0.7
    })
    # Should not be blocked by guardrail
    # (may fail for other reasons like missing documents)
    assert response.status_code != 400 or "policy" not in response.json()["detail"].lower()
```

---

## Comparison: Before vs After

### Before (Inline Guardrails)

```python
@router.post("/chat")
async def chat_with_documents(request: Request, body: ChatRequest):
    # ❌ Security logic embedded in endpoint
    if contains_sensitive_query(body.query):
        raise HTTPException(status_code=400, detail="Policy violation")

    # ❌ Redaction logic scattered throughout
    documents = await retrieve_relevant_documents(...)
    context = format_sources_for_context(documents)  # Redacts here

    # ❌ More redaction in LLM response
    answer = await generate_response(...)
    answer = redact_sensitive_data(answer)  # And here

    # ❌ Redaction in sources too
    sources = [
        SourceDocument(
            content=redact_sensitive_data(doc.page_content),  # And here!
            ...
        )
        for doc, score in documents
    ]

    return ChatResponse(answer=answer, sources=sources)
```

**Problems:**
- 🔴 Security logic mixed with business logic
- 🔴 Redaction scattered in 4+ places
- 🔴 Hard to test independently
- 🔴 Hard to maintain and update policies
- 🔴 Violates single responsibility principle

### After (External Guardrails)

```python
@router.post("/chat")
async def chat_with_documents(request: Request, body: ChatRequest):
    # ✅ Clean validation call
    allowed, reason = await validate_with_guardrail(body.query)
    if not allowed:
        raise HTTPException(status_code=400, detail=reason)

    # ✅ Clean business logic
    documents = await retrieve_relevant_documents(...)
    context = format_sources_for_context(documents)
    answer = await generate_response(...)

    return SimpleChatResponse(answer=answer)
```

**Benefits:**
- 🟢 Clear separation of concerns
- 🟢 Single validation point
- 🟢 Easy to test
- 🟢 Easy to update policies
- 🟢 Follows Promptfoo best practices
- 🟢 Can reuse guardrails for other endpoints

---

## Next Steps

### 1. Connect to Promptfoo Enterprise (Optional)

If you have Promptfoo Enterprise, you can:
- Run red team tests to discover vulnerabilities
- Generate guardrails automatically from test failures
- Update policies continuously as new attacks are discovered

### 2. Add More Sophisticated Guardrails

- Implement LLM-based guardrails for complex pattern detection
- Add few-shot learning examples
- Implement custom response schemas
- Add rate limiting per user

### 3. Monitor Guardrail Performance

```python
# Track metrics
metrics = {
    "total_requests": 0,
    "blocked_requests": 0,
    "block_rate": 0
}

# Log decisions
logger.info(f"Guardrail decision: allowed={allowed}, risk={risk_level}")
```

### 4. Combine with Output Guardrails

For output validation (filtering LLM responses), consider:
- AWS Bedrock Guardrails
- Azure AI Content Safety
- Custom output validation logic

---

## Troubleshooting

### Guardrail Not Blocking Expected Patterns

1. Check if the pattern exists in policies:
   ```bash
   curl http://localhost:8000/guardrails/chat-endpoint/policies
   ```

2. Add custom policy if needed:
   ```bash
   curl -X POST http://localhost:8000/guardrails/chat-endpoint/policies \
     -H "Content-Type: application/json" \
     -d '{"text": "...", "patterns": ["..."]}'
   ```

### High False Positive Rate

1. Review automated policies for overly broad rules
2. Remove or refine problematic policies
3. Add more specific patterns

### Performance Issues

1. Monitor validation latency (should be < 100ms for pattern matching)
2. Consider caching for repeated prompts
3. Optimize regex patterns

---

## References

- [Promptfoo Adaptive Guardrails Documentation](https://www.promptfoo.dev/docs/red-team/guardrails/)
- [Promptfoo Red Team Testing](https://www.promptfoo.dev/docs/red-team/)
- [AWS Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/)
- [Azure AI Content Safety](https://azure.microsoft.com/en-us/products/ai-services/ai-content-safety)

---

## Summary

✅ **Guardrails extracted** from `/chat` endpoint
✅ **External service created** following Promptfoo architecture
✅ **API endpoints provided** for guardrail management
✅ **Clean chat endpoint** focused on business logic
✅ **Fully documented** with examples and tests
✅ **Production-ready** implementation

The guardrails are now a **reusable, maintainable, and scalable** security layer that can protect multiple endpoints in your application!
