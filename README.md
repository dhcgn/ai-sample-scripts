# ai-sample-acripts

Same sample scripts for different AI Services, written in bash or powershell.

## Multi-Modal

### Describe Image (gpt-4o-mini with vision)

[multi-modal/describe-image.sh](multi-modal/describe-image.sh)

```bash
bash multi-modal/describe-image.sh pic.jpg 'What is in this image? Give a Description and a list of tags.'
```

```text
### Description
The image captures a scene of a young child and an adult walking along a path in a residential area. The child, wearing a purple jacket and a pink hat, appears to be joyfully posing or dancing while holding a small decorated stick. The adult, who is further back on the path, is wearing a dark coat and seems to be looking at the child, possibly smiling or engaging with her. The background features houses and greenery typical of a neighborhood setting.

### Tags
- Child
- Adult
- Walking
- Residential area
- Joyful
- Nature
- Family
- Pathway
- Outdoor activity
- Smiling
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
