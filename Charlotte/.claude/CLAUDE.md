# Charlotte – project context

A small Godot 4.7 2D game (GL Compatibility, 1280×720, `canvas_items` stretch) about Charlotte,
a little girl, on her street in Montréal (Rosemont): her side of **6e Avenue** between
**Rue Dandurand** (left) and **Rue Holt** (right), in autumn. In-game text is in **French** (Québec).

Current state: a living, side-scrolling street. Charlotte walks with ←/→ or by clicking/tapping the street; double-pressing the arrow or double-clicking/tapping makes her run
(`Character.running`, `RUN_SPEED` × walk speed, eased; `Character.speed()` gives the current speed).
Interactions: click (or tap) a stray cat or a passerby's dog and Charlotte walks over and pets it. Click her front door
(ground floor of `duplex_charlotte`, n° 5672) to go inside her flat. No goals yet.

## Run / verify

- Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot` (not on PATH).
- Main scene: `res://scenes/intro.tscn` (title screen) → "Démarrer" / Enter → `res://scenes/main.tscn` (street)
  ⇄ `res://scenes/house.tscn` (inside, through her front door).
- Screenshots (use them to check visual changes):
  - `Godot --path . res://scenes/intro.tscn -- --screenshot=/path/intro.png`
  - `Godot --path . res://scenes/main.tscn -- --screenshot=/path/main.png [--x=1234] [--wait=6]` (`--x` = Charlotte's start x, `--wait` = seconds before the shot)
  - `Godot --path . res://scenes/house.tscn -- --screenshot=/path/house.png [--x=1234] [--wait=1]` (x ≥ 5000 = bedroom)
  - `Godot --path . res://tools/lineup.tscn -- --screenshot=/path/lineup.png [--seed=1]` (character design sheet)
  - `Godot --path . res://tools/animals.tscn -- --screenshot=/path/animals.png [--focus=x,y --zoom=3]` (cat coats/poses, squirrels,
    dog breeds, Charlotte petting a cat and dogs; use focus/zoom to inspect details)
  - Add `--quit-after 2000` so a run can never hang; after editing SVGs or adding a new `class_name` script, run `Godot --headless --path . --import` first
    (otherwise the new class is "not declared").

## Layout

- `scenes/main.gd` builds the whole street in code from `LAYOUT` (an ordered list of house SVG names) and
  placement arrays (`TREES_AFTER`, `LAMPS_AFTER`, `HYDRANTS_AT`, `RACKS_AT`). Fractional values = position between house indices.
  `LAYOUT` runs: `ecole` (école Saint-Jean-de-Brébeuf, across Dandurand), `rue_dandurand`, Charlotte's block (dépanneur Xin-Xin …
  `coin_holt`), `rue_holt`, `coin_holt_est`. Entries in `CROSS_STREETS` are gaps (width in px), not SVGs: `CrossStreet`
  (`world/cross_street.gd`) draws them in one-point perspective as three nodes in the draw order: `VISTA` (before the houses:
  receding street, walls along it from `left_walls`/`right_walls`, street trees), `GROUND` (after `Street`: asphalt through the
  sidewalk, curb ramps, crosswalk, yellow in the school zone) and `SIGNS` (with the props: plates, stop/school sign, utility pole
  and wires). Charlotte's bounds stop at the curbs (`CrossStreet.road_x`); crossing streets and turning corners are planned.
  Passersby already walk across on the crosswalks. `reference/` has photos of the Dandurand corner and `google_map_immediate_area.png`.
- `scenes/intro.gd` builds a shorter copy of the same street (5 houses around Charlotte's duplex), plus the logo and start button.
  Its geometry helpers mirror `main.gd`, so a layout/geometry change in one may need the same change in the other.
- `scenes/house.gd`: the flat as a side-on cross-section, from the photos in `reference/charlotte_house_inside`:
  vestibule (0–640) → oak glass doorway → salon (–2260) → hallway → kitchen (3400–3960); Charlotte's bedroom is a separate
  area (5000–6650) reached through the "chacha" door (fade, camera limits switch). Walls/floor are drawn by its inner `_Rooms`
  class; furniture comes from `world/interior_art.gd` (`InteriorArt`, one SVG function per piece). Charlotte is at scale 0.5 inside.
  Place pieces with `_put(tex, x, bottom, scale, shadow)`: `"wall"` for hung things, `"floor"` for standing furniture (adds a
  contact shadow). Windows get `_daylight()` beams; lamps get additive `_glow()`s. Add pieces in back-to-front order.
- Charlotte's hamster (`world/hamster.gd`, `Hamster`) lives in the terrarium on her bedroom dresser. The terrarium art is two
  layers, `InteriorArt.terrarium(false)` behind and `terrarium(true)` in front (glass glare, things on the dresser); the
  hamster node shares its position/scale and works in its canvas units. It wanders, grooms, runs its wheel, naps in the
  hideout, and stands up with hearts when clicked.
- `characters/`: `Character` (paper-cutout puppet: walk cycle, blink, hair follow-through), `PlayerControl` (keys and
  click/tap-to-walk, walks to interactables and calls them; used by the street and the house), `CharacterArt` (generates the
  body-part SVGs from a look), `CharacterLook` (Resource; `CharacterLook.charlotte()` and `CharacterLook.random(rng, age)`).
- `world/`: one `class_name` per element (`SkyBackdrop`, `Skyline`, `Cloud`, `Birds`, `Street`, `Cat` (railing cat), `Squirrel`, `Passerby`, `PropArt`),
  plus `StrayCat` (procedural sidewalk cats: 8 coats, walk/sit/loaf/pet), `Dog` (9 breeds on a leash, attached to a passerby's
  `Character.hand_position()`), `WindowCats` (cats that pop up behind window panes near the camera), `Wind` (periodic gusts:
  drives the `gust` uniform of every sway material + a leaf flurry), `LeafKick` (leaves kicked by Charlotte's feet),
  `Foreground` (blurred near-camera layer, `Parallax2D` scroll 1.35), `Squirrel` (flees Charlotte, from further away when she
  runs, often up the nearest street tree; climbs the trunk's side, hides in the canopy and pokes its head out at the
  canopy outline, found from the tree texture's alpha. Squirrels are added before the trees so the tree hides them;
  `squirrel.trees` shares the scene's `_tree_sprites` array, filled later), `CritterDraw` (shared static drawing helpers for the
  animals: shaded outlined bodies, tapered limbs/tails built from convex quads, glossy eyes, hearts).
  `PropArt` generates trees, lamp posts, hydrants, bikes, leaves as textures. `PropArt.car()`/`wheel()` still exist but
  cars were removed from both scenes on purpose (2026-10-31); see git history to bring them back.
- `shaders/`: `grade.gdshader` (full-screen colour grade on CanvasLayer 50), `sway.gdshader` (tree sway).
- `art/decor/windows.json`: window panes per house, written by the generator, read by `WindowCats`. It is not a resource:
  an export preset needs `*.json` in its include filter.
- `art/decor/*.svg`: house façades, **generated**. Edit `tools/generate_houses.gd` and regenerate instead of hand-editing:
  `Godot --headless --path . --script res://tools/generate_houses.gd`
- `art/logo.png` is cut out of `art/logo.jpg` by `tools/cutout_logo.gd` (same headless invocation).
- `reference/` holds real-world reference photos (Charlotte, her house, the neighbours, the Google Maps view). It is gitignored.

## Interactions and scene changes

- Anything clickable joins the `interactable` group and implements `can_interact()`, `hit_test(point)`, `approach_x(from_x)`,
  `reserve()`, `release()` and `interact(charlotte)` (see `StrayCat`), and optionally `focus_x()` (where Charlotte should look). `main.gd` walks Charlotte to `approach_x`, then calls `interact`.
- Input is mouse-based with event positions converted to world space, so touch works through emulated mouse events.
- Doors are `DoorSpot.make(rect, action)` interactables. `Transition` fades (`fade_in`, `through_black`, `change_scene`) and
  holds cross-scene state as static vars (`Transition.street_x`: where Charlotte reappears on the street).
- To test click flows, write a temporary `extends SceneTree` script and run it with `-s` (a scene-based test node gets freed
  by `change_scene_to_file`); send clicks with `Input.parse_input_event`, then delete the script.
- Petting: `Character.pet(seconds, low)` lunges (low 1 = deep, for cats/small dogs; 0 = standing, arm out, for big dogs) and
  strokes with the front hand. The animal is drawn just in front of Charlotte so her hand lands on its head: stray cats walk at
  y 646 (she is at 638); a dog being petted steps 32 px toward the camera and gets z_index 1, while its walker `hold()`s.

## Conventions

- Art is made procedurally in code: SVG strings or `_draw()`. There are no hand-drawn sprites except the logo.
- Performance: a `_draw()` node spanning the whole street is never culled and redraws every command each frame, and every
  `draw_set_transform` breaks batching. Thousands of small shapes (leaves, grit) therefore go into one vertex-coloured mesh
  (`Street._Batch`); before that the street ran at about 35 fps on an M1. Check with
  `RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)` (the street is about 700).
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
