#!/bin/bash

if [ -z "$MISTRAL_API_KEY" ]; then
  echo "Error: MISTRAL_API_KEY is not set." >&2
  exit 1
fi

usage() {
    echo "Usage: $0 <path_to_pdf_file>"
    echo "Example: $0 /path/to/document.pdf"
    exit 1
}

cleanup() {
    rm -f "$TEMP_JSON_FILE"
}

trap cleanup EXIT

if [ "$#" -ne 1 ]; then
    usage
fi

PDF_FILE=$1

if [[ ! "$PDF_FILE" =~ \.pdf$ ]]; then
    echo "Error: The file must be a PDF."
    usage
fi

PDF_BASE64=$(base64 "$PDF_FILE" | tr -d '\n')

TEMP_JSON_FILE=$(mktemp)

cat > "$TEMP_JSON_FILE" <<EOF
{
    "model": "mistral-ocr-latest",
    "document": {
        "type": "document_url",
        "document_url": "data:application/pdf;base64,$PDF_BASE64"
    },
    "include_image_base64": false
}
EOF

timestamp=$(date +"%Y%m%d_%H%M%S")
mkdir -p logging

response=$(curl -s https://api.mistral.ai/v1/ocr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MISTRAL_API_KEY}" \
  -d @"$TEMP_JSON_FILE")

echo "$response" | jq > "logging/$timestamp.mistral_ocr_response.json"
echo "$response" | jq -r '.pages[] | "---\nPage: \(.index)\n---\n\(.markdown)\n"' > "logging/$timestamp.mistral_ocr_response.md"
jq 'del(.document.document_url)' "$TEMP_JSON_FILE" > "logging/$timestamp.mistral_ocr_request.json"

echo "$response" | jq

