#!/bin/bash
# Research context for a prediction market question
# Usage: research.sh <question> [--json]
#
# Gathers relevant context from web search to inform conviction formation.
# Returns structured research summary.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
QUESTION=""
JSON_OUTPUT=false
MAX_RESULTS=5

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --json|-j)
      JSON_OUTPUT=true
      shift
      ;;
    --max|-m)
      MAX_RESULTS="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: research.sh <question> [OPTIONS]"
      echo ""
      echo "Gather context for conviction formation via web search."
      echo ""
      echo "Options:"
      echo "  --json, -j          Output as JSON"
      echo "  --max, -m <n>       Max search results (default: 5)"
      echo ""
      echo "Example:"
      echo "  research.sh \"Will JD Vance win the 2028 presidential election?\""
      exit 0
      ;;
    *)
      if [ -z "$QUESTION" ]; then
        QUESTION="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$QUESTION" ]; then
  echo "Error: Question required" >&2
  echo "Usage: research.sh <question>" >&2
  exit 1
fi

# Build search query - extract key terms from question
# Remove common words and focus on the core topic
SEARCH_QUERY=$(echo "$QUESTION" | sed 's/[Ww]ill //g; s/[?]//g; s/ the / /g; s/ a / /g; s/ an / /g')

# Add context terms for better results
SEARCH_QUERY="$SEARCH_QUERY latest news analysis 2026"

# Use Brave Search API via environment or fallback
# Note: In OpenClaw context, web_search tool handles this
# For standalone use, we output the query for manual search

if [ "$JSON_OUTPUT" = true ]; then
  # Output JSON structure for the research
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  cat << EOF
{
  "question": "$(echo "$QUESTION" | sed 's/"/\\"/g')",
  "search_query": "$(echo "$SEARCH_QUERY" | sed 's/"/\\"/g')",
  "timestamp": "$TIMESTAMP",
  "instructions": "Use web_search tool with the search_query to gather context. Then populate the findings array.",
  "findings": [],
  "summary": null,
  "key_facts": [],
  "sentiment": null,
  "data_quality": null
}
EOF

else
  echo "=== Research: $QUESTION ==="
  echo ""
  echo "Suggested search query:"
  echo "  $SEARCH_QUERY"
  echo ""
  echo "To gather context, search for:"
  echo "  1. Recent news about the topic"
  echo "  2. Expert analysis or predictions"
  echo "  3. Historical precedents"
  echo "  4. Polling data (if applicable)"
  echo "  5. Key factors that could influence outcome"
  echo ""
  echo "Structure your findings as:"
  echo "  - Key facts (objective information)"
  echo "  - Expert opinions (with sources)"
  echo "  - Sentiment (bullish/bearish/mixed)"
  echo "  - Data quality (high/medium/low)"
fi
