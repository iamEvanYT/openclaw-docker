# OpenClaw Docker

A Docker Compose setup for running [OpenClaw](https://github.com/openclaw/openclaw) with Tailscale VPN for secure remote access.

## What's Included

| Service       | Description                                         |
| ------------- | --------------------------------------------------- |
| **gateway**   | The main OpenClaw gateway (AI agent runtime)        |
| **tailscale** | Secure VPN tunnel for remote HTTPS access           |
| **browser**   | Sandbox browser for web automation (Chrome + noVNC) |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- [Tailscale](https://tailscale.com/) account
- Tailscale auth key from [admin console](https://login.tailscale.com/admin/settings/keys)

## Quick Start

```bash
# 1. Clone and enter the directory
git clone https://github.com/iamEvanYT/openclaw-docker.git
cd openclaw-docker

# 2. Run the automated setup
sh ./setup.sh
```

The setup script will:

- Prompt for your Tailscale auth key
- Configure and start all services
- Run the OpenClaw onboarding wizard
- Generate the Tailscale HTTPS configuration automatically

### 3. Generate HTTPS Certificate (Required)

Even after automated setup, you must generate the HTTPS certificate:

```bash
# SSH into the Tailscale container
sh ./scripts/ssh-tailscale.sh

# Generate certificate (replace with your actual Tailscale domain)
tailscale cert your-machine.your-tailnet.ts.net

# Exit the container
exit
```

Find your Tailscale domain in the [admin console](https://login.tailscale.com/admin/machines) or run `tailscale status` inside the container.

### 4. Restart Services

```bash
sh ./scripts/restart.sh
```

Your OpenClaw instance is now ready at `https://your-machine.tailnet.ts.net`

## Manual Setup (Advanced)

If you prefer to set up manually instead of using `setup.sh`:

### 1. Configure Tailscale

Create `tailscale/.env`:

```env
TS_AUTHKEY=tskey-auth-xxxxxxxxxxxxxxxx
```

### 2. Start Services

```bash
sh ./scripts/startup.sh
```

### 3. Enable HTTPS

In the [Tailscale Admin Console](https://login.tailscale.com/admin/dns), enable "HTTPS Certificates". This is required for both automated and manual setup.

### 4. Generate Certificate

```bash
sh ./scripts/ssh-tailscale.sh
tailscale cert your-machine.your-tailnet.ts.net
exit
```

### 5. Create Serve Configuration

Create `volumes/tailscale/config/serve.json`:

```json
{
  "TCP": {
    "443": { "HTTPS": true },
    "8443": { "HTTPS": true }
  },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "NOTE": "OpenClaw Gateway",
      "Handlers": {
        "/": { "Proxy": "http://127.0.0.1:18789" }
      }
    },
    "${TS_CERT_DOMAIN}:8443": {
      "NOTE": "OpenClaw Browser noVNC",
      "Handlers": {
        "/": { "Proxy": "http://172.20.0.10:6080" }
      }
    }
  },
  "AllowFunnel": {
    "${TS_CERT_DOMAIN}:443": false,
    "${TS_CERT_DOMAIN}:8443": false
  }
}
```

### 6. Restart and Onboard

```bash
sh ./scripts/restart.sh
sh ./scripts/ssh-gateway.sh
openclaw onboard
```

## Available Scripts

| Script                     | Purpose                                       |
| -------------------------- | --------------------------------------------- |
| `setup.sh`                 | Initial automated setup (includes onboarding) |
| `scripts/startup.sh`       | Start all services                            |
| `scripts/shutdown.sh`      | Stop all services                             |
| `scripts/restart.sh`       | Restart all services                          |
| `scripts/ssh-gateway.sh`   | SSH into the OpenClaw gateway container       |
| `scripts/ssh-tailscale.sh` | SSH into the Tailscale container              |
| `scripts/gateway-logs.sh`  | View gateway logs                             |
| `scripts/update.sh`        | Update to latest OpenClaw image               |
| `scripts/fix-perms.sh`     | Fix file permissions                          |

## Accessing Services

After setup and certificate generation, access your services via Tailscale:

| Service          | URL                                        | Description            |
| ---------------- | ------------------------------------------ | ---------------------- |
| OpenClaw Gateway | `https://your-machine.tailnet.ts.net`      | Main API and dashboard |
| noVNC (Browser)  | `https://your-machine.tailnet.ts.net:8443` | Remote browser desktop |

**Note:** HTTPS will not work until you complete the certificate generation step (see Quick Start step 3).

## Directory Structure

```
.
├── docker-compose.yml      # Service definitions
├── setup.sh                # Automated setup script
├── gateway/.env            # Gateway environment variables
├── tailscale/.env          # Tailscale auth key
├── scripts/                # Helper scripts
└── volumes/                # Persistent data
    ├── config/             # OpenClaw configuration
    ├── workspace/          # OpenClaw workspace
    ├── storage/            # Persistent storage
    ├── tailscale/          # Tailscale state & certificates
    └── browser/            # Browser profile data
```

## Environment Variables

### Gateway (`gateway/.env`)

Add your secrets here. See [OpenClaw documentation](https://docs.openclaw.ai) for available options.

### Tailscale (`tailscale/.env`)

| Variable     | Description                        |
| ------------ | ---------------------------------- |
| `TS_AUTHKEY` | Your Tailscale auth key (required) |

## Troubleshooting

### Services won't start

Check logs:

```bash
docker compose logs -f
```

### Tailscale not connecting

Verify your auth key is set correctly in `tailscale/.env` and hasn't expired.

### HTTPS not working

Ensure you've:

1. Enabled HTTPS in Tailscale DNS settings
2. Generated certificates with `tailscale cert`
3. Created the `serve.json` configuration

### Permission denied errors

Run:

```bash
sh ./scripts/fix-perms.sh
```

## Updating

To update to the latest OpenClaw version:

```bash
sh ./scripts/update.sh
```

## Security Notes

- The `AllowFunnel` setting is disabled by default. Do not enable unless you understand the security implications.
- Keep your Tailscale auth key secure and rotate it periodically.
- The browser service runs with isolated permissions but still exercise caution when browsing untrusted sites.

## Support

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw Discord](https://discord.gg/clawd)
- [Tailscale Documentation](https://tailscale.com/kb)
