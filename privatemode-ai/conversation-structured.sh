#!/bin/bash

usage() {
    echo "Structured-Output Conversation Script for AI API"
    echo "Passing a lot of text to the AI and getting structured output for different caption suggestions as a json array."
    echo ""
    echo "Usage: $0 <prompt> <api_url> [json_schema_file]"
    echo "Example: $0 \"<a lot of text>\" http://localhost:8080 schema.json"
    echo ""
    echo "Parameters:"
    echo "  prompt          - Text to send to the AI"
    echo "  api_url         - API URL for the service (e.g., http://localhost:8080)"
    echo "  json_schema_file- (Optional) Path to a JSON schema file for structured output"
    exit 1
}

cleanup() {
    rm -f "$TEMP_JSON_FILE"
}

trap cleanup EXIT

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage
fi

TEXT=$1
API_URL=$2
SCHEMA_FILE=$3

PROMPT=$(cat <<EOF
You are an AI designed to generate descriptive captions for content.
Please provide a list of possible captions, each with a relevance score between 0 and 1 that indicates how well the caption describes the content.
Your response must be a JSON object matching the following schema:

- Include at least 3 captions.
- Do not include any extra information or explanation.

Example:

Task:
Given the content, return your output in the exact JSON structure as described above.

Content:

$TEXT
EOF
)

# Remove trailing slash if present
API_URL=${API_URL%/}

# Escape the prompt for JSON
PROMPT_JSON=$(echo "$PROMPT" | jq -Rs .)

TEMP_JSON_FILE=$(mktemp)

MODEL_ID="ibnzterrell/Meta-Llama-3.3-70B-Instruct-AWQ-INT4"
# MODEL_ID="google/gemma-3-27b-it"

# Prepare response_format if schema file is provided
RESPONSE_FORMAT=""
if [ -n "$SCHEMA_FILE" ]; then
    if ! [ -f "$SCHEMA_FILE" ]; then
        echo "Error: Schema file '$SCHEMA_FILE' not found."
        exit 1
    fi
    # Read and minify schema
    JSON_SCHEMA=$(jq -c . "$SCHEMA_FILE")
    RESPONSE_FORMAT=$(cat <<EOF
,
    "response_format": {
        "type": "json_schema",
        "json_schema": $JSON_SCHEMA
    }
EOF
)
fi

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
    ]$RESPONSE_FORMAT
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

response=$(curl -s $API_URL/v1/chat/completions \
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
echo "Chat completion output: "
echo "$content" | jq

echo "Request-to-response time: ${response_time} seconds"

# Also save the content to a markdown file
echo "$content" > "logging/$timestamp.privatemode_conversation_response.md"
