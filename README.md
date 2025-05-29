[![Check Shell Scripts](https://github.com/dhcgn/ai-sample-scripts/actions/workflows/check-shell-scripts.yml/badge.svg)](https://github.com/dhcgn/ai-sample-scripts/actions/workflows/check-shell-scripts.yml)

# ai-sample-acripts

Same sample scripts for different AI Services, written in bash or powershell.

## Multi-Modal

### Describe Image (gpt-4o-mini with vision)

[multi-modal/describe-image.sh](multi-modal/describe-image.sh)

```bash
export OPENAI_API_KEY=$(cat .secrets/OPENAI_API_KEY.txt)
bash download_test_images.sh
bash multi-modal/describe-image.sh test-data/images/n01494475_hammerhead.JPEG 'What is in this image? Give a Description and a list of tags.'
```

```text
The image features a man standing on a sandy beach holding two fish in his hands. He is shirtless, wearing floral swim shorts and flip-flops. The background includes a view of the ocean under a clear blue sky, with some distant land visible on the horizon.

### Description:
- Setting: Beach environment
- Subject: A man holding two fish
- Clothing: Floral swim shorts, flip-flops, no shirt
- Mood: Casual and relaxed

### Tags:
- Beach
- Fishing
- Outdoors
- Summer
- Catch of the day
- Marine life
- Recreation
- Sports
- Ocean
- Coastal
```
### Describe Image with structured output (gpt-4o-mini with vision)

[multi-modal/describe-image-structured.sh](multi-modal/describe-image-structured.sh)

```bash
bash multi-modal/describe-image-structured.sh test-data/images/n01494475_hammerhead.JPEG 
```

```json
{
  "tags": [
    {
      "tag": "man",
      "precision": 0.99
    },
    {
      "tag": "beach",
      "precision": 0.95
    },
    {
      "tag": "sand",
      "precision": 0.95
    },
    {
      "tag": "ocean",
      "precision": 0.95
    },
    {
      "tag": "fish",
      "precision": 0.98
    },
    {
      "tag": "holding",
      "precision": 0.97
    },
    {
      "tag": "shorts",
      "precision": 0.92
    },
    {
      "tag": "sunglasses",
      "precision": 0.88
    },
    {
      "tag": "hat",
      "precision": 0.90
    },
    {
      "tag": "daytime",
      "precision": 0.94
    }
  ]
}
```

### Transcript Audio (gpt-4o-audio-preview-2024-10-01)

[multi-modal/transcript-gpt-4o-audio-preview.sh](multi-modal/transcript-gpt-4o-audio-preview.sh)

```bash
bash multi-modal/transcript-gpt-4o-audio-preview.sh file.mp3 "Write me back the ONLY content, as accurately as possible! Do not return anything else!"
```

### Transcript Audio (whisper-1)

[transcript/whisper.sh](transcript/whisper.sh)

```bash
bash transcript/whisper.sh file.mp3 "Medical Interview" de
```

```bash
bash transcript/whisper.sh test-data/TheFutureofWomeninFlying.mp3 "Speach of Amelia Earhart" "en"
```

### Transcript Audio (assemblyai)

```bash
bash transcript/assemblyai.sh test-data/TheFutureofWomeninFlying.mp3 
```

### Transcript Audio (gpt-4o-transcribe)

```bash
bash transcript/openai_transcribe.sh test-data/TheFutureo
fWomeninFlying.mp3 "Speach of Amelia Earhart" "en"
```

### Text-to-Speech

[text-to-speech/text-to-speech.sh](text-to-speech/text-to-speech.sh)

```bash
bash text-to-speech/text-to-speech.sh "Hallo! mein Name ist Franz."
```

```text
Speech file saved to: /home/user/ai-sample-acripts/speech_20241023_122002.mp3
```

### Moderation

[moderation/moderation.sh](moderation/moderation.sh)

```bash
bash moderation/moderation.sh "Your are dump"
```

```json
{
  "id": "modr-a75d9ae4e63e1fcdad3192f54381bf44",
  "model": "omni-moderation-latest",
  "results": [
    {
      "flagged": true,
      "categories": {
        "harassment": true,
        "harassment/threatening": false,
        "sexual": false,
        "hate": false,
        "hate/threatening": false,
        "illicit": false,
        "illicit/violent": false,
        "self-harm/intent": false,
        "self-harm/instructions": false,
        "self-harm": false,
        "sexual/minors": false,
        "violence": false,
        "violence/graphic": false
      },
      "category_scores": {
        "harassment": 0.721970864775024,
        "harassment/threatening": 0.0008189714985138275,
        "sexual": 0.00014325365947100792,
        "hate": 0.00010322310367548195,
        "hate/threatening": 0.0000015936620247162786,
        "illicit": 0.0037773915102819354,
        "illicit/violent": 0.000008092757566536092,
        "self-harm/intent": 0.00022735757340977802,
        "self-harm/instructions": 0.00022788290577331583,
        "self-harm": 0.0005064509108778008,
        "sexual/minors": 0.0000027535691114583474,
        "violence": 0.0005600758955536546,
        "violence/graphic": 0.000007484622751061123
      },
      ...
```

### PDF to Text with Visuals

- [pdf/pdf-to-text-with-visuals-anthropic.sh](pdf/pdf-to-text-with-visuals-anthropic.sh)
- [pdf/pdf-to-text-with-visuals-mistral.sh](pdf/pdf-to-text-with-visuals-mistral.sh)


This script extracts text content from a PDF file and uses the `claude-3-7-sonnet-20250219` model from Anthropic to process the content. You need to provide an API key by setting the `ANTHROPIC_API_KEY` environment variable.

The script uses the following key parameters:
- **max_tokens**: Currently set to 1024 tokens (can be increased up to 8192 tokens with claude-3-7-sonnet-20250219)
- Note: The model may stop generating before reaching this limit

```bash
bash pdf/pdf-to-text-with-visuals-anthropic.sh pdf/sample_data/sample.pdf
```

```plain
What are 5 facts about the human brain?

Here are five interesting facts about the human brain:
[...]
```

## Privatemode AI

Privatemode AI is a secure generative AI platform developed by Edgeless Systems, designed specifically to address the privacy and data protection concerns organizations face when using AI services. 

Unlike conventional AI solutions, Privatemode AI leverages **confidential computing** and **end-to-end encryption** to ensure that all data—from user input, through processing, to output—remains fully protected and inaccessible to anyone except the user.

### Prerequisites

This example uses a Privatemode AI proxy running on a server at IP address `192.168.3.10`.

The Docker image `ghcr.io/edgelesssys/privatemode/privatemode-proxy:latest` is running on `http://192.168.3.10:9876/`. For more details, see [privatemode-ai/README.md](privatemode-ai/README.md).

### Conversation

```bash
bash privatemode-ai/conversation.sh "Capitel of France?" http://192.168.3.10:9876
# Chat completion output: The capital of France is Paris.
```

### OCR

```bash
bash privatemode-ai/ocr.sh pdf/sample_data/simple.jpg http://192.168.3.10:9876/
# Chat completion output: This is a Test

bash privatemode-ai/ocr.sh pdf/sample_data/simple.png http://192.168.3.10:9876/
# Chat completion output: This is a Test
```

## Tools

### ffmpeg

```bash
ffmpeg -i input.m4a -ss 00:00:0.0 -t 10 -b:a 96k output.mp3
```

# Good Practice: Setting API Keys

To work efficiently with this collection of scripts, set your API keys as environment variables in your shell profile.

1. Open your profile file (e.g., `~/.bashrc` or `~/.bash_profile`) in a text editor:
   ```bash
   nano ~/.bashrc
   ```
2. Add your API keys (replace `...` with your actual keys):
   ```bash
   export MISTRAL_API_KEY=...
   export ANTHROPIC_API_KEY=...
   export OPENAI_API_KEY=...
   ```
3. Load your profile to apply the changes:
   ```bash
   source ~/.bashrc
   ```
