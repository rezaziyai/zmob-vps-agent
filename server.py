import os
import subprocess

from mcp.server.mcpserver import MCPServer

TOKEN = os.environ["ZMOB_AGENT_TOKEN"]

server = MCPServer("ZMOB VPS Agent")


def check_token(token: str) -> None:
    if token != TOKEN:
        raise PermissionError("Invalid authentication token")


@server.tool()
def server_info(token: str) -> str:
    """Return basic VPS information."""
    check_token(token)

    commands = [
        "hostname",
        "uname -a",
        "uptime",
        "free -h",
        "df -h /",
    ]

    output = []
    for command in commands:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        output.append(
            f"$ {command}\n"
            f"{result.stdout}"
            f"{result.stderr}"
        )

    return "\n".join(output)


@server.tool()
def run_command(token: str, command: str) -> str:
    """Execute a Linux command on the VPS."""
    check_token(token)

    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        timeout=120,
    )

    return (
        f"EXIT CODE: {result.returncode}\n\n"
        f"STDOUT:\n{result.stdout}\n\n"
        f"STDERR:\n{result.stderr}"
    )


@server.tool()
def read_file(token: str, path: str) -> str:
    """Read a text file from the VPS."""
    check_token(token)

    with open(path, "r", encoding="utf-8") as file:
        return file.read()


@server.tool()
def write_file(token: str, path: str, content: str) -> str:
    """Write a text file to the VPS."""
    check_token(token)

    with open(path, "w", encoding="utf-8") as file:
        file.write(content)

    return f"Written: {path}"


if __name__ == "__main__":
    server.run(
        transport="streamable-http",
        host="127.0.0.1",
        port=8765,
        stateless_http=True,
    )
