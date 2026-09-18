#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this installer as root."
  exit 1
fi

APP=/opt/zmob-agent
PYTHON_BIN=python3

echo "[1/6] Installing prerequisites..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip openssl curl

echo "[2/6] Creating application..."
mkdir -p "$APP"
python3 -m venv "$APP/venv"

echo "[3/6] Installing MCP..."
"$APP/venv/bin/pip" install --upgrade pip
"$APP/venv/bin/pip" install "mcp==2.2.0"

echo "[4/6] Writing agent..."
curl -fsSL https://raw.githubusercontent.com/rezaziyai/zmob-vps-agent/main/server.py -o "$APP/server.py"

echo "[5/6] Creating service..."
install -d -m 700 /etc/zmob-agent
TOKEN="$(openssl rand -hex 32)"
printf 'ZMOB_AGENT_TOKEN=%s\n' "$TOKEN" > /etc/zmob-agent/agent.env
chmod 600 /etc/zmob-agent/agent.env

cat >/etc/systemd/system/zmob-agent.service <<'EOF'
[Unit]
Description=ZMOB VPS Agent
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/zmob-agent
EnvironmentFile=/etc/zmob-agent/agent.env
ExecStart=/opt/zmob-agent/venv/bin/python /opt/zmob-agent/server.py
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now zmob-agent

echo "[6/6] Checking service..."
sleep 2
systemctl --no-pager --full status zmob-agent || true

echo
echo "ZMOB VPS Agent installed."
echo "Local MCP endpoint: http://127.0.0.1:8765/mcp"
echo "Token stored in: /etc/zmob-agent/agent.env"
