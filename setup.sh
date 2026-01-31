#!/usr/bin/env sh

# Remove `.git` repository of the template
rm -rf .git

# Generate a new token for the gateway
GATEWAY_TOKEN=$(openssl rand -hex 32)
sed -i.bak "s/CLAWDBOT_GATEWAY_TOKEN=YOUR_CLAWDBOT_GATEWAY_TOKEN_HERE/CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN/" gateway/.env
rm -f gateway/.env.bak