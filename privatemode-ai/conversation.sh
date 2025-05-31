#!/bin/bash

usage() {
    echo "Usage: $0 <prompt> <api_url>"
    echo "Example: $0 \"What is the meaning of life?\" http://localhost:8080"
    echo ""
    echo "Parameters:"
    echo "  prompt  - The prompt/question to send to the AI"
    echo "  api_url - API URL for the service (e.g., http://localhost:8080)"
    exit 1
}

cleanup() {
    rm -f "$TEMP_JSON_FILE"
}

trap cleanup EXIT

if [ "$#" -ne 2 ]; then
    usage
fi

PROMPT=$1
API_URL=$2

# Remove trailing slash if present
API_URL=${API_URL%/}

# Escape the prompt for JSON
PROMPT_JSON=$(echo "$PROMPT" | jq -Rs .)

TEMP_JSON_FILE=$(mktemp)

MODEL_ID="ibnzterrell/Meta-Llama-3.3-70B-Instruct-AWQ-INT4"

cat > "$TEMP_JSON_FILE" <<EOF
{
    "model": "$MODEL_ID",
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": $PROMPT_JSON
                }
            ]
        }
    ]
}
EOF

# echo "Generated JSON request:"
# cat "$TEMP_JSON_FILE"

timestamp=$(date +"%Y%m%d_%H%M%S")

# Validate JSON syntax
if ! jq empty "$TEMP_JSON_FILE" 2>/dev/null; then
    echo "Error: Generated JSON is invalid"
    echo "JSON content see logging/$timestamp.privatemode_request_json_error.json"
    cat "$TEMP_JSON_FILE" > "logging/$timestamp.privatemode_request_json_error.json"
    
    exit 1
fi

mkdir -p logging

start_time=$(date +%s)

# Test Endpoint
# Test if the API endpoint is reachable and has the required model
echo "Testing API endpoint..."
models_response=$(curl -s "$API_URL/v1/models")
if ! echo "$models_response" | jq -e ".data[] | select(.id == \"$MODEL_ID\")" > /dev/null; then
    echo "Error: Required model '$MODEL_ID' not found in API response"
    echo "Available models:"
    echo "$models_response" | jq -r '.data[].id // "No models found"'
    exit 1
fi
echo "API endpoint validated - required model found"

response=$(curl -s "$API_URL"/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d @"$TEMP_JSON_FILE")

end_time=$(date +%s)
response_time=$((end_time - start_time))

# echo "Response from API:"
# echo "$response" 

echo "$response" | jq > "logging/$timestamp.privatemode_conversation_response.json"
cat "$TEMP_JSON_FILE" > "logging/$timestamp.privatemode_conversation_request.json"

# Extract and display the content
content=$(echo "$response" | jq -r '.choices[0].message.content // "ERROR from script: No content found"')
echo "Chat completion output: $content"
echo "Request-to-response time: ${response_time} seconds"

# Also save the content to a markdown file
echo "$content" > "logging/$timestamp.privatemode_conversation_response.md"
