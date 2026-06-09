# “Couldn’t save scene … dependencies couldn’t be satisfied” — what it means and how to fix it

**Plain language:** Godot is trying to write your scene file to disk, but it cannot safely do that because something linked to that scene is missing, broken, or out of sync (another scene, a script, a texture, or the editor’s own copy of a file).

This is **not** one single bug in your project — it is a **symptom**. Fix it by finding **which** link is broken for **the scene you are saving**.

---

## 1. See the real error (most important)

1. In Godot, open the **Output** panel (bottom) or **Debugger → Errors**.
2. Try **saving the scene again**.
3. Look for a **red** line that names a **file path** or **script** — that is usually the actual problem.

If you tell the assistant **that exact line** (or a screenshot), we can target the fix.

---

## 2. Cursor + Godot at the same time (very common in this project)

If you edit the **same** scripts in **Cursor** and in **Godot**, the editor can hold an **old copy** in memory. Saving a scene then fails because Godot sees mismatched scripts or dependencies.

**What helps:**

1. In Godot: **Editor → Editor Settings → Text Editor → Behavior** → turn **Auto Reload Scripts on External Change** **ON** (this project also loads **`addons/external_edit_sync`** to nudge this).
2. After saving files in **Cursor**, switch to Godot and let scripts reload — or **Project → Reload Current Project** if it still feels wrong.
3. If a script tab in Godot has **unsaved** changes that conflict with disk, **save or discard** there before saving scenes.
4. **Practical habit:** Edit **`.gd` scripts** in Cursor; do **scene (`.tscn`) layout** in Godot when possible — fewer conflicts.

---

## 3. Broken script (second most common)

If **any** script attached to the scene (or to an instanced child) has a **syntax error**, Godot may refuse to save.

- Open the script; check the **Script** editor for red underlines.
- Or run a headless check from the project folder (developers use this):  
  `godot --path . --headless --quit-after 1`  
  and read the console for **Parse Error** / **Compile Error**.

---

## 4. Missing or moved files

If the scene references a texture, scene, or resource that was **moved, renamed, or deleted**, save can fail until you **fix the path** in the Inspector or **restore the file** from git.

**This repo:** Under `char2/`, texture file names use names like `Left_ALeftm.png`, not always `L_Arm.png`. Old `*.import` files for **missing** PNGs may show as deleted in git — that is only a problem if something still references those old paths. **Check the Output** when saving.

---

## 5. If you are stuck right now (quick sequence)

1. **Save or revert** every open script in Godot (no `*` on tabs).
2. **Save all** in Cursor for the same project, then focus Godot.
3. **Project → Reload Current Project** (or close Godot fully and reopen).
4. Open **only** the scene that failed, try **Save** again.
5. If it still fails, copy **every red line** from **Output** after the save attempt.

---

## 6. “Once and for all”

You can’t guarantee the dialog **never** appears (any future bad path or merge can break a dependency), but you **can** make it rare:

- Keep **Auto Reload** on and avoid **two editors** editing the **same** file without saving.
- After big git changes, **reload the project** once in Godot.
- Fix **script errors** immediately so scenes stay saveable.

---

_Last updated: 2026-04-15 — Stone Age Clans project._
