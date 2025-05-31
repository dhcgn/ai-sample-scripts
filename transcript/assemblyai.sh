#!/bin/bash

if [ -z "$ASSEMBLYAI_API_KEY" ]; then
    echo "Error: ASSEMBLYAI_API_KEY is not set." >&2
    exit 1
fi

# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_audio_file>"
    echo "Example: $0 /path/to/audio.mp4"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi

# Assign arguments to variables
AUDIO_FILE=$1

# Validate the file type
if [[ ! "$AUDIO_FILE" =~ \.(mp3|m4a|mp4|wav|ogg)$ ]]; then
    echo "Error: The audio file must be an mp3, m4a, mp4, wav, or ogg file."
    usage
fi

# Your script logic here
echo "Processing file: $AUDIO_FILE"

# Create a timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Upload the audio file and capture the upload URL
upload_response=$(curl -s --location 'https://api.assemblyai.com/v2/upload' \
    --header "Authorization: $ASSEMBLYAI_API_KEY" \
    --header "Content-Type: audio/ogg" \
    --data-binary "@$AUDIO_FILE")

upload_url=$(echo "$upload_response" | jq -r '.upload_url')

if [ -z "$upload_url" ]; then
    echo "Error: Failed to upload the audio file."
    exit 1
fi

# Make the API call to transcribe the audio file and capture the response
transcription_response=$(curl -s --location 'https://api.assemblyai.com/v2/transcript' \
    --header "Authorization: $ASSEMBLYAI_API_KEY" \
    --header "Content-Type: application/json" \
    --data "{\"audio_url\": \"$upload_url\", \"language_detection\": true}")

transcription_id=$(echo "$transcription_response" | jq -r '.id')

if [ -z "$transcription_id" ]; then
    echo "Error: Failed to initiate transcription."
    exit 1
fi

# Ensure the logging directory exists
mkdir -p logging

# Save the responses to files with the timestamp in the logging directory
echo "$upload_response" > "logging/$timestamp.upload_response.json"
echo "$transcription_response" > "logging/$timestamp.transcription_response.json"

# Poll for the transcription result
status="queued"
while [ "$status" != "completed" ]; do
    sleep 5
    status_response=$(curl -s --location "https://api.assemblyai.com/v2/transcript/$transcription_id" \
        --header "Authorization: $ASSEMBLYAI_API_KEY")
    status=$(echo "$status_response" | jq -r '.status')
done

# Save the final transcription result
echo "$status_response" > "logging/$timestamp.final_transcription.json"

# Print the formatted output to the console
echo "$status_response" | jq -r '.text'

# Clean up any temporary files if needed
