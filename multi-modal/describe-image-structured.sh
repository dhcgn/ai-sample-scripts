#!/bin/bash

# Documentation: https://platform.openai.com/docs/api-reference/chat/create

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set." >&2
    exit 1
fi

# Check for required commands
for cmd in identify jq curl base64; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        if [ "$cmd" = "identify" ]; then
            echo "Please install ImageMagick to proceed." >&2
        fi
        exit 1
    fi
done

# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_image>"
    echo "Example: $0 /path/to/image.jpg"
    echo "Note: Image must be 1024x1024 pixels or smaller"
    exit 1
}

# Function to clean up temporary files
cleanup() {
    rm -f "$TEMP_BASE64_FILE" "$TEMP_JSON_FILE"
}

# Set up trap to clean up temporary files on script exit
trap cleanup EXIT

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi

# Assign arguments to variables
IMAGE_FILE=$1
PROMPT="What is in this image? Give a Description and a list of tags"

# Validate the file type (case insensitive)
if [[ ! "${IMAGE_FILE,,}" =~ \.(jpg|jpeg|png)$ ]]; then
    echo "Error: The image file must be a jpg, jpeg, or png file." >&2
    usage
fi

# Check if file exists
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file does not exist: $IMAGE_FILE" >&2
    exit 1
fi

# Get image dimensions using ImageMagick's identify command
dimensions=$(identify -format "%wx%h" "$IMAGE_FILE")
width=$(echo "$dimensions" | cut -d'x' -f1)
height=$(echo "$dimensions" | cut -d'x' -f2)

if [ "$width" -gt 1024 ] || [ "$height" -gt 1024 ]; then
    echo "Image dimensions ($dimensions) exceed maximum allowed size of 1024x1024. Resizing image..."
    temp_image=$(mktemp --suffix=.jpg)
    convert "$IMAGE_FILE" -resize 1024x1024\> "$temp_image"
    IMAGE_FILE="$temp_image"
    trap 'rm -f "$temp_image"' EXIT
fi

# Your script logic here
echo "Processing file: $IMAGE_FILE ($dimensions)"
echo "Using prompt: $PROMPT"

# Create temporary files
TEMP_BASE64_FILE=$(mktemp)
TEMP_JSON_FILE=$(mktemp)

# Base64 encode the image file to a temporary file
base64 "$IMAGE_FILE" > "$TEMP_BASE64_FILE"

# Create the JSON structure with the base64 content from file
cat > "$TEMP_JSON_FILE" << EOF
{
    "model": "gpt-4o-2024-08-06",
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": $(printf '%s' "$PROMPT" | jq -R .)
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "data:image/jpeg;base64,$(cat "$TEMP_BASE64_FILE")"
                    }
                }
            ]
        }
    ],
    "response_format": {
        "type": "json_schema",
        "json_schema": {
            "name": "image_description",
            "schema": {
                "type": "object",
                "properties": {
                    "tags": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        }
                    }
                },
                "required": ["tags"],
                "additionalProperties": false
            },
            "strict": true
        }
    }
}
EOF

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Make the API call and capture the response
response=$(curl -s "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d @"$TEMP_JSON_FILE")

# Ensure the logging directory exists
mkdir -p logging

# Save the response to a file with the timestamp in the logging directory
echo "$response" > "logging/$timestamp.response.json"

# Save request body in the logging directory (excluding the base64 data for readability)
echo "$TEMP_JSON_FILE" > "logging/$timestamp.request.json"

# Print the formatted output to the console
echo "$response" | jq -r '.choices[0].message.content'