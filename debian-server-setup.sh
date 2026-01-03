#!/bin/bash
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run as root (run 'su -' before executing this script)."
  exit 1
fi

echo "--- 🚀 Starting Docker & Git Setup Script ---"

# --- Prompt for the non-root username ---
# This ensures the standard user can run docker without sudo later
read -p "👉 Please enter your non-root username (to grant Docker permission): " TARGET_USER

if id "$TARGET_USER" &>/dev/null; then
    echo "✅ Verified! Proceeding setup for user: $TARGET_USER"
else
    echo "❌ Error: User '$TARGET_USER' does not exist. Please check the spelling and try again."
    exit 1
fi
# ---------------------------------------------

# 1. Update and install dependencies
echo "--- 📦 Updating system and installing dependencies (including Git) ---"
apt-get update
# apt-get install -y ca-certificates curl gnupg git

# 2. Setup GPG Keys for Docker
echo "--- 🔑 Setting up Docker GPG keys ---"
install -m 0755 -d /etc/apt/keyrings
# Remove old key if exists to avoid overwrite prompt
rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Add Docker Repository
echo "--- 📚 Adding Docker official repository ---"
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Install Docker Engine
echo "--- 🐳 Installing Docker Engine and Docker Compose Plugin ---"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Add user to docker group
echo "--- 👤 Adding user '$TARGET_USER' to the 'docker' group ---"
usermod -aG docker $TARGET_USER

# 6. Enable and start service
echo "--- 🔌 Enabling and starting Docker service ---"
systemctl enable docker
systemctl start docker

echo "--- ✅ Installation Complete! ---"
echo "⚠️  IMPORTANT: You must Log out and Log back in as '$TARGET_USER' for the group changes to take effect."
echo "👉 Verify installation with: 'docker --version' and 'docker compose version'"
