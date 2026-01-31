#!/usr/bin/env sh

sh ./scripts/shutdown.sh

echo "\n--------------------------------"
echo "Service shutdown complete."
echo "Waiting for 5 seconds before starting..."
echo "--------------------------------\n"

sleep 5

sh ./scripts/startup.sh