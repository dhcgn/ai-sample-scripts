#!/bin/bash

if [ -z "$OPENAI_API_KEY" ]; then
  echo "Error: OPENAI_API_KEY is not set." >&2
  exit 1
fi

# Function to display usage information
usage() {
    echo "Usage: $0 <text>"
    echo "Example: $0 'This is a sample text to classify.'"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi

# Assign arguments to variables
TEXT=$1

# Construct the JSON payload
JSON_PAYLOAD=$(jq -n \
    --arg model "omni-moderation-latest" \
    --arg input "$TEXT" \
    '{
        model: $model,
        input: $input
    }')

# Make the API call
# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Ensure the logging directory exists
mkdir -p logging

# Make the API call and capture the response
response=$(curl -s "https://api.openai.com/v1/moderations" \
    -X POST \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Save the response to a file with the timestamp in the logging directory
echo "$response" > "logging/$timestamp.response.json"

# Save request body in the logging directory
echo "$JSON_PAYLOAD" > "logging/$timestamp.request.json"

# Print the formatted output to the console
echo "$response" | jq