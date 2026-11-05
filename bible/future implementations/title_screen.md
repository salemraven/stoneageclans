# Title screen

**Status:** Not the front door. The game still boots into `scenes/Main.tscn`. `scenes/TitleScreen.tscn` exists only as a stub: NEW GAME is live, LOAD GAME and SETTINGS are dim labels.

This screen is later work. It has two jobs before a game starts: make the player character, then set sandbox options.

## Flow

1. Title. Background stays `titlescreen.png`.
2. **New Game** opens the character creator. Confirming it loads `Main.tscn` with that person as the player.
3. **Settings** opens the sandbox menu. It does not start a game. Changes save immediately.
4. **Load Game** stays disabled until saves exist.

Normal launch (`tools/launch_game_mac.sh` with no arguments, and `project.godot` `run/main_scene`) keeps opening Main until this screen is actually built. Test launches that pass extra arguments stay on Main.

## Character creator

The player is one caveman, made before the camp exists. Use the appearance genes that already ship. Do not invent a second face system.

Pick and show:

- Name
- Body height and width
- Skin
- Hair
- Nose (`nose1`–`nose14`)
- Brow (`brow1`–`brow12`)
- Eye size, eye shape, pupil color

Store the result the same way a founder with no parents is stored (`random_founder_genome` / `fill_missing_loci` in [genetics.md](../genetics.md)). Children born later still inherit from this genome. Clothes and hair stay parented to the body or head they sit on.

The creator does not pick clan name, skills, or starting gear. Those stay whatever Main already does for a new game.

## Settings

One sandbox control for now.

**AI productivity.** Slider from 0.50 to 2.00, step 0.25. Default 1.00.

- Left is easier (AI camps slower). Right is harder (AI camps faster).
- The player camp is never scaled.
- `--pace-arena` ignores the slider and stays at 1.00.

The value already lives on the `SandboxSettings` autoload and is saved at `user://sandbox_settings.cfg`. The title menu is what still needs to be built. It should read `ai_productivity()`, write with `set_ai_productivity()`, and show `pace_label()` (Easier / Normal / Harder) plus the number.

What that number already changes, AI clans only:

- Off-screen settlement time: herding, huts, births, growth, abstract gather
- Awake AI pregnancy and baby growth (sleeping bodies are not scaled a second time)
- How many AI men can herd at once, still capped by the number of grown men

## Not in this pass

- Do not make TitleScreen the main scene.
- Do not enable the SETTINGS label.
- Do not build the creator UI.
- Load game, audio, and display options wait until this screen exists.
