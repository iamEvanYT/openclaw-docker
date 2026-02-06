#!/usr/bin/env sh

# Remove `.git` repository of the template
rm -rf .git

# Prompt for instance name
echo ""
echo "=========================================="
echo "Instance Configuration"
echo "=========================================="
echo "Enter a name for this OpenClaw instance."
echo "This will be the hostname in Tailscale (e.g., 'my-openclaw')."
echo "Press Enter to use default: openclawd"
echo ""
printf "Instance Name: "
read -r INSTANCE_NAME

# Use default if not provided
if [ -z "$INSTANCE_NAME" ]; then
    INSTANCE_NAME="openclawd"
    echo "Using default: openclawd"
else
    echo "Using instance name: $INSTANCE_NAME"
    # Update docker-compose.yml with the new hostname
    sed -i.bak "s/hostname: openclawd/hostname: $INSTANCE_NAME/" docker-compose.yml
    rm -f docker-compose.yml.bak
    echo "✓ Updated docker-compose.yml hostname"
fi

# Prompt for Tailscale auth key
echo ""
echo "=========================================="
echo "Tailscale Authentication"
echo "=========================================="
echo "Please enter your Tailscale auth key (tskey-auth-...)."
echo "You can generate one at: https://login.tailscale.com/admin/settings/keys"
echo "Press Enter to skip (you'll need to manually configure tailscale/.env)"
echo ""
printf "Tailscale Auth Key: "
read -r TS_AUTHKEY

# Save auth key to tailscale/.env if provided
if [ -n "$TS_AUTHKEY" ]; then
    echo "TS_AUTHKEY=$TS_AUTHKEY" > tailscale/.env
    echo "✓ Tailscale auth key saved to tailscale/.env"
else
    echo "⚠ No auth key provided. Make sure to manually set TS_AUTHKEY in tailscale/.env"
fi

echo ""
echo "=========================================="
echo "Starting Onboarding Process"
echo "=========================================="
echo ""

# Temporarily modify docker-compose.yml to use sleep command for onboarding
sed -i.bak 's/\["node", "dist\/index.js", "gateway", "--bind", "lan", "--port", "18789"\]/["sleep", "infinity"]/' docker-compose.yml

# Start containers
echo "Starting containers..."
docker compose up -d

# Wait a moment for containers to initialize
sleep 3

# Get the actual gateway container name (handles potential prefixes/suffixes)
GATEWAY_CONTAINER=$(docker compose ps -q gateway | xargs docker inspect --format='{{.Name}}' | sed 's/\///')

if [ -z "$GATEWAY_CONTAINER" ]; then
    echo "Error: Could not find gateway container"
    # Restore docker-compose.yml before exiting
    mv docker-compose.yml.bak docker-compose.yml
    exit 1
fi

echo "Running onboarding in container: $GATEWAY_CONTAINER"
echo ""

# Run onboarding
docker exec -it "$GATEWAY_CONTAINER" node dist/index.js onboard

ONBOARDING_STATUS=$?

# Stop containers
echo ""
echo "Stopping containers..."
docker compose down

# Restore original docker-compose.yml
mv docker-compose.yml.bak docker-compose.yml

# Check if onboarding was successful
if [ $ONBOARDING_STATUS -eq 0 ]; then
    echo ""
    echo "✓ Onboarding completed successfully!"
    
    # Create tailscale serve.json
    mkdir -p volumes/tailscale/config
    cat > volumes/tailscale/config/serve.json << 'EOF'
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
EOF
    echo "✓ Created volumes/tailscale/config/serve.json"
else
    echo ""
    echo "⚠ Onboarding may not have completed successfully (exit code: $ONBOARDING_STATUS)"
    echo "  You can run onboarding manually later with:"
    echo "  docker compose up -d && docker exec -it \$(docker compose ps -q gateway) node dist/index.js onboard"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To start OpenClaw:"
echo "  docker compose up -d"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
