# ai-sample-acripts

Same sample scripts for different AI Services, written in bash or powershell.

## Multi-Modal

### gpt-4o-audio-preview-2024-10-01

[multi-modal/transcript-gpt-4o-audio-preview.sh](multi-modal/transcript-gpt-4o-audio-preview.sh)

```bash
bash multi-modal/transcript-gpt-4o-audio-preview.sh file.mp3 "Schreibe mir den NUR Inhalt zurück, so genau wie möglich! Gebe nichts anderes zurück!"
```

### whisper-1

[transcript/whisper.sh](transcript/whisper.sh)

```bash
bash transcript/whisper.sh file.mp3 "" de
```

## Tools

### ffmpeg

```bash
ffmpeg -i input.m4a -ss 00:00:0.0 -t 10 -b:a 96k output.mp3
```
