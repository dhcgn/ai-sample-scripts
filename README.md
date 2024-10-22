# ai-sample-acripts

Same sample scripts for different AI Services, written in bash or powershell.

## Multi-Modal

### Describe Image (gpt-4o-mini with vision)

[multi-modal/descripte-image.sh](multi-modal/descripte-image.sh)

```bash
bash pic.jpg 'What is in this image? Give a Description and a list of tags.'
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

## Tools

### ffmpeg

```bash
ffmpeg -i input.m4a -ss 00:00:0.0 -t 10 -b:a 96k output.mp3
```
