import os
import subprocess
import shutil

COMPILED_DIR = os.path.abspath("./tools/compiled")
BUILD_DIR = os.path.abspath("./build")
FILES = ["vx_server.py", "vx_agent.py"]

def ensure_dir():
    os.makedirs(COMPILED_DIR, exist_ok=True)
    os.makedirs(BUILD_DIR, exist_ok=True)

def compile_file(file):
    name = os.path.splitext(os.path.basename(file))[0]
    print(f"[+] Compiling {file}...")

    cmd = [
        "nuitka",
        "--standalone",
        "--onefile",
        f"--output-dir={BUILD_DIR}",
        "--remove-output",
        file
    ]

    try:
        subprocess.run(cmd, check=True)

        # Find output binary in build/
        ext = ".exe" if os.name == "nt" else ""
        built_path = os.path.join(BUILD_DIR, f"{name}.bin{ext}")
        fallback = os.path.join(BUILD_DIR, f"{name}{ext}")
        final_path = built_path if os.path.exists(built_path) else fallback

        if os.path.exists(final_path):
            shutil.move(final_path, os.path.join(COMPILED_DIR, os.path.basename(final_path)))
            print(f"[+] Output: {os.path.join(COMPILED_DIR, os.path.basename(final_path))}")
        else:
            print(f"[!] Couldn't find compiled output for {file}")

    except subprocess.CalledProcessError as e:
        print(f"[!] Failed to compile {file}:\n{e}")

if __name__ == "__main__":
    ensure_dir()
    for f in FILES:
        if not os.path.exists(f):
            print(f"[!] Skipping: {f} not found.")
            continue
        compile_file(f)

    print("\n[+] Compilation complete. Check:", COMPILED_DIR)
