#!/usr/bin/env bash
# Local definition wiki. Open http://127.0.0.1:8000
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 -m venv wiki/.venv
wiki/.venv/bin/pip install -q -r wiki/requirements.txt
exec wiki/.venv/bin/mkdocs serve -a 127.0.0.1:8000
