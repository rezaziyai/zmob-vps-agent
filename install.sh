#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this installer as root."
  exit 1
fi

APP=/opt/zmob-agent

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip openssl curl wget

mkdir -p "$APP"
python3 -m venv "$APP/venv"

"$APP/venv/bin/pip" install --upgrade pip
"$APP/venv/bin/pip" install "mcp==2.2.0"

curl -fsSL https://raw.githubusercontent.com/rezaziyai/zmob-vps-agent/main/server.py -o "$APP/server.py"

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

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Installing cloudflared..."
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb
  apt-get install -y /tmp/cloudflared.deb
fi

echo ""
echo "ZMOB Agent installed."
echo "Local MCP: http://127.0.0.1:8765/mcp"
echo ""
echo "Cloudflare Tunnel setup:"
echo "Run: cloudflared tunnel login"
echo "Then we will create agent.4hh.ir tunnel routing."
