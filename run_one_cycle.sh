#!/bin/bash
#
# Red Team → Guardrails: One Complete Cycle
# This script runs ONE iteration of the continuous improvement cycle
#

set -e

echo "🔄 RED TEAM → GUARDRAILS CYCLE"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check if server is running
echo "📋 STEP 1: Checking if server is running..."
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Server not running!${NC}"
    echo "Please start the server in another terminal:"
    echo "  python main.py"
    exit 1
fi
echo -e "${GREEN}✅ Server is running${NC}"
echo ""

# Step 2: Check current policy count
echo "📊 STEP 2: Current guardrail policies..."
POLICY_COUNT=$(curl -s http://localhost:8000/guardrails/chat-endpoint/policies | python3 -c "import sys, json; print(len(json.load(sys.stdin)['policies']))" 2>/dev/null || echo "0")
echo -e "${GREEN}Current policies: $POLICY_COUNT${NC}"
echo ""

# Step 3: Run red team tests
echo "🔴 STEP 3: Running red team tests..."
echo "This may take a few minutes..."
if [ -f "promptfooconfig.yaml" ]; then
    npx promptfoo@latest redteam run --output redteam_results.json
    echo -e "${GREEN}✅ Red team tests complete${NC}"
else
    echo -e "${RED}❌ promptfooconfig.yaml not found!${NC}"
    echo "Please configure Promptfoo first"
    exit 1
fi
echo ""

# Step 4: Analyze results
echo "🔍 STEP 4: Analyzing results..."
if [ -f "redteam_results.json" ]; then
    # Count passed/failed
    TOTAL=$(python3 -c "import json; data=json.load(open('redteam_results.json')); print(len(data.get('results', [])))" 2>/dev/null || echo "0")
    FAILED=$(python3 -c "import json; data=json.load(open('redteam_results.json')); print(len([t for t in data.get('results', []) if not t.get('success', True)]))" 2>/dev/null || echo "0")
    PASSED=$((TOTAL - FAILED))

    echo -e "${GREEN}✅ Passed: $PASSED/$TOTAL${NC}"
    echo -e "${RED}❌ Failed: $FAILED/$TOTAL${NC}"

    if [ "$FAILED" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 PERFECT! No vulnerabilities found!${NC}"
        echo "Your guardrails are working great!"
        exit 0
    fi
else
    echo -e "${YELLOW}⚠️  Results file not found${NC}"
    echo "Please check manually with: npx promptfoo@latest view"
fi
echo ""

# Step 5: Show failures
echo "🚨 STEP 5: Found vulnerabilities that need fixing:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python3 << 'PYTHON_SCRIPT'
import json
import sys

try:
    with open('redteam_results.json') as f:
        data = json.load(f)

    failed_tests = [
        test for test in data.get('results', [])
        if not test.get('success', True)
    ]

    for i, test in enumerate(failed_tests[:5], 1):  # Show first 5
        prompt = test.get('vars', {}).get('query', 'N/A')
        print(f"\n❌ Vulnerability {i}:")
        print(f"   Attack: {prompt[:80]}...")

        # Extract keywords
        words = prompt.lower().split()
        actions = ['list', 'show', 'give', 'provide', 'summarize', 'organize', 'display', 'tell']
        sensitive = ['sensitive', 'confidential', 'private', 'secret', 'password', 'credentials']

        found = [w for w in words if w in actions + sensitive][:3]

        if found:
            pattern = "|".join(found)
            print(f"   Suggested pattern: r\"(?i)({pattern})\"")

    if len(failed_tests) > 5:
        print(f"\n... and {len(failed_tests) - 5} more")

except Exception as e:
    print(f"Error analyzing results: {e}")
    sys.exit(1)
PYTHON_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 6: Next actions
echo "📝 STEP 6: Next Actions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Review full results:"
echo "   ${YELLOW}npx promptfoo@latest view${NC}"
echo ""
echo "2. Add policies to app/services/guardrails.py:"
echo "   - Find the 'RED TEAM DISCOVERED POLICIES' section (around line 175)"
echo "   - Add GuardrailPolicy for each vulnerability above"
echo ""
echo "3. Restart the server:"
echo "   ${YELLOW}python main.py${NC}"
echo ""
echo "4. Run this script again to verify fixes:"
echo "   ${YELLOW}./run_one_cycle.sh${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 7: Open report
echo "🌐 Opening detailed report..."
npx promptfoo@latest view &
sleep 2

echo ""
echo "✅ Cycle complete! Follow the next actions above to fix vulnerabilities."
echo ""
