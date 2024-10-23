#!/bin/bash

if [ -z "$OPENAI_API_KEY" ]; then
  echo "Error: OPENAI_API_KEY is not set." >&2
  exit 1
fi

# Function to display usage information
usage() {
  echo "Usage: $0 <prompt>"
  echo "Example: $0 'Today is a wonderful day to build something people love!'"
  exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  usage
fi

# Assign arguments to variables
PROMPT=$1

# Construct the JSON payload
JSON_PAYLOAD=$(jq -n \
  --arg model "tts-1-hd" \
  --arg input "$PROMPT" \
  --arg voice "alloy" \
  '{
    model: $model,
    input: $input,
    voice: $voice
  }')

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Make the API call and save the output to speech.mp3
curl -s "https://api.openai.com/v1/audio/speech" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  --output "speech_$timestamp.mp3"

# Print the full path of the generated speech file
echo "Speech file saved to: $(realpath "speech_$timestamp.mp3")"