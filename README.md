### 📚 LLM-Ready Repository Access

For easy AI analysis of this entire repository, visit:
**https://gitingest.com/dhcgn/ai-sample-scripts**

This provides the complete repository content in an LLM-digestible format, allowing you to easily access all information with your preferred AI assistant.

---

# [![Check Shell Scripts](https://github.com/dhcgn/ai-sample-scripts/actions/workflows/check-shell-scripts.yml/badge.svg)](https://github.com/dhcgn/ai-sample-scripts/actions/workflows/check-shell-scripts.yml)

# AI Sample Scripts: Simple, Secure, and Portable

This repository demonstrates how easy it is to use modern AI services for a variety of tasks. You can use these scripts directly, with no dependencies or imports required. All examples use raw HTTP requests, making them easy to adapt to any scripting or programming language.

## Why This Repo?

* No SDKs or libraries required. All scripts use only standard tools (like `curl`), so you can copy and adapt them anywhere.
* Multi-language ready. The logic is portable to Bash, PowerShell, Python, or any language that can make HTTP requests.
* Real-world AI tasks. See how to do image description, audio transcription, text-to-speech, moderation, PDF extraction, and more.
* Privacy-first. Special focus on [Privatemode AI](#privatemode-ai-confidential-computing), which enables confidential AI computing for sensitive data.
* Some scripts demonstrate how to return structured data. This is always JSON, which enables developers to easily work with the output in any language.

---

## 🚀 Quick Start

1. **Clone this repo**
2. **Set your API keys as environment variables** (see [API Key Setup](#api-key-setup))
3. **Run any script!**

---

## 📂 Folder Overview

```
├── download_test_images.sh
├── moderation/                 # Content moderation
├── multi-modal/                # Image, audio, and multi-modal tasks
├── pdf/                        # PDF extraction and analysis
├── privatemode-ai/             # Confidential AI scripts (Privatemode)
├── test-data/                  # Example input files
├── text-to-speech/             # Text-to-speech
└── transcript/                 # Audio transcription
```

---

## 🛡️ Privatemode AI: Confidential AI Computing


**Privatemode AI** (by Edgeless Systems) enables you to use powerful generative AI models with true end-to-end confidentiality. Unlike typical cloud AI, your data is protected by confidential computing and encryption. No one but you can access your data, not even the service provider.

See the [Privatemode AI Documentation](https://docs.privatemode.ai/) for more details.

**Why use Privatemode AI?**

* Confidentiality. Data is protected at all times (in transit, at rest, and during processing).
* Regulatory compliance. Ideal for sensitive or regulated data.
* Drop-in replacement. Works just like other AI APIs, but with privacy guarantees.

### Prerequisites

- You need access to a running Privatemode AI proxy (see [privatemode-ai/README.md](privatemode-ai/README.md) for setup)
- Set your `PRIVATE_MODE_API_KEY` environment variable

### Example: Secure Chat Completion

```bash
# Ask a question securely
bash privatemode-ai/conversation.sh "What is the capital of France?" http://192.168.3.10:9876
# Output: The capital of France is Paris.
```

### Example: Confidential OCR

```bash
bash privatemode-ai/ocr.sh test-data/pdf/simple.jpg http://192.168.3.10:9876/
# Output: This is a Test
```


### Example: Audio Transcription (Privatemode Whisper)

```bash
bash privatemode-ai/whisper.sh  test-data/audio/MLKDream_64kb.mp3 "Speech" "en" http://192.168.3.10:9876
```

### Example: Structured Extraction

```bash
bash privatemode-ai/conversation-structured.sh "Dies ist eine Rechnung über einen Computer" privatemode-ai/caption_list.schema.json http://localhost:8080
```

---

## 🖼️ Multi-Modal AI (OpenAI, etc.)

### Image Description

```bash
export OPENAI_API_KEY=...
bash download_test_images.sh
bash multi-modal/describe-image.sh test-data/images/n01494475_hammerhead.JPEG 'What is in this image? Give a Description and a list of tags.'
```

### Image Tagging (Structured)

```bash
bash multi-modal/describe-image-structured.sh test-data/images/n01494475_hammerhead.JPEG
```

### Audio Transcription

```bash
bash multi-modal/transcript-gpt-4o-audio-preview.sh test-data/TheFutureofWomeninFlying.mp3 "Transcribe this audio."
bash transcript/whisper.sh test-data/TheFutureofWomeninFlying.mp3 "Speech of Amelia Earhart" "en"
bash transcript/assemblyai.sh test-data/TheFutureofWomeninFlying.mp3
bash transcript/openai_transcribe.sh test-data/TheFutureofWomeninFlying.mp3 "Speech of Amelia Earhart" "en"
```

### Text-to-Speech

```bash
bash text-to-speech/text-to-speech.sh "Hello! My name is Franz."
# Output: Speech file saved to ...
```

### Moderation

```bash
bash moderation/moderation.sh "You are dumb"
# Output: JSON with moderation categories and scores
```

### PDF to Text with Visuals

```bash
bash pdf/pdf-to-text-with-visuals-anthropic.sh test-data/pdf/sample.pdf
bash pdf/pdf-to-text-with-visuals-mistral.sh test-data/pdf/sample.pdf
```

---


## 🔑 API Key Setup

You can easily obtain these API keys from each AI service provider (such as OpenAI, Privatemode AI, AssemblyAI, Anthropic, etc.).

Set your API keys as environment variables in your shell profile for convenience:

```bash
export OPENAI_API_KEY=...
export PRIVATE_MODE_API_KEY=...
export ASSEMBLYAI_API_KEY=...
export ANTHROPIC_API_KEY=...
export MISTRAL_API_KEY=...
```

For persistent setup, add these lines to your `~/.bashrc` or `~/.bash_profile` and run `source ~/.bashrc`.

---

## 🛠️ Tools

### ffmpeg (for audio conversion)

```bash
ffmpeg -i input.m4a -ss 00:00:0.0 -t 10 -b:a 96k output.mp3
```

---

## 📑 License & Contribution

Feel free to use, adapt, and contribute improvements! See individual script headers for details.
