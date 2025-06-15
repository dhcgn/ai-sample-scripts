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
You job is to extract text from the images I provide you. Extract every bit of the text in the image. Don't say anything just do your job. Text should be same as in the images.

Things to avoid:
- Don't miss anything to extract from the images

Things to include:
- Include everything, even anything inside [], (), {} or anything.
- Include any repetitive things like "..." or anything
- If you think there is any mistake in image just include it too
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
    ]
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
echo "Chat completion output: $content"
echo "Request-to-response time: ${response_time} seconds"

# Also save the content to a markdown file
echo "$content" > "logging/$timestamp.privatemode_ocr_response.md"

