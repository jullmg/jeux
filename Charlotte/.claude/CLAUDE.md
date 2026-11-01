# Charlotte – project context

A small Godot 4.7 2D game (GL Compatibility, 1280×720, `canvas_items` stretch) about Charlotte,
a little girl, on her street in Montréal (Rosemont): her side of **6e Avenue** between
**Rue Dandurand** (left) and **Rue Holt** (right), in autumn. In-game text is in **French** (Québec).

Current state: a living, side-scrolling street. Charlotte walks with ←/→ or by clicking/tapping the street; double-pressing the arrow or double-clicking/tapping makes her run
(`Character.running`, `RUN_SPEED` × walk speed, eased; `Character.speed()` gives the current speed).
Interactions: click (or tap) a stray cat or a passerby's dog and Charlotte walks over and pets it. Click her front door
(ground floor of `duplex_charlotte`, n° 5672) to go inside her flat. In her bedroom, click the dresser's drawers to open her
wardrobe and change clothes. Click her desk to draw (`ui/drawing_pad.gd`, `DrawingPad`: crayons, sizes, eraser); "Sur le frigo !" saves the
drawing to `user://drawings/` (newest 4 kept) and sticks it on the kitchen fridge. Delete that folder after tests.
Click the bookshelf in her bedroom to read (`ui/book_reader.gd`, `BookReader`: four short original stories, a
picture and text per page). Click her bed to sleep: night falls, "Bonne nuit, Chacha…", then "Le lendemain matin…" and `Season.day` goes up.
Click the fridge: it opens (`InteriorArt.fridge_open()`) and she takes a random snack (`InteriorArt.snack(kind)`), "Miam !".
Click the hallway TV to turn it on and change channels, then off. `world/tv_shows.gd` (`TvShows`) is the
catalogue of channels, all original (no copyrighted shows or characters): news, animals, cartoon, hockey, weather, the
sitcom "Les Ratons", cooking, space, music, game show; `TvShows.draw(id, canvas, t, on_for)`. `world/tv_screen.gd`
(`TvScreen`, a `Control`) is one TV for any house: set its `channels` (TvShows ids) to give it its own lineup. No goals yet.

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
  - Add `--season=winter` (spring, summer, autumn, winter; or printemps/été/automne/hiver) to any of these to see a season.
  - Add `--quit-after 2000` so a run can never hang; after editing SVGs or adding a new `class_name` script, run `Godot --headless --path . --import` first
    (otherwise the new class is "not declared").

## Layout

- Streets extend `world/street_scene.gd` (`StreetScene`): it builds sky, skyline, houses, cross streets, sidewalk, trees,
  lamps, hydrants, racks, passersby, cats, squirrels, Charlotte and the camera from data the street sets in `_init()`
  (`layout`: ordered house SVG names; `cross_streets`; `trees_after`, `lamps_after`, `hydrants_at`, `racks_at`,
  `squirrels_at`; fractional values = position across a building), plus hooks (`_start_x`, `_walk_bounds`,
  `_build_cross_streets`, `_decorate_house`, `_build_landmarks`, `_build_doors`, `_build_sidewalk_props` (against the
  buildings, behind people), `_build_extra_props` (curbside, in front of people)).
- `scenes/main.gd` (6e Avenue) is one such street; `scenes/dandurand.gd` (Rue Dandurand: dépanneur Xin-Xin's real front,
  `depanneur_front` in the generator, with 6e Avenue crossing at its right end) is another.
- Turning corners: `StreetScene._add_corner(cross_street, scene, key)` makes the cross street clickable: Charlotte walks to
  the curb, the other street loads with `Transition.arrive = key`, and that street's `_start_x()` checks `_arriving(key)`
  to put her at the matching corner. 6e ⇄ Dandurand works both ways. A corner only works from the sidewalk Charlotte
  started on, and its click area is the vista above the crosswalk.
- Crossing streets: the sidewalk is split into stretches at each cross street's curbs (`StreetScene._segments`); Charlotte
  walks one stretch at a time. Every crosswalk is clickable (`_add_crossing`, automatic): she goes to the curb on her side,
  says "Je regarde des deux côtés !" and looks both ways, then walks across on her own (`PlayerControl.hands_off`) to the
  other stretch. `CrossStreet.guard = true` (the school's crosswalk on Dandurand) adds a `CrossingGuard`
  (`world/crossing_guard.gd`, neon-yellow coat and cap) who steps out with her ARRÊT paddle while Charlotte crosses.
  `Bubble.say(parent, at, text)` shows a speech bubble anywhere; `DoorSpot` takes an optional `approach` and `condition`.
- Real-world rules (from the Google Maps view): back lanes (ruelles) only open onto the north-south avenues like 6e
  Avenue, never onto Dandurand or Holt (no "gap" walls or `ruelle` buildings there). Every intersection has a street-name
  post at both corners (`CrossStreet` SIGNS): the plate of the street we're on faces us, the cross street's plate is
  slanted along that street toward its vanishing point. Overhead wires run pole to pole across the whole view.
  `layout` runs: `ecole` (école Saint-Jean-de-Brébeuf, across Dandurand), `rue_dandurand`, Charlotte's block (`depanneur`: the
  side of dépanneur Xin-Xin, which fronts Dandurand; `garages`; `ruelle_verte`, the green lane with its sign; … `coin_holt`),
  `rue_holt`, `coin_holt_est`. The first three buildings of the block are drawn from the photos in `reference/` (the user wants
  every detail as close to the pictures as possible). The cross-street vistas run to the horizon with Mount Royal at the end. Entries in `cross_streets` are gaps (width in px), not SVGs: `CrossStreet`
  (`world/cross_street.gd`) draws them in one-point perspective as three nodes in the draw order: `VISTA` (before the houses:
  receding street, walls along it from `left_walls`/`right_walls`, street trees), `GROUND` (after `Street`: asphalt through the
  sidewalk, curb ramps, crosswalk, yellow in the school zone) and `SIGNS` (with the props: plates, stop/school sign, utility pole
  and wires). Charlotte's bounds stop at the curbs (`CrossStreet.road_x`); crossing streets and turning corners are planned.
  Passersby already walk across on the crosswalks. `reference/` has photos of the Dandurand corner and `google_map_immediate_area.png`.
- `scenes/intro.gd` builds a shorter copy of the same street (5 houses around Charlotte's duplex), plus the logo and start button.
  Its geometry helpers mirror `main.gd`, so a layout/geometry change in one may need the same change in the other.
- Interiors are built from reusable parts, meant for future house insides too:
  - `world/interior.gd` (`Interior`, base class): Charlotte + `PlayerControl` + camera (`_spawn_charlotte`), areas
    (`_enter_area`, `_go_through` with a fade), furniture `_put(tex, x, bottom, scale, shadow)` (`"wall"` for hung things,
    `"floor"` for standing furniture, adds a contact shadow; add pieces back to front), `_plate`, light (`_daylight` beams with
    dust motes, additive `_glow`, `_ceiling_light`, swaying `_pendant`, flickering `_candle`), `_fairy_lights`,
    `_switchable(area, stand_x, lights, room)` (wall switches/lamps that toggle lights and dim the room), and `_finish()`
    (foreground, colour grade, fade-in, `--screenshot=`).
  - `world/room_shell.gd` (`RoomShell`): walls/ceiling/crown moulding/baseboards and a glossy narrow-strip hardwood floor, all from
    data (`rooms`, `chair_rails`, `posts`, `casings`, `gleams` = x of lights mirrored on the floor).
  - `world/interior_art.gd` (`InteriorArt`): one SVG function per piece of furniture; `world/fairy_lights.gd` (`FairyLights`).
- `scenes/house.gd` (extends `Interior`): Charlotte's flat, from the photos in `reference/charlotte_house_inside`:
  vestibule (0–640) → oak glass doorway → salon (–2260) → hallway → kitchen (3400–3960); Charlotte's bedroom is a separate
  area (5000–6650) reached through the "chacha" door (fade, camera limits switch). Charlotte is at scale 0.5 inside.
- `scenes/depanneur.gd` (extends `Interior`): inside dépanneur Xin-Xin, entered from its door on Rue Dandurand (bell). A
  crammed corner store: cash machine, newspapers, counter (till, scratch tickets) with the shopkeeper (an Asian man: short
  black hair, warm light skin, dark eyes; on a raised floor behind the counter) and a wall of shelves behind her, a real-time
  clock, a specials board, the candy wall, low gondolas mid-floor, bread rack, coffee/hot chocolate corner, the sloche
  machine (animated swirls; Québec word "sloche", not "barbotine"), freezer, drinks fridges, dairy cooler with 4 L milk
  bags, stockroom door, security mirror. Furniture from `world/shop_art.gd` (`ShopArt`): original artwork, never real logos;
  real names only as plain text labels ("LOTO-QUÉBEC", "SLUSH PUPPIE"). Checkered floor
  and suspended ceiling (`RoomShell.floor_style = "tiles"`, `ceiling_style = "drop"`); blurred "shelf" foreground. Click
  the shopkeeper to say hello; candy, sloche, coffee corner, freezer, fridges or dairy to buy something.
  `Interior._say(who, text)` (speech bubble) and `Interior._treat(picture, text)` (what Charlotte gets) are reusable.
- Charlotte's parents, from `reference/mere_charlotte.jpg` / `pere_charlotte.jpg`: `CharacterLook.mom()` (long wavy light-brown
  hair, brown eyes, black knit sweater, jeans) in the kitchen, `CharacterLook.dad()` (short brown hair, no cap,
  `facial_hair = "stubble"`, blue eyes, navy sweater) in the salon. Click them and they say a line (`MOM_LINES` / `DAD_LINES`
  in house.gd).
- Charlotte's hamster (`world/hamster.gd`, `Hamster`) lives in the terrarium on her bedroom dresser. The terrarium art is two
  layers, `InteriorArt.terrarium(false)` behind and `terrarium(true)` in front (glass glare, things on the dresser); the
  hamster node shares its position/scale and works in its canvas units. It wanders, grooms, runs its wheel, naps in the
  hideout, and stands up with hearts when clicked; with an empty bowl, a click feeds it (seeds fall in, it runs over and
  eats with stuffed cheeks).
- `ui/wardrobe.gd` (`Wardrobe`, CanvasLayer 60): the dressing window (mirror preview + tabs of clothes, colours, patterns,
  hairstyle and hair colour, hats, accessories; "Au hasard", "Comme d'habitude"). On "C'est parfait !" the house calls `CharacterLook.dress_charlotte()`,
  which keeps the look for every scene and saves it to `user://charlotte_outfit.tres`; `CharacterLook.charlotte()` returns it
  (else `usual()`, the yellow dress). Delete that file after tests that press "C'est parfait !". Picking a clothing colour drops
  Charlotte's exact-colour `overrides` for clothes (`cloth_*`, `accent_*`, `shoe_*`). Design sheets use `CharacterLook.usual()`.
- `characters/`: `Character` (paper-cutout puppet: walk cycle, blink, hair follow-through; `set_look()` rebuilds it), `PlayerControl` (keys and
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

- Anything clickable (a `Node2D`, or a `Control` like `TvScreen`) joins the `interactable` group and implements `can_interact()`, `hit_test(point)`, `approach_x(from_x)`,
  `reserve()`, `release()` and `interact(charlotte)` (see `StrayCat`), and optionally `focus_x()` (where Charlotte should look). `main.gd` walks Charlotte to `approach_x`, then calls `interact`.
- Input is mouse-based with event positions converted to world space, so touch works through emulated mouse events.
- Doors are `DoorSpot.make(rect, action)` interactables. `Transition` fades (`fade_in`, `through_black`, `change_scene`) and
  holds cross-scene state as static vars (`Transition.street_x`: where Charlotte reappears on the street).
- To test click flows, write a temporary `extends SceneTree` script and run it with `-s` (a scene-based test node gets freed
  by `change_scene_to_file`); send clicks with `Input.parse_input_event`, then delete the script.
- Petting: `Character.pet(seconds, low)` lunges (low 1 = deep, for cats/small dogs; 0 = standing, arm out, for big dogs) and
  strokes with the front hand. The animal is drawn just in front of Charlotte so her hand lands on its head: stray cats walk at
  y 646 (she is at 638); a dog being petted steps 32 px toward the camera and gets z_index 1, while its walker `hold()`s.

## Sound

- `audio/sfx.gd` is the `Sfx` autoload: every sound effect is synthesised in code on first use (no audio files, no
  licences): `Sfx.play(name, world_position = Vector2.INF, volume_db, pitch)`; names include steps (`Sfx.step_for(outside)`
  picks wood / street / leaves / snow by season), door, click, tv, fridge, miam, meow, purr, bark, squeak, nibble, page,
  swoosh, pop, chime, goodnight, bird, wind. `Sfx.ambience(scene)` adds birdsong outdoors (not in winter).
- `ui/mute_button.gd` (`MuteButton` autoload): speaker button top-right on every screen, or the M key, mutes the Master bus;
  remembered in `user://settings.cfg`.
- Buses "Effets" (effects) and "Musique". Music is the user's own tracks (made with Suno), never generated in code:
  `audio/music/<name>.mp3|.ogg|.wav`, played by the `Music` autoload (`audio/music.gd`): looping, crossfading.
  `Music.play([names…])` plays the first that exists, else leaves the current track playing. Names: `title` (intro;
  present), `street` / `street_<season>` (streets, `StreetScene._music()`), `maison-charlotte` (her flat; present), `house`
  (other interiors, `Interior._music()`), `depanneur` (present),
  `night` (bedtime). Missing tracks are fine: the previous music carries on.
- `Character.step_sound` (empty for passersby) plays footsteps; scripts run with `--check-only` report "Sfx not found"
  because autoloads aren't loaded there; run the scene instead to check.

## Seasons

- `world/season.gd` (`Season`): `Season.current` (default `"autumn"`, the original Halloween look) and every seasonal
  palette: tree canopies (`tree_palettes`, empty in winter = bare snowy trees), `foliage`, ground `litter` + `litter_amount`,
  `falling_colors`/`falling_texture`/`falling_amount` (leaves, petals, snow), `sky`, `sun`, grade `tint`,
  `dress_for_weather` (passersby), `add_weather` (winter snowfall) and `decor(art)` (facade SVG path).
- Elements read the season when they're built; switching reloads the scene. Seasonal code must keep **the same random draws
  in the same order** in every season (only colours/visibility change), so the street stays the same people and places.
- Facades: the generator writes autumn to `art/decor/*.svg` and the other seasons to `art/decor/<season>/*.svg` (snow on
  ledges, wreaths, Christmas lights in winter; tulips/geraniums instead of pumpkins; ghosts/cobwebs/bats autumn only).
- `ui/debug_menu.gd` is the `DebugMenu` autoload: reads `--season=`, and in debug builds F1 opens a "Saisons" menu that
  switches season while playing (reloads the scene; Charlotte keeps her x via `Transition.street_x` / `Transition.inside_x`).
- Nothing stands behind Mount Royal: the cross-street vista paints open sky over the distant city first. Mount Royal shows
  only when the street runs west (`CrossStreet.facing = "west"`, Montreal compass); other ways end in sky and clouds.

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
