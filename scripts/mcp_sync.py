#!/usr/bin/env python3
"""Sanitize and merge Cursor ~/.cursor/mcp.json for ai-skills-rules sync."""

from __future__ import annotations

import json
import os
import re
import sys
from copy import deepcopy
from pathlib import Path
from typing import Any

SECRET_KEY = re.compile(
    r"(token|key|secret|password|passwd|credential|auth|api[_-]?key|pat)",
    re.I,
)
PLACEHOLDER = re.compile(r"^YOUR_.*_HERE$", re.I)


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def dump_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def is_secret_key(key: str) -> bool:
    return bool(SECRET_KEY.search(key))


def is_placeholder(value: str) -> bool:
    return not value or bool(PLACEHOLDER.match(value)) or value.startswith("YOUR_")


def replace_home(value: str, home: str) -> str:
    if home and home in value:
        return value.replace(home, "${HOME}")
    return value


def sanitize_value(key: str, value: str, home: str) -> str:
    value = replace_home(value, home)
    if is_secret_key(key) and not is_placeholder(value):
        normalized = re.sub(r"[^A-Z0-9]+", "_", key.upper()).strip("_")
        return f"YOUR_{normalized}_HERE"
    return value


def sanitize_server(server: dict[str, Any], home: str) -> dict[str, Any]:
    out = deepcopy(server)
    for field in ("env", "headers"):
        if field in out and isinstance(out[field], dict):
            out[field] = {
                k: sanitize_value(k, v, home)
                for k, v in out[field].items()
                if isinstance(v, str)
            }
    if "args" in out and isinstance(out["args"], list):
        out["args"] = [
            replace_home(v, home) if isinstance(v, str) else v for v in out["args"]
        ]
    return out


def sanitize_config(data: dict[str, Any], home: str) -> dict[str, Any]:
    servers = data.get("mcpServers", {})
    if not isinstance(servers, dict):
        raise ValueError("mcp.json: mcpServers must be an object")
    return {
        "mcpServers": {
            name: sanitize_server(cfg, home)
            for name, cfg in sorted(servers.items())
            if isinstance(cfg, dict)
        }
    }


def merge_map(repo: dict[str, str] | None, local: dict[str, str] | None) -> dict[str, str]:
    merged = dict(repo or {})
    for key, local_val in (local or {}).items():
        if key in merged:
            if isinstance(local_val, str) and not is_placeholder(local_val):
                merged[key] = local_val
        else:
            merged[key] = local_val
    return merged


def expand_home_in_server(server: dict[str, Any], home: str) -> dict[str, Any]:
    out = deepcopy(server)
    for field in ("env", "headers"):
        if field in out and isinstance(out[field], dict):
            out[field] = {
                k: v.replace("${HOME}", home) if isinstance(v, str) else v
                for k, v in out[field].items()
            }
    if "args" in out and isinstance(out["args"], list):
        out["args"] = [
            v.replace("${HOME}", home) if isinstance(v, str) else v for v in out["args"]
        ]
    return out


def merge_server(repo: dict[str, Any], local: dict[str, Any] | None, home: str) -> dict[str, Any]:
    out = expand_home_in_server(deepcopy(repo), home)
    if not local:
        return out
    for field in ("env", "headers"):
        if field in out or field in local:
            out[field] = merge_map(out.get(field), local.get(field))
    return out


def merge_config(repo_data: dict[str, Any], local_data: dict[str, Any] | None) -> dict[str, Any]:
    repo_servers = repo_data.get("mcpServers", {})
    local_servers = (local_data or {}).get("mcpServers", {})
    home = str(Path.home())

    names = sorted(set(repo_servers) | set(local_servers))
    merged: dict[str, Any] = {}
    for name in names:
        if name in repo_servers:
            merged[name] = merge_server(
                repo_servers[name],
                local_servers.get(name) if isinstance(local_servers.get(name), dict) else None,
                home,
            )
        else:
            local_cfg = local_servers[name]
            if isinstance(local_cfg, dict):
                merged[name] = expand_home_in_server(deepcopy(local_cfg), home)

    return {"mcpServers": merged}


def cmd_sanitize(src: Path, dst: Path) -> None:
    home = str(Path.home())
    data = sanitize_config(load_json(src), home)
    dump_json(dst, data)


def cmd_merge(repo: Path, local: Path | None, dst: Path) -> None:
    repo_data = load_json(repo)
    local_data = load_json(local) if local and local.is_file() else None
    dump_json(dst, merge_config(repo_data, local_data))


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: mcp_sync.py sanitize <src> <dst>", file=sys.stderr)
        print("       mcp_sync.py merge <repo> <local> <dst>", file=sys.stderr)
        return 1

    cmd = sys.argv[1]
    if cmd == "sanitize":
        if len(sys.argv) != 4:
            print("Usage: mcp_sync.py sanitize <src> <dst>", file=sys.stderr)
            return 1
        cmd_sanitize(Path(sys.argv[2]), Path(sys.argv[3]))
        return 0

    if cmd == "merge":
        if len(sys.argv) != 5:
            print("Usage: mcp_sync.py merge <repo> <local> <dst>", file=sys.stderr)
            return 1
        local = Path(sys.argv[3])
        cmd_merge(Path(sys.argv[2]), local, Path(sys.argv[4]))
        return 0

    print(f"Unknown command: {cmd}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
