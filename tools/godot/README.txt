Place Godot 4.6.x (standard win64) here — do not commit the .exe (see repo .gitignore).

Download: https://godotengine.org/download/windows/
Rename to match scripts if needed: Godot_v4.6.1-stable_win64.exe

Optional (recommended for headless / CI): also drop the console build here as
  Godot_v4.6.1-stable_win64_console.exe
godot.cmd prefers the console build when present (cleaner stdout).

Cursor / VS Code (godot-tools)
- Workspace setting godotTools.editorPath.godot4 must be relative to the project root, e.g.
    tools/godot/Godot_v4.6.1-stable_win64.exe
  Do not use ${workspaceFolder} in that setting — the extension joins paths incorrectly.
- godotTools.lsp.headless (in .vscode/settings.json) runs a headless Godot for the language
  server so you do not need the editor window open. Set to false if you prefer connecting
  only to an already-running Godot editor.

Tasks and scripts use tools/godot/godot.cmd (portable; works on any clone path).
