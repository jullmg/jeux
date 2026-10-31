# Charlotte – project context

A small Godot 4.7 2D game (GL Compatibility, 1280×720, `canvas_items` stretch) about Charlotte,
a little girl, on her street in Montréal (Rosemont): her side of **6e Avenue** between
**Rue Dandurand** (left) and **Rue Holt** (right), in autumn. In-game text is in **French** (Québec).

Current state: a living, side-scrolling street you walk along with ←/→. No goals or interactions yet.

## Run / verify

- Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot` (not on PATH).
- Main scene: `res://scenes/intro.tscn` (title screen) → "Démarrer" / Enter → `res://scenes/main.tscn`.
- Screenshots (use them to check visual changes):
  - `Godot --path . res://scenes/intro.tscn -- --screenshot=/path/intro.png`
  - `Godot --path . res://scenes/main.tscn -- --screenshot=/path/main.png [--x=1234]` (`--x` = Charlotte's start x)
  - `Godot --path . res://tools/lineup.tscn -- --screenshot=/path/lineup.png [--seed=1]` (character design sheet)

## Layout

- `scenes/main.gd` builds the whole street in code from `LAYOUT` (an ordered list of house SVG names) and
  placement arrays (`TREES_AFTER`, `LAMPS_AFTER`, `HYDRANTS_AT`, `RACKS_AT`, `CARS_AT`). Fractional values = position between house indices.
- `scenes/intro.gd` builds a shorter copy of the same street (5 houses around Charlotte's duplex), plus the logo and start button.
  Its geometry helpers mirror `main.gd`, so a layout/geometry change in one may need the same change in the other.
- `characters/`: `Character` (paper-cutout puppet: walk cycle, blink, hair follow-through), `CharacterArt` (generates the
  body-part SVGs from a look), `CharacterLook` (Resource; `CharacterLook.charlotte()` and `CharacterLook.random(rng, age)`).
- `world/`: one `class_name` per element (`SkyBackdrop`, `Skyline`, `Cloud`, `Birds`, `Street`, `Cat`, `Squirrel`, `Passerby`, `PropArt`).
  `PropArt` generates trees, lamp posts, hydrants, cars, wheels, bikes, leaves as textures.
- `shaders/`: `grade.gdshader` (full-screen colour grade on CanvasLayer 50), `sway.gdshader` (tree sway).
- `art/decor/*.svg`: house façades, **generated**. Edit `tools/generate_houses.gd` and regenerate instead of hand-editing:
  `Godot --headless --path . --script res://tools/generate_houses.gd`
- `art/logo.png` is cut out of `art/logo.jpg` by `tools/cutout_logo.gd` (same headless invocation).
- `reference/` holds real-world reference photos (Charlotte, her house, the neighbours, the Google Maps view). It is gitignored.

## Conventions

- Art is made procedurally in code: SVG strings or `_draw()`. There are no hand-drawn sprites except the logo.
- The world uses a fixed RNG seed (`2026`) so the street looks the same on every run.
- Shared y-coordinates (`HOUSE_BASE_Y 592`, `CHARLOTTE_Y 638`, `CURB_Y 664`) and scales (`HOUSE_SCALE 0.57`,
  `CHAR_SCALE 0.38`, `TREE_SCALE 0.55`) are duplicated as constants in `main.gd` and `intro.gd`. Keep them in sync.
- UI above the grade goes on a CanvasLayer > 50 so it keeps its true colours.
- Palette: warm autumn street; UI blue `#1D4F91`, yellow `#FFD23F`, cream `#E8DDD0`.
- GDScript style: static typing, `:=`, tabs, short section-banner comments.

## Repo

- The git repo root is the parent folder `jeux/`. It also contains `bebe-scutigere/`, a separate web game.
- The repo uses `~/.ssh/githubkey` via the repo-local `core.sshCommand`. The remote is `git@github-personal:jullmg/jeux.git`.
