# Charlotte – project context

A small Godot 4.7 2D game (GL Compatibility, 1280×720, `canvas_items` stretch) about Charlotte,
a little girl, on her street in Montréal (Rosemont): her side of **6e Avenue** between
**Rue Dandurand** (left) and **Rue Holt** (right), in autumn. In-game text is in **French** (Québec).

Current state: a living, side-scrolling street. Charlotte walks with ←/→ or by clicking/tapping the street.
First interaction: click (or tap) a stray cat and Charlotte walks over and pets it. No goals yet.

## Run / verify

- Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot` (not on PATH).
- Main scene: `res://scenes/intro.tscn` (title screen) → "Démarrer" / Enter → `res://scenes/main.tscn`.
- Screenshots (use them to check visual changes):
  - `Godot --path . res://scenes/intro.tscn -- --screenshot=/path/intro.png`
  - `Godot --path . res://scenes/main.tscn -- --screenshot=/path/main.png [--x=1234] [--wait=6]` (`--x` = Charlotte's start x, `--wait` = seconds before the shot)
  - `Godot --path . res://tools/lineup.tscn -- --screenshot=/path/lineup.png [--seed=1]` (character design sheet)
  - `Godot --path . res://tools/animals.tscn -- --screenshot=/path/animals.png` (cat coats/poses, squirrels, dog breeds, Charlotte petting)
  - Add `--quit-after 2000` so a run can never hang; after editing SVGs run `Godot --headless --path . --import` first.

## Layout

- `scenes/main.gd` builds the whole street in code from `LAYOUT` (an ordered list of house SVG names) and
  placement arrays (`TREES_AFTER`, `LAMPS_AFTER`, `HYDRANTS_AT`, `RACKS_AT`). Fractional values = position between house indices.
- `scenes/intro.gd` builds a shorter copy of the same street (5 houses around Charlotte's duplex), plus the logo and start button.
  Its geometry helpers mirror `main.gd`, so a layout/geometry change in one may need the same change in the other.
- `characters/`: `Character` (paper-cutout puppet: walk cycle, blink, hair follow-through), `CharacterArt` (generates the
  body-part SVGs from a look), `CharacterLook` (Resource; `CharacterLook.charlotte()` and `CharacterLook.random(rng, age)`).
- `world/`: one `class_name` per element (`SkyBackdrop`, `Skyline`, `Cloud`, `Birds`, `Street`, `Cat` (railing cat), `Squirrel`, `Passerby`, `PropArt`),
  plus `StrayCat` (procedural sidewalk cats: 8 coats, walk/sit/loaf/pet), `Dog` (9 breeds on a leash, attached to a passerby's
  `Character.hand_position()`), `WindowCats` (cats that pop up behind window panes near the camera), `Wind` (periodic gusts:
  drives the `gust` uniform of every sway material + a leaf flurry), `LeafKick` (leaves kicked by Charlotte's feet),
  `Foreground` (blurred near-camera layer, `Parallax2D` scroll 1.35).
  `PropArt` generates trees, lamp posts, hydrants, bikes, leaves as textures. `PropArt.car()`/`wheel()` still exist but
  cars were removed from both scenes on purpose (2026-10-31); see git history to bring them back.
- `shaders/`: `grade.gdshader` (full-screen colour grade on CanvasLayer 50), `sway.gdshader` (tree sway).
- `art/decor/windows.json`: window panes per house, written by the generator, read by `WindowCats`. It is not a resource:
  an export preset needs `*.json` in its include filter.
- `art/decor/*.svg`: house façades, **generated**. Edit `tools/generate_houses.gd` and regenerate instead of hand-editing:
  `Godot --headless --path . --script res://tools/generate_houses.gd`
- `art/logo.png` is cut out of `art/logo.jpg` by `tools/cutout_logo.gd` (same headless invocation).
- `reference/` holds real-world reference photos (Charlotte, her house, the neighbours, the Google Maps view). It is gitignored.

## Interactions

- Anything clickable joins the `interactable` group and implements `can_interact()`, `hit_test(point)`, `approach_x(from_x)`,
  `reserve()`, `release()` and `interact(charlotte)` (see `StrayCat`). `main.gd` walks Charlotte to `approach_x`, then calls `interact`.
- Input is mouse-based with event positions converted to world space, so touch works through emulated mouse events.
- Petting: `Character.pet(seconds)` puts her in a lunge with the front hand stroking; stray cats are drawn just in front of
  Charlotte (y 646 vs 638) so the hand lands on their heads.

## Conventions

- Art is made procedurally in code: SVG strings or `_draw()`. There are no hand-drawn sprites except the logo.
- The world uses a fixed RNG seed (`2026`) so the street looks the same on every run.
- Shared y-coordinates (`HOUSE_BASE_Y 592`, `CHARLOTTE_Y 638`, `CURB_Y 664`) and scales (`HOUSE_SCALE 0.57`,
  `CHAR_SCALE 0.38`, `TREE_SCALE 0.55`) are duplicated as constants in `main.gd` and `intro.gd`. Keep them in sync.
- UI above the grade goes on a CanvasLayer > 50 so it keeps its true colours.
- Palette: warm autumn street; UI blue `#1D4F91`, yellow `#FFD23F`, cream `#E8DDD0`.
- GDScript style: static typing, `:=`, tabs, short section-banner comments.
- Light comes from the low sun on the upper left: highlights on the left, shadows thrown to the right.
- In the shell, `rm` is aliased to `rm -i` (it hangs waiting for input); use `/bin/rm -f`.

## Repo

- The git repo root is the parent folder `jeux/`. It also contains `bebe-scutigere/`, a separate web game.
- The repo uses `~/.ssh/githubkey` via the repo-local `core.sshCommand`. The remote is `git@github-personal:jullmg/jeux.git`.
