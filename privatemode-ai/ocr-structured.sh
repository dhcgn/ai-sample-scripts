#!/bin/bash

usage() {
    echo "Usage: $0 <path_to_file> <api_url>"
    echo "Example: $0 /path/to/image.jpg http://localhost:8080"
    echo "Example: $0 /path/to/image.png http://localhost:8080"
    echo ""
    echo "Parameters:"
    echo "  path_to_file - Path to the JPG or PNG file to process"
    echo "  api_url      - API URL for the service (e.g., http://localhost:8080)"
    exit 1
}

MODEL_NAME="leon-se/gemma-3-27b-it-fp8-dynamic"

read -r -d '' PROMPT << EOM
You are an OCR extraction assistant. Your job is to analyze the provided image and return a structured JSON object that matches the following schema:

{
  "document_type": "string (e.g. letter, picture, receipt, screenshot, blank page, or other)",
  "ocr_text": "string (all text extracted from the image, including every visible character, symbol, or mark)",
  "tags": ["string", ...] (a list of descriptive tags for the image),
  "description": "string (a short text describing what can be seen in the image)"
}

Instructions:
- Extract every bit of text from the image, including anything inside [], (), {}, or any other symbols.
- Include all repetitive elements, such as "..." or similar marks.
- If there are mistakes or unclear text in the image, include them as they appear.
- Do not omit any content, even if it seems irrelevant.
- For document_type, choose the best match from: letter, picture, receipt, screenshot, blank page, or other.
- For tags, provide a list of relevant keywords describing the image (e.g., "handwritten", "invoice", "screenshot", "logo").
- For description, provide a short text describing what can be seen in the image (e.g., "A handwritten note with a signature at the bottom.").

Respond ONLY with a valid JSON object matching the schema above. Do not include any extra explanation or commentary.
EOM

cleanup() {
    rm -f "$TEMP_JSON_FILE"
}

trap cleanup EXIT

if [ "$#" -ne 2 ]; then
    usage
fi


# Rename PDF_FILE to IMAGE_FILE for clarity
IMAGE_FILE=$1
API_URL=$2


# Remove trailing slash if present
API_URL=${API_URL%/}


# Check if the input file is a supported image type
if [[ ! "$IMAGE_FILE" =~ \.(jpg|jpeg|png)$ ]]; then
    echo "Error: The file must be a JPG, JPEG, or PNG file."
    usage
fi


# Determine the MIME type based on file extension
if [[ "$IMAGE_FILE" =~ \.(jpg|jpeg)$ ]]; then
    MIME_TYPE="image/jpeg"
elif [[ "$IMAGE_FILE" =~ \.png$ ]]; then
    MIME_TYPE="image/png"
fi


# Encode the image file as base64
FILE_BASE64=$(base64 "$IMAGE_FILE" | tr -d '\n')

# Escape the prompt for JSON
PROMPT_JSON=$(echo "$PROMPT" | jq -Rs .)

TEMP_JSON_FILE=$(mktemp)

# Prepare response_format using ocr.schema.json
SCHEMA_FILE="$(dirname "$0")/ocr.schema.json"
RESPONSE_FORMAT=""
if [ -f "$SCHEMA_FILE" ]; then
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
    "model": "$MODEL_NAME",
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": $PROMPT_JSON
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "data:$MIME_TYPE;base64,$FILE_BASE64"
                    }
                }
            ]
        }
    ]$RESPONSE_FORMAT
}
EOF

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
if ! echo "$models_response" | jq -e ".data[] | select(.id == \"$MODEL_NAME\")" > /dev/null; then
    echo "Error: Required model '$MODEL_NAME' not found in API response"
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

echo "$response" | jq > "logging/$timestamp.privatemode_ocr_response.json"
jq 'del(.messages[0].content[1].image_url.url)' "$TEMP_JSON_FILE" > "logging/$timestamp.privatemode_ocr_request.json"

# Extract and display the content
content=$(echo "$response" | jq -r '.choices[0].message.content // "ERROR from script: No content found"')
echo "Chat completion output: "
echo "$content" | jq
echo "Request-to-response time: ${response_time} seconds"

# Also save the content to a markdown file
echo "$content" > "logging/$timestamp.privatemode_ocr_response.md"

