# OpenClaw Docker Setup (with Tailscale)

## Setup

1. Run `sh ./setup.sh` to setup everything initially.
2. Set the Tailscale Auth Key in the `tailscale/.env` file.
3. Run `sh ./scripts/startup.sh` to start the services.
4. In Tailscale Admin Console, go to DNS and turn on 'Enable HTTPS' if not enabled.
5. Run `sh ./scripts/ssh-tailscale.sh` to SSH into the Tailscale container.
6. Then in the Tailscale container, run `tailscale cert <tailscale-domain>` to generate a HTTPS certificate.
7. Setup `serve.json` as described below.
8. Run `sh ./scripts/restart.sh` to restart the services.
9. Run `sh ./scripts/ssh-gateway.sh` to SSH into the Gateway container.
10. Finally, run `openclaw onboard` to onboard the gateway!

## Setup `serve.json`

Put this in volumes/tailscale/config/serve.json:

```json
{
  "TCP": {
    "443": { "HTTPS": true }
  },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "Handlers": {
        "/": { "Proxy": "http://127.0.0.1:18789" }
      }
    }
  },
  "AllowFunnel": {
    "${TS_CERT_DOMAIN}:18789": false
  }
}
```

This will then allow HTTPS to work when you go to the domain on tailscale.
