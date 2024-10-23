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

### Text-to-Speech

[text-to-speech/text-to-speech.sh](text-to-speech/text-to-speech.sh)

```bash
bash text-to-speech/text-to-speech.sh "Hallo! mein Name ist Franz."
```

```text
Speech file saved to: /home/user/ai-sample-acripts/speech_20241023_122002.mp3
```

## Tools

### ffmpeg

```bash
ffmpeg -i input.m4a -ss 00:00:0.0 -t 10 -b:a 96k output.mp3
```
