#!/bin/bash

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "Error: ANTHROPIC_API_KEY is not set." >&2
  exit 1
fi

# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_pdf_file>"
    echo "Example: $0 /path/to/document.pdf"
    exit 1
}

# Function to clean up temporary files
cleanup() {
    rm -f "$TEMP_JSON_FILE"
}

# Set up trap to clean up temporary files on script exit
trap cleanup EXIT

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi

# Assign argument to variable
PDF_FILE=$1

# Validate the file type
if [[ ! "$PDF_FILE" =~ \.pdf$ ]]; then
    echo "Error: The file must be a PDF."
    usage
fi

# First fetch the file
PDF_BASE64=$(base64 "$PDF_FILE" | tr -d '\n')

# Create a multiline variable for the text content
read -r -d '' TEXT_CONTENT << EOM
Give me the whole content of this file as markdown, only return the content of this file as markdown.
EOM

# Create temporary file for the JSON request body
TEMP_JSON_FILE=$(mktemp)

# Create the JSON request body using a here document
cat > "$TEMP_JSON_FILE" <<EOF
{
    "model": "claude-3-7-sonnet-20250219",
    "max_tokens": 64000,
    "messages": [{
        "role": "user",
        "content": [{
            "type": "document",
            "source": {
                "type": "base64",
                "media_type": "application/pdf",
                "data": "$PDF_BASE64"
            }
        },
        {
            "type": "text",
            "text": "$TEXT_CONTENT"
        }]
    }]
}
EOF

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Ensure the logging directory exists
mkdir -p logging

# Finally send the API request using the JSON body and capture the response
response=$(curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d @"$TEMP_JSON_FILE")

# Save the response to a file with the timestamp in the logging directory
echo "$response" | jq > "logging/$timestamp.response.json"
echo "$response" | jq -r '.content[0].text'> "logging/$timestamp.response.md"

# Save request body in the logging directory (excluding the base64 data for readability)
jq 'del(.messages[0].content[0].source.data)' "$TEMP_JSON_FILE" > "logging/$timestamp.request.json"

# Print the formatted output to the console
echo "$response" | jq -r '.content[0].text'
