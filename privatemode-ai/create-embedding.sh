#!/bin/bash

# Script: create-embedding.sh
# Description: Reads one or more files, each line is truncated to 512 chars, sends all lines as input to the embedding API, and prints the resulting vectors (tab-separated).
# Result file can be tested with https://projector.tensorflow.org/
# Usage: ./create-embedding.sh <file1> [file2 ...] <api_url>
# Example: ./create-embedding.sh input.txt http://localhost:9876

set -euo pipefail

# Check for required commands
for cmd in jq curl; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done



usage() {
    echo "Usage: $0 <input_file> <output_tsv_file> <api_url>"
    echo "Each line in the file will be truncated to 512 characters and embedded."
    echo "Example: $0 input.txt output.tsv http://localhost:9876"
    exit 1
}

if [ "$#" -ne 3 ]; then
    usage
fi

INPUT_FILE="$1"
OUTPUT_TSV_FILE="$2"
API_URL="$3"

# Validate file
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE" >&2
    exit 1
fi
if [ ! -r "$INPUT_FILE" ]; then
    echo "Error: File not readable: $INPUT_FILE" >&2
    exit 1
fi


# Print the number of lines in the input file
num_lines=$(wc -l < "$INPUT_FILE")
echo "Number of lines in input file: $num_lines"

# Read and process lines
INPUT_LINES=()
while IFS= read -r line; do
    # Truncate to 512 chars
    INPUT_LINES+=("${line:0:512}")
done < "$INPUT_FILE"

if [ "${#INPUT_LINES[@]}" -eq 0 ]; then
    echo "Error: No input lines found in file." >&2
    exit 1
fi

# Prepare JSON array
JSON_INPUT=$(printf '%s\n' "${INPUT_LINES[@]}" | jq -R . | jq -s .)


MODEL_ID="intfloat/multilingual-e5-large-instruct"

REQUEST_JSON=$(mktemp)
RESPONSE_JSON=$(mktemp)
trap 'rm -f "$REQUEST_JSON" "$RESPONSE_JSON"' EXIT

cat > "$REQUEST_JSON" <<EOF
{
    "input": $JSON_INPUT,
    "model": "$MODEL_ID",
    "encoding_format": "float"
}
EOF


# Logging setup
timestamp=$(date +"%Y%m%d_%H%M%S")
mkdir -p logging

# Test Endpoint
echo "Testing API endpoint..."
models_response_and_status=$(curl -s -w "\n%{http_code}" "$API_URL/v1/models")
models_response=$(echo "$models_response_and_status" | sed '$d')
http_status=$(echo "$models_response_and_status" | tail -n1)

if [ "$http_status" -ne 200 ]; then
    echo "Error: API endpoint returned HTTP status $http_status" >&2
    echo "Response: $models_response" >&2
    exit 1
fi

if ! echo "$models_response" | jq -e ".data[] | select(.id == \"$MODEL_ID\")" > /dev/null; then
    echo "Error: Required model '$MODEL_ID' not found in API response" >&2
    echo "Available models:" >&2
    echo "$models_response" | jq -r '.data[].id // "No models found"' >&2
    exit 1
fi
echo "API endpoint validated - required model found"


# Save request to logging
cat "$REQUEST_JSON" > "logging/$timestamp.privatemode_embeddings_request.json"

# Send request and save response directly to logging
curl -s -X POST "$API_URL/v1/embeddings" \
    -H "Content-Type: application/json" \
    --data-binary "@$REQUEST_JSON" \
    -o "logging/$timestamp.privatemode_embeddings_response.json"


# Extract vectors as tab-separated values and save to TSV file (do not print to stdout)
jq -r '.data[] | select(.object=="embedding") | .embedding | map(tostring) | join("\t")' "logging/$timestamp.privatemode_embeddings_response.json" > "$OUTPUT_TSV_FILE"

# Print the path to the response log file and TSV file
echo "Response JSON saved to: logging/$timestamp.privatemode_embeddings_response.json"
echo "Vectors TSV saved to: $OUTPUT_TSV_FILE"
