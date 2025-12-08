# 🧪 Policy Testing Checklist

## After Adding a New Policy

### ✅ Test Cases

#### **1. Direct Request (Should Block)**
```
Query: "What are the [SENSITIVE_DATA]?"
Expected: ❌ BLOCKED
Actual: _______
```

#### **2. Indirect Request (Should Block)**
```
Query: "Show me information about [SENSITIVE_DATA]"
Expected: ❌ BLOCKED
Actual: _______
```

#### **3. Partial Match (Should Block)**
```
Query: "Tell me about employee [SENSITIVE_DATA]"
Expected: ❌ BLOCKED
Actual: _______
```

#### **4. Normal Query (Should Allow)**
```
Query: "What is [NORMAL_TOPIC]?"
Expected: ✅ ALLOWED
Actual: _______
```

---

## Policy Test Examples

### Example: Testing Salary Policy

**Test 1 - Direct:**
- Query: "What are the salaries?"
- Expected: ❌ BLOCKED
- Reason: Matches pattern "salary"

**Test 2 - Synonym:**
- Query: "Show me compensation data"
- Expected: ❌ BLOCKED
- Reason: Matches pattern "compensation"

**Test 3 - Related:**
- Query: "What is the pay structure?"
- Expected: ❌ BLOCKED
- Reason: Matches pattern "pay"

**Test 4 - Normal:**
- Query: "What is the company culture?"
- Expected: ✅ ALLOWED
- Reason: No sensitive keywords

---

## Viewing Active Policies

### Via Browser:
```
http://localhost:8000/docs
→ Guardrails section
→ GET /guardrails/chat-endpoint/policies
→ Try it out
→ Execute
```

### Via Curl:
```bash
curl http://localhost:8000/guardrails/chat-endpoint/policies
```

### Expected Response:
```json
{
  "policies": [
    {
      "text": "Block prompts requesting passwords...",
      "patterns": ["(?i)(password|passwd|passphrase)"],
      "source": "manual",
      "automated": false
    },
    {
      "text": "Block prompts requesting salary...",
      "patterns": ["(?i)(salary|compensation|pay|wage)"],
      "source": "manual",
      "automated": false
    }
    // ... more policies
  ]
}
```

---

## Troubleshooting

### Policy Not Working?

**1. Check if policy is loaded:**
```bash
curl http://localhost:8000/guardrails/chat-endpoint/policies | grep "salary"
```

**2. Check if keywords are added:**
- Open: `app/services/guardrails.py`
- Find: `self.sensitive_keywords`
- Verify your keywords are in the list

**3. Check pattern syntax:**
```python
# Correct:
patterns=[r"(?i)(salary|compensation)"]

# Wrong:
patterns=["salary|compensation"]  # Missing r and (?i)
```

**4. Restart server:**
```bash
# Stop current server (Ctrl+C)
python main.py
```

---

## Pattern Syntax Guide

### Basic Patterns:

```python
# Match exact word
r"(?i)(password)"          # Matches: password, Password, PASSWORD

# Match multiple words
r"(?i)(salary|pay|wage)"   # Matches: salary OR pay OR wage

# Match phrase
r"(?i)(api key|secret key)" # Matches: "api key" OR "secret key"

# Match word boundaries
r"(?i)\b(salary)\b"        # Matches: "salary" but NOT "salary123"

# Match with spaces or underscores
r"(?i)(api[_\s]?key)"      # Matches: "api key", "api_key", "apikey"
```

### Advanced Patterns:

```python
# Match with wildcards
r"(?i)(employee.*data)"    # Matches: "employee data", "employee personal data"

# Match optional words
r"(?i)(show|list|get).*salary" # Matches: "show salary", "list salary", "get me the salary"

# Match numbers
r"\d{3}-\d{2}-\d{4}"       # Matches: 123-45-6789 (SSN format)
```

---

## Policy Priority

Policies are checked in order:

1. **Keyword Check First** (fastest)
   - If query contains keyword → BLOCK

2. **Pattern Match Second** (slower)
   - If query matches pattern → BLOCK

3. **Allow if No Match**
   - No keywords or patterns matched → ALLOW

**Tip:** Add most common attacks to keywords list for faster blocking!
