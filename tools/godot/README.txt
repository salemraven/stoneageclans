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

Regression check: run tools/verify_vscode_godot_setup.ps1 or VS Code task "Godot: Verify Cursor/VS Code setup".

If Godot "can't find" the project after renaming the folder (e.g. Stone Age Clans -> StoneAgeClans):
- Godot's Project Manager stores RECENT paths in your user profile, not in this repo. The old path is a dead link.
- Fix A (one-time on this PC): create a junction so the saved path works again (run cmd.exe as your user):
    mklink /J "c:\Users\mxz\Desktop\stoneageclans\Stone Age Clans" "c:\Users\mxz\Desktop\stoneageclans\StoneAgeClans"
  Adjust paths if your Desktop layout differs. Restart Godot.
- Fix B: Project Manager -> Remove Missing -> Import -> pick the folder that contains project.godot (StoneAgeClans).
- Fix C: Double-click Open_In_Godot_Editor.cmd in the project root (passes --path explicitly).
- Cursor: File -> Open Folder -> StoneAgeClans (not the old folder name).
