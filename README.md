# ZMOB VPS Agent

One-command installer for a small Ubuntu VPS agent.

## Install

Run on a fresh Ubuntu VPS as root:

```bash
curl -fsSL https://raw.githubusercontent.com/rezaziyai/zmob-vps-agent/main/install.sh | bash
```

The installer creates the agent under /opt/zmob-agent and runs it as a systemd service.

## Important

This repository does not by itself create a privileged connection from a ChatGPT conversation. The agent must be connected to a supported MCP/agent runtime before ChatGPT can invoke its tools.
