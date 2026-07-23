#!/usr/bin/env bash
# ============================================================
# deploy-remote.sh
# Runs ON the EC2 instance. Called by the GitHub Actions deploy
# job via SSH. It unpacks the artifact, installs production
# dependencies, and restarts the app via systemd.
#
# Expects two env vars passed over SSH:
#   ARTIFACT  - the tarball filename in /tmp
#   APP_ENV   - "dev" or "prod"
# ============================================================
set -euo pipefail

APP_DIR="/opt/devops-node-sample"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"
SERVICE="devops-node-sample"

echo "==> Deploying $ARTIFACT (env: $APP_ENV)"

# 1. Prepare directories
sudo mkdir -p "$RELEASES_DIR"
RELEASE_DIR="$RELEASES_DIR/${ARTIFACT%.tgz}"
sudo rm -rf "$RELEASE_DIR"
sudo mkdir -p "$RELEASE_DIR"

# 2. Unpack the artifact into a new release folder
echo "==> Unpacking to $RELEASE_DIR"
sudo tar -xzf "/tmp/$ARTIFACT" -C "$RELEASE_DIR"

# 3. Install production dependencies only
echo "==> Installing dependencies"
cd "$RELEASE_DIR"
sudo npm ci --omit=dev

# 4. Write the environment file the service reads
echo "==> Writing environment file"
sudo tee "$RELEASE_DIR/.env" >/dev/null <<EOF
NODE_ENV=$APP_ENV
APP_VERSION=${ARTIFACT%.tgz}
PORT=3000
EOF

# 5. Atomically switch the "current" symlink to the new release
echo "==> Switching current -> $RELEASE_DIR"
sudo ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

# 6. Restart the service
echo "==> Restarting $SERVICE"
sudo systemctl restart "$SERVICE"

# 7. Keep only the 5 most recent releases
echo "==> Cleaning old releases"
cd "$RELEASES_DIR"
ls -1dt */ | tail -n +6 | xargs -r sudo rm -rf

echo "==> Deploy complete."
