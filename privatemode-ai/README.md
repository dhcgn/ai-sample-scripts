
# Privatemode AI

Privatemode AI API Documentation: [https://docs.privatemode.ai/](https://docs.privatemode.ai/).

## Quick Start: Obtain an API Key

To use Privatemode AI, you need an API key. Obtain one here: [https://www.privatemode.ai/pricing](https://www.privatemode.ai/pricing) and go to the "Inference API" section. You can get a 14-day trial (1M tokens), then it's €5 for 1M tokens.

## About Privatemode AI

Privatemode AI is the first generative AI chat app & API with end-to-end encryption, enabling organizations to process even sensitive data securely with generative AI.

- **App & API:** Intuitive chat interface and an API compatible with OpenAI's API.
- **End-to-end encryption:** All data is encrypted on your device and remains encrypted throughout processing and storage. Data is never accessible in plaintext—not to Edgeless Systems, cloud providers, or admins.
- **Confidential Computing:** Built on AMD EPYC CPUs and Nvidia H100 GPUs, leveraging hardware-based security to keep data encrypted even in memory during processing.
- **Cryptographic attestation:** Remote attestation and cryptographic certificates verify the integrity of the secure processing environment.
- **No data retention:** The AI model cannot leak, remember, or use your data for training.
- **Model support:** Supports open-source models (e.g., Meta Llama 3.3; DeepSeek R1 coming soon).
- **Source available:** Core code will be published on GitHub for transparency.

**Technical details:**
- Runs on Nvidia H100 GPUs and AMD EPYC CPUs with Confidential Computing support
- End-to-end encryption: Data is encrypted on the client, remains encrypted in memory, and is only decrypted on your device
- Black-box architecture: Data is never visible to Edgeless Systems, cloud operators, or hackers
- Remote attestation: Devices verify the secure environment before processing

**Pricing & Availability:**
- **App:** 14-day free trial, then €20/month per user
- **API:** 14-day free trial with 1M tokens, then €5 per 1M tokens

## Technical Data: Confidential Computing on NVIDIA H100 GPUs

For more details, see the official NVIDIA documentation: [Confidential Computing on H100 GPUs for Secure and Trustworthy AI](https://developer.nvidia.com/blog/confidential-computing-on-h100-gpus-for-secure-and-trustworthy-ai/)

- **NVIDIA H100 Tensor Core GPU** is the first GPU to support confidential computing, enabling secure processing of data-in-use in a hardware-based, attested trusted execution environment (TEE).
- **Hardware Root of Trust (RoT):** The H100 TEE is anchored in an on-die hardware root of trust. Secure and measured boot, SPDM session establishment, and cryptographically signed attestation reports ensure the integrity of the environment.
- **Confidential Computing Modes:**
  - **CC-Off:** Standard operation, no confidential features.
  - **CC-On:** All confidential computing features active, firewalls enabled, performance counters disabled to prevent side-channel attacks.
  - **CC-DevTools:** Partial CC mode for development and profiling, with protections disabled.
- **Encrypted Data Transfers:** Data between CPU and GPU is encrypted using bounce buffers. Command buffers and CUDA kernels are encrypted and signed before crossing the PCIe bus.
- **Attestation:** Device identity certificates and attestation reports can be verified by the user or relying party before use. NVIDIA Remote Attestation Service (NRAS) is available for validation.
- **No Code Changes Required:** Most GPU-accelerated workloads run transparently in confidential computing mode with no application code changes.
- **Performance:** GPU compute and memory bandwidth are nearly unaffected; CPU-GPU interconnect bandwidth is limited by CPU encryption performance (~4 GB/s).
- **Supported Hardware Stack:**
  - **CPU:** AMD Milan+ (SEV-SNP), Intel Sapphire Rapids (TDX)
  - **GPU:** NVIDIA H100 PCIe, H100 NVL, HGX H100
  - **OS:** Ubuntu 22.04+, Kernel 5.19-rc6_v4+
  - **NVIDIA Driver:** R535.86+
  - **VBIOS:** 96.00.5E.00.01+
- **Security Benefits:** Protection against software, physical, rollback, cryptographic, and replay attacks. Hardware firewalls and attestation ensure isolation and verifiability.


## Models

Privatemode AI supports a range of open-source and high-performance models for both text generation and embedding. The API is compatible with OpenAI's model selection and usage patterns. You can list available models using the `/v1/models` endpoint. Example:

```bash
curl http://localhost:9876/v1/models | jq
```

Example response:
```json
{
  "object": "list",
  "data": [
    {
      "id": "intfloat/multilingual-e5-large-instruct",
      "object": "model",
      "tasks": ["embed"]
    },
    {
      "id": "google/gemma-3-27b-it",
      "object": "model",
      "tasks": ["generate"]
    },
    {
      "id": "ibnzterrell/Meta-Llama-3.3-70B-Instruct-AWQ-INT4",
      "object": "model",
      "tasks": ["generate"]
    },
    {
      "id": "latest",
      "object": "model",
      "tasks": ["generate"]
    }
  ]
}
```

You can specify the model in your API requests using the `model` parameter. New models are added regularly, including state-of-the-art open-source LLMs and embedding models. See the API documentation for the latest list and details.


## Docker

You can run Privatemode AI locally or on your own server using Docker. This is the fastest way to get started for development or testing. Replace `...` with your actual API key:

```bash
docker run --rm -p 9876:9876 ghcr.io/edgelesssys/privatemode/privatemode-proxy:latest --apiKey ...
```

This will start the proxy on port 9876. You can then send API requests to `http://localhost:9876`.

### Docker Compose

The following example uses Docker Compose to run the Privatemode AI proxy and Watchtower for automatic updates. **Note:** This setup is for development and testing only. In production, you should manage updates and secrets more securely.

Key points:
- The proxy is exposed on port 9876.
- The API key is provided via the `PRIVATE_MODE_API_KEY` environment variable.
- Watchtower automatically updates the proxy container (can change behavior without notice).

```yaml
version: '3.8'

services:
  privatemode-proxy:
    image: ghcr.io/edgelesssys/privatemode/privatemode-proxy:latest
    container_name: privatemode-proxy
    restart: unless-stopped
    ports:
      - "9876:9876"
    environment:
      - PRIVATE_MODE_API_KEY=${PRIVATE_MODE_API_KEY}
    command: >
      --apiKey ${PRIVATE_MODE_API_KEY}
      --port 9876
      --workspace /app/privatemode-proxy
    volumes:
      - privatemode_proxy_workspace:/app/privatemode-proxy

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 300 privatemode-proxy
    depends_on:
      - privatemode-proxy

volumes:
  privatemode_proxy_workspace:
    driver: local
```