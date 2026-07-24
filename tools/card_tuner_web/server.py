#!/usr/bin/env python3
"""Local web server for the character card layer + arm tuner."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
WORKSPACE = ROOT.parents[1]
ASSETS = WORKSPACE / "assets" / "character_cards"
LAYOUT_TRES = ASSETS / "layered_blank_1.tres"
PRESETS_DIR = WORKSPACE / "assets" / "limb_presets"
WEAPON_PRESET_FILES: dict[str, Path] = {
    "club": PRESETS_DIR / "club_clansmen_1.tres",
    "none": PRESETS_DIR / "none_clansmen_1.tres",
}
DEFAULT_WEAPON = "club"
HOST = "0.0.0.0"
PORT = 8765


def _normalize_weapon(weapon: str | None) -> str:
    key = (weapon or DEFAULT_WEAPON).strip().lower()
    if key not in WEAPON_PRESET_FILES:
        return DEFAULT_WEAPON
    return key


def _preset_path(weapon: str | None = None) -> Path:
    return WEAPON_PRESET_FILES[_normalize_weapon(weapon)]


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _vec2_from_tres(text: str, key: str, default: list[float]) -> list[float]:
    match = re.search(rf"{re.escape(key)}\s*=\s*Vector2\(([^)]+)\)", text)
    if not match:
        return default
    parts = [p.strip() for p in match.group(1).split(",")]
    if len(parts) != 2:
        return default
    return [float(parts[0]), float(parts[1])]


def load_layout() -> dict:
    text = _read_text(LAYOUT_TRES)
    return {
        "layout_id": "layered_blank_1",
        "body_texture_path": "res://assets/character_cards/body1.png",
        "head_texture_path": "res://assets/character_cards/head1.png",
        "body_neck_socket_px": _vec2_from_tres(text, "body_neck_socket_px", [176.0, 24.0]),
        "head_pivot_px": _vec2_from_tres(text, "head_pivot_px", [153.0, 345.0]),
        "body_offset_px": _vec2_from_tres(text, "body_offset_px", [0.0, 0.0]),
    }


def save_layout(data: dict) -> None:
    neck = data.get("body_neck_socket_px", [176.0, 24.0])
    pivot = data.get("head_pivot_px", [153.0, 345.0])
    body_off = data.get("body_offset_px", [0.0, 0.0])
    text = _read_text(LAYOUT_TRES)
    if not text:
        text = """[gd_resource type="Resource" script_class="CharacterCardLayerLayout" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/config/character_card_layer_layout.gd" id="1"]

[resource]
script = ExtResource("1")
layout_id = "layered_blank_1"
body_texture_path = "res://assets/character_cards/body1.png"
head_texture_path = "res://assets/character_cards/head1.png"
body_neck_socket_px = Vector2(176, 24)
head_pivot_px = Vector2(153, 345)
"""
    text = re.sub(
        r"body_neck_socket_px\s*=\s*Vector2\([^)]+\)",
        f"body_neck_socket_px = Vector2({neck[0]}, {neck[1]})",
        text,
    )
    text = re.sub(
        r"head_pivot_px\s*=\s*Vector2\([^)]+\)",
        f"head_pivot_px = Vector2({pivot[0]}, {pivot[1]})",
        text,
    )
    if "body_offset_px" in text:
        text = re.sub(
            r"body_offset_px\s*=\s*Vector2\([^)]+\)",
            f"body_offset_px = Vector2({body_off[0]}, {body_off[1]})",
            text,
        )
    else:
        text = text.rstrip() + f"\nbody_offset_px = Vector2({body_off[0]}, {body_off[1]})\n"
    LAYOUT_TRES.write_text(text, encoding="utf-8")


def _float_from_tres(text: str, key: str, default: float) -> float:
    match = re.search(rf"{re.escape(key)}\s*=\s*([-\d.]+)", text)
    if not match:
        return default
    try:
        return float(match.group(1))
    except ValueError:
        return default


def _upsert_float(text: str, key: str, value: float) -> str:
    line = f"{key} = {value}"
    if re.search(rf"{re.escape(key)}\s*=\s*[-\d.]+", text):
        return re.sub(rf"{re.escape(key)}\s*=\s*[-\d.]+", line, text)
    return text.rstrip() + f"\n{line}\n"


PRESET_VEC2_KEYS = [
    "shoulder_offset_px",
    "hand_grip_offset_px",
    "hand_grip_ready_offset_px",
    "support_shoulder_offset_px",
    "support_hand_idle_offset_px",
    "overlay_offset_idle_px",
    "ready_offset_px",
    "weapon_elbow_pole_idle_px",
    "support_elbow_pole_idle_px",
]
PRESET_FLOAT_KEYS = ["upper_arm_length", "lower_arm_length"]


def load_preset(weapon: str | None = None) -> dict:
    path = _preset_path(weapon)
    text = _read_text(path)
    out: dict = {"weapon": _normalize_weapon(weapon)}
    for key in PRESET_VEC2_KEYS:
        out[key] = _vec2_from_tres(text, key, [0.0, 0.0])
    for key in PRESET_FLOAT_KEYS:
        out[key] = _float_from_tres(text, key, 120.0)
    return out


def _upsert_vec2(text: str, key: str, value: list[float]) -> str:
    line = f"{key} = Vector2({value[0]}, {value[1]})"
    if re.search(rf"{re.escape(key)}\s*=\s*Vector2\([^)]+\)", text):
        return re.sub(
            rf"{re.escape(key)}\s*=\s*Vector2\([^)]+\)",
            line,
            text,
        )
    return text.rstrip() + f"\n{line}\n"


def save_preset(data: dict, weapon: str | None = None) -> None:
    path = _preset_path(weapon)
    text = _read_text(path)
    for key, value in data.items():
        if key == "weapon":
            continue
        if isinstance(value, list) and len(value) == 2:
            text = _upsert_vec2(text, key, value)
        elif key in PRESET_FLOAT_KEYS and isinstance(value, (int, float)):
            text = _upsert_float(text, key, float(value))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def load_version() -> dict:
    sha = "unknown"
    branch = "unknown"
    try:
        sha = (
            subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=WORKSPACE, text=True)
            .strip()
        )
        branch = (
            subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=WORKSPACE, text=True)
            .strip()
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return {
        "sha": sha,
        "branch": branch,
        "built_at": datetime.now(timezone.utc).isoformat(),
        "layout_path": str(LAYOUT_TRES.relative_to(WORKSPACE)),
        "preset_path": str(_preset_path(DEFAULT_WEAPON).relative_to(WORKSPACE)),
        "weapons": {
            key: str(path.relative_to(WORKSPACE))
            for key, path in WEAPON_PRESET_FILES.items()
        },
    }


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self) -> None:
        path = urlparse(self.path).path
        if path in ("/", "/index.html") or path.endswith((".html", ".js", ".css")):
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.send_header("Pragma", "no-cache")
        super().end_headers()

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send_json(self, payload: dict, status: int = 200) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b"{}"
        return json.loads(raw.decode("utf-8") or "{}")

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def _query_weapon(self) -> str:
        query = parse_qs(urlparse(self.path).query)
        values = query.get("weapon", [])
        return _normalize_weapon(values[0] if values else None)

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/api/layout":
            self._send_json(load_layout())
            return
        if path == "/api/preset":
            self._send_json(load_preset(self._query_weapon()))
            return
        if path == "/api/version":
            self._send_json(load_version())
            return
        if path.startswith("/assets/"):
            rel = path[len("/assets/") :]
            file_path = WORKSPACE / "assets" / rel
            if file_path.is_file():
                data = file_path.read_bytes()
                ctype = "image/png" if file_path.suffix == ".png" else "application/octet-stream"
                self.send_response(200)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
                return
            self.send_error(404)
            return
        super().do_GET()

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        try:
            payload = self._read_json()
            if path == "/api/layout":
                save_layout(payload)
                self._send_json({"ok": True, "layout": load_layout()})
                return
            if path == "/api/preset":
                save_preset(payload, self._query_weapon())
                self._send_json({"ok": True, "preset": load_preset(self._query_weapon())})
                return
            self.send_error(404)
        except Exception as exc:  # noqa: BLE001
            self._send_json({"ok": False, "error": str(exc)}, status=500)


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Card tuner web UI: http://{HOST}:{PORT}/")
    print(f"Also try: http://localhost:{PORT}/")
    server.serve_forever()


if __name__ == "__main__":
    main()
