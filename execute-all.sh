#!/bin/bash

# --- API Key Checks ---
MISSING_KEYS=()


# --- Set script directory and use relative paths for key files ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check and export OpenAI API Key
OPENAI_KEY_FILE="$SCRIPT_DIR/.secrets/OPENAI_API_KEY.txt"
if [ -z "$OPENAI_API_KEY" ]; then
    if [ -f "$OPENAI_KEY_FILE" ]; then
        OPENAI_API_KEY=$(cat "$OPENAI_KEY_FILE")
        export OPENAI_API_KEY
    else
        MISSING_KEYS+=("OPENAI_API_KEY")
    fi
fi

# Check and export Anthropic API Key
ANTHROPIC_KEY_FILE="$SCRIPT_DIR/.secrets/ANTHROPIC_API_KEY.txt"
if [ -z "$ANTHROPIC_API_KEY" ]; then
    if [ -f "$ANTHROPIC_KEY_FILE" ]; then
        ANTHROPIC_API_KEY=$(cat "$ANTHROPIC_KEY_FILE")
        export ANTHROPIC_API_KEY
    else
        MISSING_KEYS+=("ANTHROPIC_API_KEY")
    fi
fi

# Check and export Mistral API Key
MISTRAL_KEY_FILE="$SCRIPT_DIR/.secrets/MISTRAL_API_KEY.txt"
if [ -z "$MISTRAL_API_KEY" ]; then
    if [ -f "$MISTRAL_KEY_FILE" ]; then
        MISTRAL_API_KEY=$(cat "$MISTRAL_KEY_FILE")
        export MISTRAL_API_KEY
    else
        MISSING_KEYS+=("MISTRAL_API_KEY")
    fi
fi

# Check and export AssemblyAI API Key
ASSEMBLYAI_KEY_FILE="$SCRIPT_DIR/.secrets/ASSEMBLYAI_API_KEY.txt"
if [ -z "$ASSEMBLYAI_API_KEY" ]; then
    if [ -f "$ASSEMBLYAI_KEY_FILE" ]; then
        ASSEMBLYAI_API_KEY=$(cat "$ASSEMBLYAI_KEY_FILE")
        export ASSEMBLYAI_API_KEY
    else
        MISSING_KEYS+=("ASSEMBLYAI_API_KEY")
    fi
fi

if [ ${#MISSING_KEYS[@]} -ne 0 ]; then
    echo "Missing API keys: ${MISSING_KEYS[*]}"
    exit 1
fi

echo "All required API keys are set."

# --- Script Execution ---
set -e


# List of scripts to run (relative to workspace root)
SCRIPTS=(
    "moderation/moderation.sh 'Test moderation input.'"
    "multi-modal/describe-image.sh test-data/pdf/simple.jpg 'Describe this image.'"
    "multi-modal/describe-image-structured.sh test-data/pdf/simple.jpg"
    "multi-modal/transcript-gpt-4o-audio-preview.sh test-data/TheFutureofWomeninFlying.mp3 'Transcribe this audio.'"
    "pdf/pdf-to-text-with-visuals-anthropic.sh test-data/pdf/sample.pdf"
    "pdf/pdf-to-text-with-visuals-mistral.sh test-data/pdf/sample.pdf"
    "text-to-speech/text-to-speech.sh 'Hello, this is a test.'"
    "transcript/assemblyai.sh test-data/TheFutureofWomeninFlying.mp3"
    "transcript/openai_transcribe.sh test-data/TheFutureofWomeninFlying.mp3 'Transcribe this audio.' en"
    "transcript/whisper.sh test-data/TheFutureofWomeninFlying.mp3 'Transcribe this audio.' en"
    "privatemode-ai/conversation.sh 'Hello, how are you?' http://localhost:8080"
    "privatemode-ai/conversation-structured.sh 'Invoice of a NVIDIA GTX 4090 from amazon.de' privatemode-ai/caption_list.schema.json http://localhost:8080"
    "privatemode-ai/ocr.sh test-data/pdf/simple.jpg http://localhost:8080"
)

for entry in "${SCRIPTS[@]}"; do
    script=$(echo "$entry" | awk '{print $1}')
    if [ ! -f "$script" ]; then
        echo "Script not found: $script. Skipping."
        continue
    fi
    echo -e "\n--- Running: $entry ---"
    eval bash "$entry"
    echo -e "--- Finished: $entry ---\n"
    sleep 1
    # Optional: Remove 'set -e' above if you want to continue on error
    # and add: if [ $? -ne 0 ]; then echo "Error running $entry"; fi
    # For now, script will exit on first error
    # Remove 'set -e' if you want to run all regardless of errors
    # and handle errors per-script
    #
    # To continue on error, comment out 'set -e' and uncomment below:
    # if ! eval bash $entry; then
    #     echo "Error running $entry"
    # fi
    # echo -e "--- Finished: $entry ---\n"
done

echo "All scripts executed."
