import subprocess
import json
import os
import socket
import time

# Your terminal's class
TERMINAL_CLASS = "kitty"
KEYBOARDS = [
    "revo-molly60mx-keyboard",
    "wilba.tech-wt65-h2",
    "at-translated-set-2-keyboard",
    # Add other keyboards here
]

def set_layout(index):
    for keyboard in KEYBOARDS:
        subprocess.run(["hyprctl", "switchxkblayout", keyboard, str(index)])

def get_socket_path():
    # Attempt to find the socket by looking in common locations
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    
    # Priority list for socket discovery
    potential_paths = [
        f"{xdg_runtime}/hypr/{signature}/.socket2.sock" if signature else None,
        f"/tmp/hypr/{signature}/.socket2.sock" if signature else None,
    ]
    
    for path in potential_paths:
        if path and os.path.exists(path):
            return path
    return None

def monitor():
    while True:
        address = get_socket_path()
        
        if not address:
            # If we can't find the socket yet, wait and try again
            time.sleep(1)
            continue

        try:
            # Connect natively to the Unix Socket
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client.connect(address)
            
            # Use a file-like object to read line by line efficiently
            with client.makefile('r') as f:
                for line in f:
                    if "activewindow>>" in line:
                        res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True)
                        if res.returncode == 0:
                            try:
                                window_info = json.loads(res.stdout)
                                if window_info.get("class") == TERMINAL_CLASS:
                                    set_layout(0)
                                else:
                                    set_layout(1)
                            except json.JSONDecodeError:
                                continue
        except (socket.error, BrokenPipeError):
            # If Hyprland restarts or the socket drops, wait and reconnect
            time.sleep(1)
        finally:
            client.close()

if __name__ == "__main__":
    # Give the system 1 second to breathe on startup
    time.sleep(1)
    monitor()