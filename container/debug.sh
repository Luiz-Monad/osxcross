#!/bin/bash -e

NGROK_SSH_PUBKEY=$(echo "$NGROK_SSH_PUBKEY" | base64 -d)
NGROK_TOKEN=$(echo "$NGROK_TOKEN" | base64 -d)

USER_NAME="$(whoami)"
USER_DIR="/$(whoami)"
mkdir -p $USER_DIR/.ssh

# Add public key to authorized_keys
echo "$NGROK_SSH_PUBKEY" | tee -a $USER_DIR/.ssh/authorized_keys
chmod 600 $USER_DIR/.ssh/authorized_keys
chown $USER_NAME:$USER_NAME $USER_DIR/.ssh -R

# Install SSHD
echo "Installing sshd..."
apt-get update
apt-get install -y --no-install-recommends openssh-server wget
service ssh start

# SSHD status
echo "SSH status:"
service ssh status

# Unzip tool
wget http://mirrors.kernel.org/ubuntu/pool/main/u/unzip/unzip_6.0-21ubuntu1_amd64.deb
dpkg -i unzip_6.0-21ubuntu1_amd64.deb

# Install ngrok
echo "Installing ngrok..."
wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
unzip ngrok-v3-stable-linux-amd64.zip

# Config ngrok
echo "Setting ngrok..."
./ngrok config add-authtoken "$NGROK_TOKEN"
CONFIG_PATH=$(./ngrok config check | awk -F' at ' '{print $2}')
tee -a "$CONFIG_PATH" <<EOF
tunnels:
  ssh_tunnel:
    addr: 22
    proto: tcp
EOF

# Config service
echo "Setting service..."
./ngrok start --all --config $CONFIG_PATH --log=stdout > /var/log/ngrok.log 2>&1 &

# Status service
echo "NGROK status:"
tail -n 5 /var/log/ngrok.log

# Show Public Keys and Config
echo "Public keys:"
cat $USER_DIR/.ssh/authorized_keys

echo "NGROK config:"
cat $CONFIG_PATH

echo "User name:"
echo $USER_NAME

echo "Debug: Ready"
