# Privatemode AI

Privatemode AI API Documentation: [https://docs.privatemode.ai/](https://docs.privatemode.ai/).

## Docker

```bash
docker run --rm -p 8080:8080 ghcr.io/edgelesssys/privatemode/privatemode-proxy:latest --apiKey ...
```

### Docker Compose

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