# Charlotte – project context

A small Godot 4.7 2D game (GL Compatibility, 1280×720, `canvas_items` stretch) about Charlotte,
a little girl (nicknamed **Chachoue**: her parents and friends call her that; neighbours and shopkeepers say "Charlotte"), on her street in Montréal (Rosemont): her side of **6e Avenue** between
**Rue Dandurand** (left) and **Rue Holt** (right), in autumn. In-game text is in **French** (Québec).

Current state: a living, side-scrolling street. Charlotte walks with ←/→ or by clicking/tapping the street; double-pressing the arrow or double-clicking/tapping makes her run; ↑ in front of a door (any `DoorSpot` whose area spans her x) goes through it (`PlayerControl._door_ahead`)
(`Character.running`, `RUN_SPEED` × walk speed, eased; `Character.speed()` gives the current speed).
Interactions: click (or tap) a stray cat or a passerby's dog and Charlotte walks over and pets it. Click her front door
(ground floor of `duplex_charlotte`, n° 5672) to go inside her flat. In her bedroom, click the dresser's drawers to open her
wardrobe and change clothes. Click her desk to draw (`ui/drawing_pad.gd`, `DrawingPad`: crayons, sizes, eraser); "Sur le frigo !" saves the
drawing to the game's `user://slots/<n>/drawings/` (newest 4 kept) and sticks it on the kitchen fridge. Delete that folder after tests.
Click the bookshelf in her bedroom to read (`ui/book_reader.gd`, `BookReader`: four short original stories, a
picture and text per page). Click her bed to sleep: night falls, "Bonne nuit, Chachoue…", then "Le lendemain matin…" (no day count shown or kept for now; `Season.day` stays 1).
Click the fridge: it opens (`InteriorArt.fridge_open()`) and she takes a random snack (`InteriorArt.snack(kind)`), "Miam !".
Click the hallway TV to turn it on and change channels, then off. `world/tv_shows.gd` (`TvShows`) is the
catalogue of channels, all original (no copyrighted shows or characters): news, animals, cartoon, hockey, weather, the
sitcom "Les Ratons", cooking, space, music, game show; `TvShows.draw(id, canvas, t, on_for)`. `world/tv_screen.gd`
(`TvScreen`, a `Control`) is one TV for any house: set its `channels` (TvShows ids) to give it its own lineup. Small quests in a notebook (see Quests).

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
  - Logic tests (clicks, quests, scene changes): headless `extends SceneTree` scripts run with `-s`, with their own quit
    timer; send clicks straight to `scene._control._unhandled_input(event)` (headless window size skews `Input.parse_input_event`).
    Windows only for screenshots, and they must quit by themselves.
  - Add `--quit-after 2000` so a run can never hang; after editing SVGs or adding a new `class_name` script, run `Godot --headless --path . --import` first
    (otherwise the new class is "not declared").

## Layout

- Streets extend `world/street_scene.gd` (`StreetScene`): it builds sky, skyline, houses, cross streets, sidewalk, trees,
  lamps, hydrants, racks, passersby, cats, squirrels, Charlotte and the camera from data the street sets in `_init()`
  (`layout`: ordered house SVG names; `cross_streets`; `trees_after`, `lamps_after`, `hydrants_at`, `racks_at`,
  `squirrels_at`; fractional values = position across a building), plus hooks (`_start_x`, `_walk_bounds`,
  `_build_cross_streets`, `_decorate_house`, `_build_landmarks`, `_build_doors`, `_build_sidewalk_props` (against the
  buildings, behind people), `_build_extra_props` (curbside, in front of people)).
- Charlotte's block, every side a `StreetScene` seen from across the road, walking right goes round it clockwise:
  `scenes/main.gd` (6e Avenue, `street_key` "6e": Dandurand left, Holt right), `scenes/holt.gd` (Rue Holt: 6e left, 5e right,
  plex_13–16, 28), `scenes/cinquieme.gd` (5e Avenue: Holt left, Dandurand right, the school across it; plex_17–26 and 29–36 and both lane
  entrances), `scenes/dandurand.gd` (Rue Dandurand: 5e left, dépanneur Xin-Xin's real front `depanneur_front`, 6e right).
  Cross-street `facing` by Montreal's compass: from 6e they run west (Mount Royal), from Dandurand north, from 5e east,
  from Holt south. New corner/side walls in the generator: `holt_nord`, `holt_sud`, `cinq_holt_ouest`, `coin_5e_holt`,
  `coin_5e_dandurand`, `dandurand_sud` (`VARIANTS` is 36: plex_27 on Dandurand, plex_28 on Holt, plex_29–36 on 5e, counted from the Google map).
- The 6e/Holt corner follows `reference/6eme_coin_holt.png`, `holt_coin_6eme.png` and `entree_ruelle_6eme_coin_holt.png`:
  generator kinds `corner_holt` (`coin_holt`: long brown three-storey, stepped white lintels, diamonds, the beige
  corrugated annex with its shingle awning, the red corner window), `ohbon` (dépanneur Oh Bon! on Holt: red storefront,
  checkerboard under the white stairs, canopy with red fascia, light-box sign; "OH BON!" / "DÉPANNEUR" as labels and
  the red "OH / BON!" neon in the big window, a generic "BIÈRE" neon, in `holt.gd`, no logos; `world/neon_sign.gd`,
  `NeonSign`: glowing, flickering window neon) and the Holt-side
  `ruelle` entrance (iron stair, conduits, tags, garage door, one-way sign, the post for the "RALENTISSEZ" sign).
- Vista detail (`CrossStreet`): street trees drawn from two `PropArt.tree` textures (`_tree_tex`, own RNG) in their pits,
  hazier with distance; utility poles and wires down the left curb (`_poles`); sidewalk joints, gutters, a manhole
  (`_street_details`); walls with brick courses, cornice lip, building edges, window lintels/sills/mullions; plex walls
  with doors and steps, iron balconies on the upper floors and the outdoor stair; lanes as a board fence and a tree.
  A building taller than the one before it shows its end wall above that one's roof (`_end_wall`, drawn first, far to
  near, so nearer facades hide the rest); chimneys on near roofs; street lamps down the right curb (`_lamps`); the next
  street down the vista is a "cross" gap (from `_walls_along`) with crosswalks painted across our road.
- Vista walls built from a real street carry that building's own facade texture (`w.tex`, `w.flip` from `_walls_along`)
  laid in perspective in thin strips (`CrossStreet._textured_wall`): its doors, stairs, balconies, bricks, season decor.
  Drawn walls (the corner building's side, the other blocks across) get exposed brick courses and staggered joints
  (`_bricks`). Planted curb extensions on both curbs past the corner and either side of the next crossing
  (`_curb_gardens`).
- Cross-street vistas show the real street that runs there: `StreetScene._walls_along(script, from_gap, direction)`
  reads that street's `layout` (its scene script's `_init`) from our corner to its next cross street, giving each wall
  its building's width, height, kind (`_wall_kind`: ohbon, corner_holt, shop = Xin-Xin, garage, school, gap = lane,
  plex) and brick colour sampled off its facade (`_wall_color`, brick-coloured points only); generic plexes beyond.
  The first wall is the corner building's side, so it takes our own corner facade's height and brick (`ours`). Only the side across the street
  (another block) is still hand-written.
- Before 8 (`StreetScene.CROSS_AGE`, `GameState.age`) Charlotte can't cross a street ("Je n'ai pas le droit de traverser
  toute seule !"), so her world is the block: its four corners and the lane.
- The back lanes, `scenes/ruelle.gd` (extends `StreetScene` but builds its own `_ready`; art in `world/lane_art.gd`,
  `LaneArt`, from `reference/ruelle/`). The block's lanes make an H (map): one script, three scenes by `@export lane`:
  `ruelle_dandurand.tscn` (the green cross lane, 6e → 5e, parallel to Dandurand, seen looking north: 5e left, 6e right),
  `ruelle_holt.tscn` (the cross lane near Holt, seen looking south: 6e left, 5e right) and `ruelle.tscn` ("middle", behind
  the 6e plexes, Holt's end left). A cross lane has the avenues at both ends (`LaneArt.street_end`: click to come out)
  and the middle lane opening half way ("↑ Ruelle", `LaneArt.junction`); the middle lane opens on the two cross lanes at
  its ends. `_plan()` lays out lots and `_openings` ({kind, scene, arrive, label, here}); `Transition.arrive` keys are
  "<street_key>_from_<where>" (street_key "ruelle", "ruelle_dandurand", "ruelle_holt"; streets come in with
  `_add_lane(art)` and go back out to "<street>_from_<art>", `StreetScene._from_lane()`).
  Lots of `LOT_W` 365: backs (siding/brick, wooden galleries, zigzag or spiral stairs, clothesline pulleys) and fronts
  along the lane (board, cedar, picket, chain-link fences, tôle garages, roll-up garages, sheds, planters and bench),
  Virginia creeper by season, bins, poles and wires, clotheslines across the lane (`_Clotheslines`), the black cat, yard
  trees, a croque-livre in each lane (`LaneArt.croque_livre`, `_open_croque_livre`: ready for a quest). Charlotte's
  yard is the middle lane's lot `OWN_LOT` (swing, Dad's bike, chalk hopscotch).
- Turning corners: `StreetScene._add_corner(cross_street, scene, key)` makes the cross street clickable: Charlotte walks to
  the curb, the other street loads with `Transition.arrive = key`, and that street's `_start_x()` checks `_arriving(key)`
  to put her at the matching corner (keys "<street_key>_from_<other>"). All four corners of the block work both ways. A
  corner only works from the sidewalk Charlotte started on, and its click area is the vista above the crosswalk; walking
  into the curb with the arrow keys and pushing on for a moment takes it too (`_push_round_corner`).
- Crossing streets: the sidewalk is split into stretches at each cross street's curbs (`StreetScene._segments`); Charlotte
  walks one stretch at a time. Every crosswalk is clickable (`_add_crossing`, automatic): she goes to the curb on her side,
  says "Je regarde des deux côtés !" and looks both ways, then walks across on her own (`PlayerControl.hands_off`) to the
  other stretch. `CrossStreet.guard = true` (the school's crosswalk on Dandurand) adds a `CrossingGuard`
  (`world/crossing_guard.gd`, neon-yellow coat and cap) who steps out with her ARRÊT paddle while Charlotte crosses.
  `Bubble.say(parent, at, text)` shows a speech bubble anywhere (same speaker = replaces, others stack above); `DoorSpot` takes an optional `approach` and `condition`.
- Real-world rules (from the Google Maps view): back lanes (ruelles) only open onto the north-south avenues like 6e
  Avenue, never onto Dandurand or Holt (no "gap" walls or `ruelle` buildings there). Every intersection has a street-name
  post at both corners (`CrossStreet` SIGNS): the plate of the street we're on faces us, the cross street's plate is
  slanted along that street toward its vanishing point. Overhead wires run pole to pole across the whole view:
  `world/utility_poles.gd` (`UtilityPoles`, one `_draw` node) draws the wooden poles (crossarms, insulators, transformers,
  staples and torn posters) and all wires; `StreetScene._build_utility_poles()` (in `_build_props`) puts them at the curb
  (foot y 662, in front of people, like the lamps; the lane's stand at its fences), every 650-780 px clear of cross streets, trees, lamps, hydrants, racks (own RNG); the lane
  uses them too. Lost-cat posters are stapled to the pole nearest the street's second lamp (`_poster_spot`).
  `layout` runs: `ecole` (école Saint-Jean-de-Brébeuf, across Dandurand), `rue_dandurand`, Charlotte's block (`depanneur`: the
  side of dépanneur Xin-Xin, which fronts Dandurand; `garages`; `ruelle_verte`, the green lane with its sign; … `ruelle`, `coin_holt`),
  `rue_holt`, `coin_holt_est`. The Holt-side lane entrance on 6e has the neighbours' yellow "RALENTISSEZ ! ENFANTS EN
  LIBERTÉ !" sign (`PropArt.slow_sign`, words as labels). The first three buildings of the block are drawn from the photos in `reference/` (the user wants
  every detail as close to the pictures as possible). The cross-street vistas run to the horizon with Mount Royal at the end. Entries in `cross_streets` are gaps (width in px), not SVGs: `CrossStreet`
  (`world/cross_street.gd`) draws them in one-point perspective as three nodes in the draw order: `VISTA` (before the houses:
  receding street, walls along it from `left_walls`/`right_walls`, street trees), `GROUND` (after `Street`: asphalt through the
  sidewalk, curb ramps, crosswalk, yellow in the school zone) and `SIGNS` (with the props: plates, stop/school sign). Charlotte's bounds stop at the curbs (`CrossStreet.road_x`). Passersby already walk across on the crosswalks. `reference/` has photos of the Dandurand corner and `google_map_immediate_area.png`.
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
  hair, brown eyes, teal floral dress, tights, boots) in the kitchen, `CharacterLook.dad()` (short brown hair, no cap,
  clean-shaven, blue eyes, navy T-shirt with the "bike" top pattern) in the salon; both stand at 1.18× Charlotte's scale. Click them and they say a line (`MOM_LINES` / `DAD_LINES`
  in house.gd).
- Charlotte's hamster (`world/hamster.gd`, `Hamster`) lives in the terrarium on her bedroom dresser. The terrarium art is two
  layers, `InteriorArt.terrarium(false)` behind and `terrarium(true)` in front (glass glare, things on the dresser); the
  hamster node shares its position/scale and works in its canvas units. It wanders, grooms, runs its wheel, naps in the
  hideout, and stands up with hearts when clicked; with an empty bowl, a click feeds it (seeds fall in, it runs over and
  eats with stuffed cheeks).
- `ui/wardrobe.gd` (`Wardrobe`, CanvasLayer 60): the dressing window (mirror preview + tabs of clothes, colours, patterns,
  hairstyle and hair colour, hats, accessories; "Au hasard", "Comme d'habitude"). On "C'est parfait !" the house calls `CharacterLook.dress_charlotte()`,
  which keeps the look for every scene and saves it in the game's slot folder; `CharacterLook.charlotte()` returns it
  (else `usual()`, the yellow dress). Delete that file after tests that press "C'est parfait !". Picking a clothing colour drops
  Charlotte's exact-colour `overrides` for clothes (`cloth_*`, `accent_*`, `shoe_*`). Design sheets use `CharacterLook.usual()`.
- Outdoors in winter Charlotte wears a copy of her look dressed by `Season.dress_for_weather` (coat, boots, tuque, scarf):
  `StreetScene._spawn_charlotte` and the title screen; her saved outfit is unchanged.
- `characters/`: `Character` (paper-cutout puppet: walk cycle, blink, hair follow-through, breathing, soft shading by
  `shaders/character_shade.gdshader` (lit from the left, follows `facing`), hair strands clipped to each hairstyle (`CharacterArt._strands`), clothing folds
  (dress gathers and hem, top creases, elbow and knee creases), idle gestures when `fidgets` (wave, hop,
  stretch, look round: Charlotte and her parents); `set_look()` rebuilds it), `PlayerControl` (keys and
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
- Cyclists ride by in the traffic lane now and then (`world/cyclist.gd`, `Cyclist.random`: the bike is drawn, the rider is
  a `Character` with `riding = true`: each leg split at the knee (`_pedal_legs`, two-bone IK, foot on the turning pedal); `StreetScene._spawn_cyclists`,
  `_traffic`, own RNG, rarer in winter, sometimes ringing).
- Background life: `WireBirds` (`world/wire_birds.gd`: pigeons and sparrows on the poles' cable, fly off when
  Charlotte comes close or runs, others land later; streets and lanes), children playing in the lanes (not on the
  streets): a `JumpRopeKid` (`world/jump_rope_kid.gd`, `StreetScene._build_kid`) and a `BallKid` (`world/ball_kid.gd`) in
  each lane, own RNG, clickable; few passersby on the streets (`passerby_ages`: 2 on the avenues, 1 on Dandurand/Holt), winter chimney smoke (`_build_life`).
- Every corner has planted curb extensions (`world/curb_garden.gd`, `CurbGarden`, `StreetScene._build_curb_gardens`, from
  `reference/terre_plein_01/02.png`): the curb bulges into the parking lane on both sides of each cross street, perennials
  by season, striped flexible bollards; drawn in front of people.
- Street trees come in sizes (`StreetScene.TREE_SIZES` 0.38–0.72, `_tree_scales`, own RNG; lane yard trees 0.45–0.78).
  Squirrels work from each sprite's position, scale and texture alpha, so any size is climbable.
- Street trees stand in a `TreePit` (`world/tree_pit.gd`, added in `StreetScene._build_trees`): grass, a neighbour's
  garden of perennials (seasonal tulips/mums), or mulch; granite edging, sometimes iron hoops; snow in winter.
- Depth of field: `world/depth_blur.gd` (`DepthBlur`, `shaders/depth_blur.gdshader`): `DepthBlur.far(self)` right after
  the skyline (before the houses) softens the distant roofs and steeples; `DepthBlur.vista(self, cs)` after each cross
  street's VISTA blurs round its vanishing point (a BackBufferCopy refreshes the screen copy first). Streets and lanes.
- `shaders/`: `grade.gdshader` (full-screen colour grade on CanvasLayer 50), `sway.gdshader` (tree sway).
- `art/decor/windows.json`: window panes per house, written by the generator, read by `WindowCats`. It is not a resource:
  an export preset needs `*.json` in its include filter.
- Street doors and stairs follow `reference/portes.jpg` and `reference/escaliers.jpg`: generator `DOOR_STYLES` (double,
  panel, oval, leaded stained glass, diamond, 1950s slots, slit, planks, slats, fan_top, grid, sunburst, porthole, grille,
  horizontal, arched_panels, double_leaded), optional stained-glass `sidelights`, and `door_surround` (lintel, cornice on brackets, pediment,
  arch with fanlight), door lights by `lamp_style` (lantern, globe, coach, cylinder, box, a single one hung over the
  door, or one on the left; `_door_lamps`), `ornate` stair railings (spades, scrolled newel), `stair_kind` "landing" (L with a landing on
  posts) or "curve"; drawn last in `_variant` so other draws don't move. Spiral staircases only in the lane
  (`LaneArt._spiral`), never on the street side.
- Lane entrances seen from the street (generator `_ruelle_verte`, `_ruelle`) use `_fine_tree` (trunk, limbs split three
  times, hundreds of small leaves in this season's colours, bare and snowy in winter) instead of round blobs; the Holt-side
  entrance is drawn in perspective (fences, tôle garage, creeper, clothesline, weeds, bin, bunting).
- `art/decor/*.svg`: house façades, **generated**. Edit `tools/generate_houses.gd` and regenerate instead of hand-editing:
  `Godot --headless --path . --script res://tools/generate_houses.gd`
- `art/logo.png` is cut out of `art/logo.jpg` by `tools/cutout_logo.gd` (same headless invocation).
- `reference/` holds real-world reference photos (Charlotte, her house, the neighbours, the Google Maps view). It is gitignored.

## Interactions and scene changes

- Anything clickable (a `Node2D`, or a `Control` like `TvScreen`) joins the `interactable` group and implements `can_interact()`, `hit_test(point)`, `approach_x(from_x)`,
  `reserve()`, `release()` and `interact(charlotte)` (see `StrayCat`), and optionally `focus_x()` (where Charlotte should look). `main.gd` walks Charlotte to `approach_x`, then calls `interact`.
- Input is mouse-based with event positions converted to world space, so touch works through emulated mouse events.
- Doors are `DoorSpot.make(rect, action)` interactables. `Transition` fades (`fade_in`, `through_black`, `change_scene`; the
  scene-change black lives on the tree root, group "scene_change_black", until the new scene's `fade_in`, so every scene
  calls `Transition.fade_in(self)`; the clear colour is the same dark brown) and
  holds cross-scene state as static vars (`Transition.street_x`: where Charlotte reappears on the street).
- To test click flows, write a temporary `extends SceneTree` script and run it with `-s` (a scene-based test node gets freed
  by `change_scene_to_file`); send clicks with `Input.parse_input_event`, then delete the script.
- Petting: `Character.pet(seconds, low)` lunges (low 1 = deep, for cats/small dogs; 0 = standing, arm out, for big dogs) and
  strokes with the front hand. The animal is drawn just in front of Charlotte so her hand lands on its head: stray cats walk at
  y 646 (she is at 638); a dog being petted steps 32 px toward the camera and gets z_index 1, while its walker `hold()`s.

## Quests and growing up

- Vision (Julien): Charlotte starts at 7 (`GameState.age`, saved). As she completes quests and makes friends she grows up,
  may go farther in the neighbourhood and gets more advanced quests. A year is slow: all four seasons must pass and dozens
  of quests be done (the ageing rule isn't implemented yet). Gate new quests and places by age.
- `world/quests.gd` (`Quests`): the catalogue (`ORDER`, `ALL`: `title`, `hint` = where to go, `find` = clue shown before it
  starts, `age`, optional `after` = quest it waits for, `reward` in $). Several quests can be on at once. State in
  `GameState.quests` (absent / "active" / "done"); `available`, `start`, `complete` (adds the reward), `stars`, `money_text`.
- `ui/notebook.gd` is the `Notebook` autoload (CanvasLayer 75): button left of the mute button (N key), "Mon carnet" with
  En cours (+ hint), Réussies (yellow stars), À découvrir (clues); age and pocket money; crayon doodles, ribbon bookmark, elastic,
  washi tape on the page; pauses the game while open. Hidden
  on the title and `tools/` scenes. `Notebook.announce()` (called by `Quests`) pops "Nouvelle quête" / "Quête réussie !".
- `QuestMark.make(at, condition, scale)` (`world/quest_mark.gd`): a bobbing yellow "!" over a quest giver, or over where
  to go next, while `condition` is true.
- The quests so far:
  - milk: Mom gives it, buy the 4 L bag at the dépanneur (free, `flags.has_milk`), bring it to Mom;
  - hamster: Dad gives it; feeding sets `flags.hamster_fed` (cleared at bedtime); going to bed unfed is refused, fed completes it;
  - lost cats, `world/lost_cats.gd` (`LostCats.ALL`, ids = quest ids cat, cat2, cat3, chained by `after`): Pistache
    (found on Dandurand, home 5684 6e Av.), Caramel (in the lane, home 5679 5e Av.), Bijou (in the lane, home 2655 rue
    Holt). `StreetScene._build_lost_cats()` (streets and the lane): the "PERDU" `LostCats.Poster` on the street's pole (taken down once the cat is found, `poster_up`)
    starts it; the collared cat waits at `found_at` (`_found_x`; lane = lot index); petting it, Charlotte picks it up
    (`GameState.flags.carrying`, `Character.carry(node)` / `is_holding()`, `LostCats.held(id)`, kept across scenes and
    indoors); at the owner's front door (`_door_x(art)` from `art/decor/doors.json`, written by the generator; "!" and
    house number) the owner comes out (`_bring_home`), the cat is put down, quest done. Owners are always at a front
    door on a street, never in the lane.
  - menage (Mom gives it, after the milk; the toys can't be picked up before): 11 things on the bedroom floor (`MESS`,
    `InteriorArt.mess`); clicking each, Charlotte crouches and it flies to its place (`PUT_AWAY`); `flags.tidied`.
  - plants (Dad gives it): five thirsty plants (`_plant(id, kind, …)`, `InteriorArt.house_plant(kind, thirsty)`:
    monstera and a hanging pothos in the salon, a fern on its stand and a fiddle-leaf fig in the corridor, a peace lily
    in the bedroom; thirsty = drooping, yellowed, brown tips, dry soil, dead leaves; the sprite swaps to the healthy
    picture when watered) and the watering can in the kitchen (`InteriorArt.watering_can`, carried with
    `Character.carry`, `flags.has_can`); `flags.watered`; the can goes back when all have drunk.
- The dépanneur has prices (`_buy(picture, text, price)`, paid from `GameState.money`); the clerk says "Il te manque des
  sous !" when she can't afford something.

## Saving

- `world/game_state.gd` (`GameState`): the game in progress (pocket `money`, `quests`, story `flags`, plus `Season.day` /
  `Season.current`). Several games side by side: `GameState.SLOTS` (3) slots, `GameState.slot` the current one; each
  keeps `save.json` (scene path + Charlotte's x), her outfit (`CharacterLook.outfit_path()`) and her fridge drawings
  (`DrawingPad.folder()`) in `user://slots/<n>/` (`slot_dir()`); the last one played is in `user://settings.cfg`
  [game] last_slot. `migrate()` moves an old single `user://save.json` into slot 1. `world/saver.gd` (`Saver`), added by
  `StreetScene` and `Interior`, autosaves 1 s after a scene opens, every 10 s, on leaving it and on window close.
- Title screen: "Continuer" (`GameState.load_game(last_slot())`) and "Mes parties" (a card per slot: season, age, stars,
  money, "Jouer" / "Effacer" with a confirmation, or "Nouvelle partie" in a free slot, `GameState.new_game(n)`); with no
  save at all, just "Nouvelle partie" (slot 1).
- `GameState.enabled()` is false for test runs (`--screenshot=`, `--x=`, `-s` scripts), so they never write or wipe the save.
  A plain scene run (no such args) does save: back up `user://` first if you must test that way.

## Sound

- `audio/sfx.gd` is the `Sfx` autoload: every sound effect is synthesised in code on first use (no audio files, no
  licences): `Sfx.play(name, world_position = Vector2.INF, volume_db, pitch)`; names include steps (`Sfx.step_for(outside)`
  picks wood / street / leaves / snow by season), door, click, tv, fridge, miam, meow, purr, bark, squeak, nibble, page,
  swoosh, pop, chime, goodnight, bird, wind. `Sfx.ambience(scene)` adds birdsong outdoors (not in winter).
- `ui/cute_art.gd` (`CuteArt`): little drawings on any CanvasItem (cat, dog, hamster heads, flower, heart, star, sun,
  house, Charlotte's self-portrait), clean or `crayon` (hatched fill clipped to the shape, wobbly double outline). The
  notebook's doodles use the crayon style, the menu card the clean one.
- `ui/game_menu.gd` (`GameMenu` autoload, CanvasLayer 78): ☰ button top-left or Escape (unless the notebook is open)
  pauses and opens Reprendre / Options (Musique and Effets sonores volume sliders on those buses, Plein écran) /
  Écran titre / Quitter le jeu (both save through the scene's `Saver` first). Options in `user://settings.cfg` [options].
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
  switches season while playing (reloads the scene; Charlotte keeps her x via `Transition.street_x` / `Transition.inside_x`),
  and lists every quest with "Effacer" (not started, its flags in `QUEST_FLAGS` cleared) / "Activer" / "Tout effacer" to test them again.
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
- Font: Fredoka (rounded, SIL OFL, `ui/fonts/Fredoka.ttf` + `OFL.txt`), weight 520 via `ui/fonts/fredoka.tres`, set as
  the project's `gui/theme/custom_font` (so Controls and `ThemeDB.fallback_font` draw_string() use it).
- Palette: warm autumn street; UI blue `#1D4F91`, yellow `#FFD23F`, cream `#E8DDD0`.
- GDScript style: static typing, `:=`, tabs, short section-banner comments.
- Light comes from the low sun on the upper left: highlights on the left, shadows thrown to the right.
- In the shell, `rm` is aliased to `rm -i` (it hangs waiting for input); use `/bin/rm -f`.

## Repo

- The git repo root is the parent folder `jeux/`. It also contains `bebe-scutigere/`, a separate web game.
- The repo uses `~/.ssh/githubkey` via the repo-local `core.sshCommand`. The remote is `git@github-personal:jullmg/jeux.git`.
