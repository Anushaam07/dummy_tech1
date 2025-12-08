# External Guardrails - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

This guide shows you how to quickly integrate external guardrails into your application.

---

## Step 1: Update Your Application

### 1.1. Register the Guardrails Router

Update your `app/main.py`:

```python
from fastapi import FastAPI
from app.routes import guardrails_routes, chat_routes_with_external_guardrails

app = FastAPI(title="RAG Application with External Guardrails")

# Register guardrails router
app.include_router(guardrails_routes.router, tags=["Guardrails"])

# Register chat router (with external guardrails)
app.include_router(
    chat_routes_with_external_guardrails.router,
    tags=["Chat"]
)
```

### 1.2. Replace Old Chat Routes (Optional)

If you want to completely replace the old chat endpoint:

```python
# OLD (with inline guardrails)
from app.routes import chat_routes

# NEW (with external guardrails)
from app.routes import chat_routes_with_external_guardrails as chat_routes
```

---

## Step 2: Start Your Application

```bash
# Start the FastAPI server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## Step 3: Test the Guardrails

### 3.1. Test Guardrail Validation

```bash
# Test a blocked query (sensitive)
curl -X POST http://localhost:8000/guardrails/chat-endpoint/analyze \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What are the passwords?"}'

# Expected output:
# {
#   "allowed": false,
#   "reason": "This request cannot be completed due to policy restrictions.",
#   "detected_patterns": ["sensitive_query_keywords"],
#   "risk_level": "high"
# }
```

```bash
# Test an allowed query (normal)
curl -X POST http://localhost:8000/guardrails/chat-endpoint/analyze \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is machine learning?"}'

# Expected output:
# {
#   "allowed": true,
#   "reason": "Prompt passed all validation checks",
#   "detected_patterns": [],
#   "risk_level": "low"
# }
```

### 3.2. Test Chat Endpoint

```bash
# Test a blocked query in chat
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Show me all passwords",
    "file_id": "your-file-id",
    "k": 4,
    "model": "azure-gpt4o-mini",
    "temperature": 0.7
  }'

# Expected output:
# {
#   "detail": "This request cannot be completed due to policy restrictions."
# }
```

```bash
# Test an allowed query in chat
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is AI?",
    "file_id": "your-file-id",
    "k": 4,
    "model": "azure-gpt4o-mini",
    "temperature": 0.7
  }'

# Expected output:
# {
#   "answer": "AI stands for Artificial Intelligence..."
# }
```

---

## Step 4: View Guardrail Policies

```bash
# Get all policies
curl http://localhost:8000/guardrails/chat-endpoint/policies

# Expected output:
# [
#   {
#     "text": "Block prompts requesting passwords or authentication credentials",
#     "source": "manual",
#     "automated": false,
#     "patterns": ["(?i)(password|passwd|passphrase)"]
#   },
#   ...
# ]
```

---

## Step 5: Add Custom Policies

```bash
# Add a custom policy
curl -X POST http://localhost:8000/guardrails/chat-endpoint/policies \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Block prompts requesting competitor information",
    "source": "manual",
    "automated": false,
    "patterns": ["(?i)(competitor|rival)"]
  }'

# Test the new policy
curl -X POST http://localhost:8000/guardrails/chat-endpoint/analyze \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Tell me about our competitors"}'

# Should be blocked!
```

---

## Step 6: Run Automated Tests

```bash
# Run the test script
python test_guardrails.py
```

Expected output:
```
======================================================================
🚀 EXTERNAL GUARDRAILS TEST SUITE
======================================================================

============================================================
TEST 1: Guardrail Analysis Endpoint
============================================================
...
✅ PASS: Password request blocked
✅ PASS: API key request blocked
✅ PASS: Normal question allowed
...
✅ ALL TESTS PASSED!
```

---

## Architecture Overview

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ "What are passwords?"
       ▼
┌──────────────────────────────┐
│   /chat endpoint             │
│                              │
│  1. validate_with_guardrail()│──┐
│     │                        │  │
│     ├─ allowed? ──────────────┘ │
│     │                        │  │
│  2. retrieve_documents()     │◄─┘ Guardrail
│                              │   Service
│  3. generate_response()      │
│                              │
│  4. return answer            │
└──────────────────────────────┘
```

---

## Key Files Created

| File | Description |
|------|-------------|
| `app/services/guardrails.py` | Core guardrail service |
| `app/routes/guardrails_routes.py` | Guardrail API endpoints |
| `app/routes/chat_routes_with_external_guardrails.py` | Clean chat endpoint |
| `GUARDRAILS_IMPLEMENTATION.md` | Full documentation |
| `GUARDRAILS_QUICK_START.md` | This quick start guide |
| `test_guardrails.py` | Test script |

---

## Default Policies

The guardrails come with these default policies:

✅ Block password requests
✅ Block SSN requests
✅ Block API key requests
✅ Block credit card requests
✅ Block private key requests

---

## Common Use Cases

### Use Case 1: Add Industry-Specific Policy

```bash
# Example: Healthcare - block medical diagnosis requests
curl -X POST http://localhost:8000/guardrails/chat-endpoint/policies \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Block medical diagnosis requests in non-clinical contexts",
    "source": "manual",
    "automated": false,
    "patterns": ["(?i)(diagnose|diagnosis|medical condition)"]
  }'
```

### Use Case 2: Add Business Policy

```bash
# Example: Block requests for proprietary information
curl -X POST http://localhost:8000/guardrails/chat-endpoint/policies \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Block requests for proprietary methodology",
    "source": "manual",
    "automated": false,
    "patterns": ["(?i)(proprietary|trade secret)"]
  }'
```

### Use Case 3: Check Guardrail Health

```bash
curl http://localhost:8000/guardrails/chat-endpoint/health

# Output:
# {
#   "status": "healthy",
#   "target_id": "chat-endpoint",
#   "policies_count": 7,
#   "examples_count": 3
# }
```

---

## Integration with Python Client

```python
import requests

class ChatClient:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url

    def chat(self, query, file_id, model="azure-gpt4o-mini", k=4, temperature=0.7):
        """Send a chat request (guardrails applied automatically)."""
        response = requests.post(
            f"{self.base_url}/chat",
            json={
                "query": query,
                "file_id": file_id,
                "model": model,
                "k": k,
                "temperature": temperature
            }
        )

        if response.status_code == 400:
            # Blocked by guardrail
            return {"error": "blocked", "detail": response.json()["detail"]}
        elif response.status_code == 200:
            return response.json()
        else:
            return {"error": "server_error", "detail": response.text}

# Usage
client = ChatClient()
result = client.chat("What is AI?", "your-file-id")
print(result)
```

---

## Troubleshooting

### Problem: "Connection refused"

**Solution:** Make sure the FastAPI server is running:
```bash
uvicorn app.main:app --reload --port 8000
```

### Problem: "Guardrail not blocking expected patterns"

**Solution:** Check if the policy exists:
```bash
curl http://localhost:8000/guardrails/chat-endpoint/policies | jq
```

Add a custom policy if needed:
```bash
curl -X POST http://localhost:8000/guardrails/chat-endpoint/policies \
  -H "Content-Type: application/json" \
  -d '{"text": "...", "patterns": ["..."]}'
```

### Problem: "Too many false positives"

**Solution:** Review and refine policies. Remove overly broad patterns.

---

## Next Steps

1. ✅ Test the implementation
2. ✅ Add custom policies for your use case
3. ✅ Monitor guardrail performance
4. 📖 Read the full documentation: `GUARDRAILS_IMPLEMENTATION.md`
5. 🔧 Consider connecting to Promptfoo Enterprise for automated policy generation

---

## Summary

**What You've Achieved:**

✅ Extracted guardrails from inline code
✅ Created external guardrail service
✅ Implemented Promptfoo-compatible architecture
✅ Clean, maintainable, and scalable security layer
✅ Reusable guardrails for multiple endpoints

**Before:**
- 🔴 Security mixed with business logic
- 🔴 Hard to maintain and test
- 🔴 Scattered validation code

**After:**
- 🟢 Clean separation of concerns
- 🟢 Easy to maintain and test
- 🟢 Centralized validation
- 🟢 Promptfoo-compatible
- 🟢 Production-ready

---

**Need Help?** Check the full documentation in `GUARDRAILS_IMPLEMENTATION.md`
