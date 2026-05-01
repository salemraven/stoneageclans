#!/usr/bin/env bash
# Export Godot Web preset "Web" (see export_presets.cfg → build/web/index.html),
# sync into gh-pages branch root (matches https://github.com/salemraven/stoneageclans/settings/pages),
# commit + push so the live site serves the newest exported build.
#
# Prereqs:
#   - Godot 4.x with Web export templates installed (Editor → Manage Export Templates).
#   - git remote origin push access.
#   - Local project files reflect the code you want to ship (export uses disk, not only last commit).
#
# Usage (from repo root):
#   bash tools/deploy_github_pages.sh
#   GODOT=/path/to/Godot bash tools/deploy_github_pages.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT_BIN="${GODOT:-}"
if [[ -z "${GODOT_BIN}" ]] && [[ "$(uname)" == "Darwin" ]]; then
	GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
fi
if [[ ! -x "${GODOT_BIN}" ]]; then
	echo "ERROR: Set GODOT to your Godot 4.x executable (with Web templates installed)." >&2
	exit 1
fi

EXPORT_OUT="${ROOT}/build/web"
mkdir -p "${EXPORT_OUT}"

echo "Exporting Web preset to ${EXPORT_OUT}/index.html ..."
SKIP_SINGLE_INSTANCE=1 "${GODOT_BIN}" --headless --path "${ROOT}" --export-release "Web" "${EXPORT_OUT}/index.html"

if [[ ! -f "${EXPORT_OUT}/index.html" ]]; then
	echo "ERROR: Export did not produce build/web/index.html" >&2
	exit 1
fi

MAIN_REV="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
STAMP="$(date -u +"%Y-%m-%dT%H:%MZ") ${MAIN_REV}"
echo "${STAMP}" > "${EXPORT_OUT}/BUILD.txt"

WORKTREE="${ROOT}/.deploy_gh_pages_worktree"
git fetch origin gh-pages
git branch -f gh-pages origin/gh-pages

if [[ -d "${WORKTREE}" ]]; then
	git worktree remove "${WORKTREE}" --force 2>/dev/null || rm -rf "${WORKTREE}"
fi

git worktree add --force "${WORKTREE}" gh-pages

echo "Syncing export → gh-pages worktree ..."
# Mirror export artifacts to branch root (same layout as current gh-pages)
rsync -a --delete "${EXPORT_OUT}/" "${WORKTREE}/"

pushd "${WORKTREE}" >/dev/null
git add -A
if git diff --staged --quiet; then
	echo "No changes vs origin/gh-pages (export identical)."
	popd >/dev/null
	git worktree remove "${WORKTREE}" --force
	exit 0
fi

git commit -m "chore(pages): web export ${STAMP}"
git push origin gh-pages
popd >/dev/null

git worktree remove "${WORKTREE}" --force

echo ""
echo "Done. Give GitHub Pages ~1–2 minutes, then hard-refresh the game tab."
echo "Open https://<your-user>.github.io/<repo>/BUILD.txt to verify export time + main commit (stamp)."
echo "Repo Settings → Pages should use branch gh-pages / root."
