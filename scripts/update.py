#!/usr/bin/env python3
import base64
import json
import os
import re
import sys
import urllib.request

GITHUB_REPO = "Kotlin/kotlin-lsp"
BASE_URL = "https://download.jetbrains.com/language-server/kotlin-server"

def get_latest_version():
    api_url = f"https://api.github.com/repos/{GITHUB_REPO}/releases"
    req = urllib.request.Request(
        api_url,
        headers={
            "User-Agent": "kotlin-lsp-nix-updater",
            "Accept": "application/vnd.github.v3+json",
        },
    )
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"token {token}")

    with urllib.request.urlopen(req) as resp:
        releases = json.loads(resp.read().decode("utf-8"))

    for rel in releases:
        if rel.get("draft") or rel.get("prerelease"):
            continue
        tag = rel.get("tag_name", "")
        # Tags are e.g. kotlin-lsp/v263.7084.0 or v263.7084.0
        match = re.search(r"(\d+\.\d+\.\d+)", tag)
        if match:
            return match.group(1)

    raise RuntimeError("Could not find latest release version from GitHub")

def sha256_to_sri(hex_hash: str) -> str:
    cleaned = hex_hash.strip().split()[0]
    raw = bytes.fromhex(cleaned)
    return f"sha256-{base64.b64encode(raw).decode()}"

def fetch_hash(url: str) -> str:
    sha_url = url + ".sha256"
    req = urllib.request.Request(sha_url, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode("utf-8")
        return sha256_to_sri(content)

def set_github_output(name: str, value: str):
    output_file = os.environ.get("GITHUB_OUTPUT")
    if output_file:
        with open(output_file, "a") as f:
            f.write(f"{name}={value}\n")

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sources_path = os.path.join(root, "sources.json")

    with open(sources_path, "r") as f:
        sources = json.load(f)

    current_version = sources.get("version")
    latest_version = get_latest_version()

    print(f"Current version: {current_version}")
    print(f"Latest version:  {latest_version}")

    force = "--force" in sys.argv
    if current_version == latest_version and not force:
        print("kotlin-lsp is already up to date.")
        set_github_output("updated", "false")
        return

    print(f"Updating to version {latest_version}...")

    urls = {
        "x86_64-linux": f"{BASE_URL}/{latest_version}/kotlin-server-{latest_version}.tar.gz",
        "aarch64-linux": f"{BASE_URL}/{latest_version}/kotlin-server-{latest_version}-aarch64.tar.gz",
        "x86_64-darwin": f"{BASE_URL}/{latest_version}/kotlin-server-{latest_version}.sit",
        "aarch64-darwin": f"{BASE_URL}/{latest_version}/kotlin-server-{latest_version}-aarch64.sit",
    }

    new_sources = {"version": latest_version}
    for plat, url in urls.items():
        print(f"Fetching hash for {plat}...")
        sri_hash = fetch_hash(url)
        new_sources[plat] = {"url": url, "hash": sri_hash}

    with open(sources_path, "w") as f:
        json.dump(new_sources, f, indent=2)
        f.write("\n")

    print(f"Successfully updated sources.json to {latest_version}")
    set_github_output("updated", "true")
    set_github_output("version", latest_version)

if __name__ == "__main__":
    main()
