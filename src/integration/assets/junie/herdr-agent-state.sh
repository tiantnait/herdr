#!/bin/sh
# managed by herdr; reinstalling the integration replaces this file.
# HERDR_INTEGRATION_ID=junie
# HERDR_INTEGRATION_VERSION=1

# Reports the current Junie session id to Herdr so the pane can be restored
# after a Herdr server restart. Lifecycle state stays with Herdr's screen
# detection because Junie does not emit a hook on every interruption.

[ "${1:-}" = "session" ] || exit 0
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_SOCKET_PATH:-}" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 -c '
import json
import os
import socket
import sys
import time

try:
    payload = json.load(sys.stdin)
except Exception:
    payload = {}

session_id = payload.get("session_id")
if not isinstance(session_id, str) or not session_id:
    raise SystemExit(0)

seq = time.time_ns()
params = {
    "pane_id": os.environ["HERDR_PANE_ID"],
    "source": "herdr:junie",
    "agent": "junie",
    "seq": seq,
    "agent_session_id": session_id,
}
source = payload.get("source")
if isinstance(source, str) and source:
    params["session_start_source"] = source
request = json.dumps({"id": f"herdr:junie:{seq}", "method": "pane.report_agent_session", "params": params})
try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(0.5)
        client.connect(os.environ["HERDR_SOCKET_PATH"])
        client.sendall((request + "\n").encode())
        client.recv(4096)
except Exception:
    pass
' 2>/dev/null || true
