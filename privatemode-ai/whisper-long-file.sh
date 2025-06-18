#!/bin/bash

# Script for transcribing long audio files using PrivateMode Whisper API with chunking and overlap
# Documentation: https://docs.privatemode.ai/api/speech-to-text

MODEL_NAME="openai/whisper-large-v3"
CHUNK_LENGTH=29
OVERLAP=5

set -euo pipefail

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

# Check for required commands
for cmd in ffprobe ffmpeg jq curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# Check argument count
if [ "$#" -ne 4 ]; then
    usage
fi

# Assign arguments
AUDIO_FILE="$1"
PROMPT="$2"
LANGUAGE="$3"
API_URL="$4"
API_URL="${API_URL%/}"

# Validate file type
if [[ ! "${AUDIO_FILE,,}" =~ \.(mp3|m4a|mp4|wav)$ ]]; then
    echo "Error: The audio file must be an mp3, m4a, mp4, or wav file." >&2
    usage
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: Audio file does not exist: $AUDIO_FILE" >&2
    exit 1
fi

# Ensure logging directory exists
mkdir -p logging

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Test API endpoint for required model
test_api_endpoint() {
    local api_url="$1"
    local model_name="$2"
    echo "Testing API endpoint..."
    local models_response
    models_response=$(curl -s "$api_url/v1/models")
    if ! echo "$models_response" | jq -e ".data[] | select(.id == \"$model_name\")" > /dev/null; then
        echo "Error: Required model '$model_name' not found in API response" >&2
        echo "Available models:" >&2
        echo "$models_response" | jq -r '.data[].id // "No models found"' >&2
        exit 1
    fi
    echo "API endpoint validated - required model found"
}

# Function to split audio into chunks with overlap
split_audio_chunks() {
    local input_file="$1"
    local chunk_length="$2"
    local overlap="$3"
    local duration
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
    local duration_int=${duration%.*}
    local start=0
    local idx=0
    local chunk_files=()
    while [ "$start" -lt "$duration_int" ]; do
        local chunk_file
        chunk_file=$(mktemp --suffix=.${input_file##*.})
        ffmpeg -y -hide_banner -loglevel error -ss "$start" -t "$chunk_length" -i "$input_file" "$chunk_file"
        chunk_files+=("$chunk_file")
        echo "$chunk_file"
        start=$((start + chunk_length - overlap))
        idx=$((idx + 1))
    done
    # No need to echo all chunk_files at once; each is echoed above
}

# Function to clean up chunk files
cleanup_chunks() {
    local files=("$@")
    for f in "${files[@]}"; do
        rm -f "$f"
    done
}

# Function to transcribe a single chunk
transcribe_chunk() {
    local chunk_file="$1"
    local prompt="$2"
    local language="$3"
    local api_url="$4"
    local model_name="$5"
    local ts="$6"
    local idx="$7"
    local log_prefix="logging/${ts}_chunk${idx}"

    # Prepare curl command
    local curl_cmd
    read -r -d '' curl_cmd <<EOF
curl -s -w "\n%{http_code}" --location "$api_url/v1/audio/transcriptions" \
  --form "file=@$chunk_file" \
  --form "model=$model_name" \
  --form "prompt=$prompt" \
  --form "language=$language"
EOF

    # Log the curl command
    eval echo "$curl_cmd" > "${log_prefix}.privatemode_whisper_request.json"

    # Execute the curl command
    local curl_response
    curl_response=$(eval "$curl_cmd")

    # Extract status code and body
    local status_code
    status_code=$(echo "$curl_response" | tail -n1)
    local response_body
    response_body=$(echo "$curl_response" | sed '$d')

    # Save the response
    echo "$response_body" > "${log_prefix}.privatemode_whisper_response.json"

    if [ "$status_code" -ne 200 ]; then
        echo "Error: API request failed for chunk $idx with status code $status_code" >&2
        echo "Response body: $response_body" >&2
        return 1
    fi

    # Extract text from response
    local text
    text=$(echo "$response_body" | jq -r '.text // empty')
    echo "$text"
}

# Main logic
main() {
    test_api_endpoint "$API_URL" "$MODEL_NAME"

    # Split audio into chunks
    echo "Splitting audio file into chunks..."
    mapfile -t chunk_files < <(split_audio_chunks "$AUDIO_FILE" "$CHUNK_LENGTH" "$OVERLAP")
    echo "Total chunks: ${#chunk_files[@]}"

    # Transcribe each chunk and concatenate results
    local all_text=""
    local idx=0
    for chunk in "${chunk_files[@]}"; do
        echo "Transcribing chunk $((idx+1))/${#chunk_files[@]}: $chunk"
        chunk_text=$(transcribe_chunk "$chunk" "$PROMPT" "$LANGUAGE" "$API_URL" "$MODEL_NAME" "$timestamp" "$idx")
        all_text+="Chunk $((idx+1)):\nTranscription: $chunk_text\n\n"
        idx=$((idx+1))
    done

    # Clean up chunk files
    cleanup_chunks "${chunk_files[@]}"

    # Save and print the concatenated result
    echo -e "$all_text" > "logging/${timestamp}.privatemode_whisper_full_transcript.txt"
    echo "\n--- Full Transcript ---"
    echo -e "$all_text"
}

main "$@"
