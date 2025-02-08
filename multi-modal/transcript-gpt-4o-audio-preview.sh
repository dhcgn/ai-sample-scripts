#!/bin/bash

# Documentation: https://platform.openai.com/docs/api-reference/chat/create#chat-create-messages

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set." >&2
    exit 1
fi

# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_audio_file> <prompt>"
    echo "Example: $0 /path/to/audio.mp3 'Your prompt here'"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    usage
fi

# Assign arguments to variables
AUDIO_FILE=$1
PROMPT=$2

# Validate the file type
if [[ ! "$AUDIO_FILE" =~ \.(mp3|wav)$ ]]; then
    echo "Error: The audio file must be an mp3 or wav file."
    usage
fi

# Your script logic here
echo "Processing file: $AUDIO_FILE"
echo "Using prompt: $PROMPT"

# Base64 encode the audio file
AUDIO_BASE64=$(base64 < "$AUDIO_FILE" | tr -d '\n')

# Construct the JSON payload
JSON_PAYLOAD=$(jq -n \
    --arg model "gpt-4o-audio-preview" \
    --arg text "$PROMPT" \
    --arg audio "%%%AUDIO_BASE64%%%" \
    '{
        model: $model,
        modalities: ["text"],
        messages: [
            {
                role: "user",
                content: [
                    {type: "text", text: $text},
                    {
                        type: "input_audio",
                        input_audio: {
                            data: $audio,
                            format: "mp3"
                        }
                    }
                ]
            }
        ]
    }')

# Replace the placeholder with the actual audio data
JSON_PAYLOAD=${JSON_PAYLOAD/"%%%AUDIO_BASE64%%%"/$AUDIO_BASE64}    

# Save the JSON payload to a temporary file
TEMP_JSON_FILE=$(mktemp)
echo "$JSON_PAYLOAD" > "$TEMP_JSON_FILE"

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

# Save request body in the logging directory
echo "$JSON_PAYLOAD" > "logging/$timestamp.request.json"

# Print the formatted output to the console
echo "$response" | jq -r '.choices[0].message.content'

# Clean up the temporary file
rm "$TEMP_JSON_FILE"