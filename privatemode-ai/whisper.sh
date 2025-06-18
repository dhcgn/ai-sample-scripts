#!/bin/bash
MODEL_NAME="openai/whisper-large-v3"

# Documentation: https://docs.privatemode.ai/api/speech-to-text

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set." >&2
    exit 1
fi


# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_audio_file> <prompt> <language> <api_url>"
    echo "Example: $0 /path/to/audio.mp4 'Your prompt here' en http://localhost:8080"
    echo "  path_to_audio_file - Path to the MP3, M4A, MP4, or WAV file to process"
    echo "  prompt            - Prompt text for the transcription model"
    echo "  language          - Language code (e.g., en, de, fr)"
    echo "  api_url           - API URL for the service (e.g., http://localhost:8080)"
    exit 1
}

# Check if ffprobe and ffmpeg are available
if ! command -v ffprobe >/dev/null 2>&1; then
    echo "Error: ffprobe is not installed or not in PATH. Please install FFmpeg." >&2
    exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: ffmpeg is not installed or not in PATH. Please install FFmpeg." >&2
    exit 1
fi

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    usage
fi



# Assign arguments to variables
AUDIO_FILE=$1
PROMPT=$2
LANGUAGE=$3
API_URL=$4

# Remove trailing slash if present
API_URL=${API_URL%/}

# Check audio duration and trim if necessary
TMP_AUDIO_FILE=""
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE")
DURATION_INT=${DURATION%.*}
if [ "$DURATION_INT" -gt 29 ]; then
    echo "Warning: The audio file is longer than 29 seconds. Trimming to 29 seconds."
    TMP_AUDIO_FILE=$(mktemp --suffix=.${AUDIO_FILE##*.})
    ffmpeg -y -i "$AUDIO_FILE" -t 29 "$TMP_AUDIO_FILE" < /dev/null
    AUDIO_FILE="$TMP_AUDIO_FILE"
    # Clean up temp file on exit
    trap 'rm -f "$TMP_AUDIO_FILE"' EXIT
fi


# Validate the file type
if [[ ! "$AUDIO_FILE" =~ \.(mp3|m4a|mp4|wav)$ ]]; then
    echo "Error: The audio file must be an mp3, m4a, mp4, or wav file."
    usage
fi

# Your script logic here
echo "Processing file: $AUDIO_FILE"
echo "Using prompt: $PROMPT"
echo "Using language: $LANGUAGE"

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")



# Test Endpoint
echo "Testing API endpoint..."
models_response=$(curl -s "$API_URL/v1/models")
if ! echo "$models_response" | jq -e ".data[] | select(.id == \"$MODEL_NAME\")" > /dev/null; then
    echo "Error: Required model '$MODEL_NAME' not found in API response"
    echo "Available models:"
    echo "$models_response" | jq -r '.data[].id // "No models found"'
    exit 1
fi
echo "API endpoint validated - required model found"


# Make the API call and capture both the response body and status code
curl_response=$(curl -s -w "\n%{http_code}" --location "$API_URL/v1/audio/transcriptions" \
    --form "file=@\"$AUDIO_FILE\"" \
    --form "model=\"$MODEL_NAME\"" \
    --form "prompt=\"$PROMPT\"" \
    --form "language=\"$LANGUAGE\"")

# Extract the status code (last line) and body (all but last line)
status_code=$(echo "$curl_response" | tail -n1)
response_body=$(echo "$curl_response" | sed '$d')

# Ensure the logging directory exists
mkdir -p logging
# Save request body in the logging directory
{
  echo "file=@\"$AUDIO_FILE\""
  echo "model=\"$MODEL_NAME\""
  echo "prompt=\"$PROMPT\""
  echo "language=\"$LANGUAGE\""
} >> "logging/$timestamp.privatemode_whisper_request.json"

# Output status code and body
echo "Status code: $status_code"
if [ "$status_code" -ne 200 ]; then
    echo "Error: API request failed with status code $status_code"
    echo "Response body: $response_body"
    exit 1
fi

# Save the response to a file with the timestamp in the logging directory
echo "$response_body" > "logging/$timestamp.privatemode_whisper_response.json"

# Print the formatted output to the console
echo "$response_body" | jq
