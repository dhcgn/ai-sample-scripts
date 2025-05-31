#!/bin/bash

# Documentation: https://platform.openai.com/docs/api-reference/audio/create#transcriptions

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set." >&2
    exit 1
fi

# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_audio_file> <prompt> <language>"
    echo "Example: $0 /path/to/audio.mp4 'Your prompt here' en"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    usage
fi

# Assign arguments to variables
AUDIO_FILE=$1
PROMPT=$2
LANGUAGE=$3

# Validate the file type
if [[ ! "$AUDIO_FILE" =~ \.(mp3|m4a|mp4|wav)$ ]]; then
    echo "Error: The audio file must be an mp4 or wav file."
    usage
fi

# Your script logic here
echo "Processing file: $AUDIO_FILE"
echo "Using prompt: $PROMPT"
echo "Using language: $LANGUAGE"

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Make the API call and capture the response
response=$(curl -s --location 'https://api.openai.com/v1/audio/transcriptions' \
    --header "Authorization: Bearer $OPENAI_API_KEY" \
    --form "file=@\"$AUDIO_FILE\"" \
    --form "model=\"whisper-1\"" \
    --form "prompt=\"$PROMPT\"" \
    --form "response_format=\"text\"" \
    --form "language=\"$LANGUAGE\"")

# Ensure the logging directory exists
mkdir -p logging

# Save the response to a file with the timestamp in the logging directory
echo "$response" > "logging/$timestamp.response.json"

# Save request body in the logging directory
{
  echo "file=@\"$AUDIO_FILE\""
  echo "model=\"whisper-1\""
  echo "prompt=\"$PROMPT\""
  echo "response_format=\"text\""
  echo "language=\"$LANGUAGE\""
} >> "logging/$timestamp.request.json"

# Print the formatted output to the console
echo "$response"

# Clean up any temporary files if needed