# Charlotte – project context

A small Godot 4.7 2D game (GL Compatibility, 1280×720, `canvas_items` stretch) about Charlotte,
a little girl (nicknamed **Chachoue**: her parents and friends call her that; neighbours and shopkeepers say "Charlotte"), on her street in Montréal (Rosemont): her side of **6e Avenue** between
**Rue Dandurand** (left) and **Rue Holt** (right), in autumn. In-game text is in **French** (Québec).

Current state: a living, side-scrolling street. Charlotte walks with ←/→ or A/D (W = ↑, added to the `ui_*` actions by `PlayerControl`) or by clicking/tapping the street; double-pressing the arrow or double-clicking/tapping makes her run; ↑ in front of a door (any `DoorSpot` whose area, or `up_rect`, spans her x) goes through it (`PlayerControl._door_ahead`)
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
- Screenshots (use them to check visual changes). Julien's main display is an HDMI monitor: add `--screen 1` (engine arg, before `--`) so the window opens on the MacBook's built-in screen and doesn't interrupt their work:
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
- The 6e/Holt corner follows `reference/coin_holt/6eme_coin_holt.png`, `reference/coin_holt/holt_coin_6eme.png` and `reference/ruelle/entree_ruelle_6eme_coin_holt.png`:
  generator kinds `corner_holt` (`coin_holt`: long brown three-storey, stepped white lintels, diamonds, the beige
  corrugated annex with its shingle awning, the red corner window), `ohbon` (dépanneur Oh Bon! on Holt: red storefront,
  checkerboard under the white stairs, canopy with red fascia, light-box sign; "OH BON!" / "DÉPANNEUR" as labels and
  the red "OH / BON!" neon in the big window, a generic "BIÈRE" neon, in `holt.gd`, no real logos on it yet; `world/neon_sign.gd`,
  `NeonSign`: glowing, flickering window neon) and the Holt-side
  `ruelle` entrance (iron stair, conduits, tags, garage door, one-way sign, the post for the "RALENTISSEZ" sign).
- Vista detail (`CrossStreet`): street trees drawn from two `PropArt.tree` textures (`_tree_tex`, own RNG) in their pits at the curb (`TREES_LEFT`/`TREES_RIGHT`, between the poles and lamps, `TREE_FROM_CURB`; never mid-sidewalk),
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
  the 6e plexes, Holt's end left). A cross lane has the avenues at both ends (`_build_avenues`, see below: click the vista to come out)
  and the middle lane opening half way ("↑ Ruelle", `LaneArt.junction`); the middle lane ends on the two cross lanes in a T (`LaneArt.tee`, see below). `_plan()` lays out lots and `_openings` ({kind, scene, arrive, label, here}); `Transition.arrive` keys are
  "<street_key>_from_<where>" (street_key "ruelle", "ruelle_dandurand", "ruelle_holt"; streets come in with
  `_add_lane(art)` and go back out to "<street>_from_<art>", `StreetScene._from_lane()`).
  Lots of `LOT_W` 365: backs (siding/brick, wooden galleries, zigzag or spiral stairs, clothesline pulleys) and fronts
  along the lane (board, cedar, picket, chain-link fences, tôle garages, roll-up garages, sheds, planters and bench),
  Virginia creeper by season, poles and wires (no recycling or compost bins, Julien took them out), clotheslines across the lane (`_Clotheslines`), the black cat, yard
  trees, a croque-livre in each lane (`LaneArt.croque_livre`, `_open_croque_livre`: ready for a quest). Charlotte's
  yard is the middle lane's lot `OWN_LOT` (swing, Dad's bike, chalk hopscotch).
- Turning corners: `StreetScene._add_corner(cross_street, scene, key)` makes the cross street clickable: Charlotte walks to
  the curb, the other street loads with `Transition.arrive = key`, and that street's `_start_x()` checks `_arriving(key)`
  to put her at the matching corner (keys "<street_key>_from_<other>"). All four corners of the block work both ways. A
  corner only works from the sidewalk Charlotte started on, and its click area is the vista above the crosswalk; the arrow keys
  never turn it (walking into the curb does nothing): ↑ at the curb does, through `DoorSpot.up_rect` read by `PlayerControl._door_ahead`.
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
    data (`rooms`, `chair_rails`, `posts`, `casings`, `gleams` = x of lights mirrored on the floor). Per-room wallpaper
    options: `pattern` ("stars", "dots", "stripes", "diamonds"), `pattern_color`, `pattern_alpha`, `wainscot` (Color) +
    `wainscot_height` (panelled lower wall); shops use `tile_colors`.
  - `world/interior_art.gd` (`InteriorArt`): one SVG function per piece of furniture; `world/fairy_lights.gd` (`FairyLights`).
    Decor pieces for any bedroom/house: `moon_decal`, `mobile` (sways, tweened in the scene), `wall_clock`, `house_plant`; kitchen/entrance: `wall_calendar`, `kitchen_toppers` (things on the fridge and cabinet), `kitchen_curtain`, `kitchen_mat`, `umbrella_stand`. SVG `<pattern>` does not render in these textures: draw checks/stripes as plain shapes.
- `scenes/house.gd` (extends `Interior`): Charlotte's flat, from the photos in `reference/maison_charlotte/interieur`:
  vestibule (0–640) → oak glass doorway → salon (–2260) → hallway → kitchen (3400–3960); Charlotte's bedroom is a separate
  area (5000–6650) reached through the "chacha" door (fade, camera limits switch). Charlotte is at scale 0.5 inside.
- `scenes/depanneur.gd` (extends `Interior`): inside dépanneur Xin-Xin, entered from its door on Rue Dandurand (bell). A
  crammed corner store: cash machine, newspapers, counter (till, scratch tickets) with the shopkeeper (an Asian man: short
  black hair, warm light skin, dark eyes; on a raised floor behind the counter) and a wall of shelves behind her, a real-time
  clock, a specials board, the candy wall, low gondolas mid-floor, bread rack, coffee/hot chocolate corner, the sloche
  machine (animated swirls; Québec word "sloche", not "barbotine"), freezer, drinks fridges, dairy cooler with 4 L milk
  bags, stockroom door, security mirror. Furniture from `world/shop_art.gd` (`ShopArt`): drawn artwork with the **real
  logos** stamped on it (`ShopArt._stamped`, files in `art/brands/`: Québon on the milk cartons, Ruffles and Lay's on the
  chip bags, Loto-Québec on the poster, Slush Puppie on the machine). Checkered floor
  and suspended ceiling (`RoomShell.floor_style = "tiles"`, `ceiling_style = "drop"`); blurred "shelf" foreground. Click
  the shopkeeper to say hello; candy, sloche, coffee corner, freezer, fridges or dairy to buy something.
  `Interior._say(who, text)` (speech bubble) and `Interior._treat(picture, text)` (what Charlotte gets) are reusable.
  Its art (`ShopArt`) is built from product helpers (`_can`, `_bottle`, `_bag`, `_box`, `_jar`, `_carton`, `_tag`, `_lip`) and
  shared gradients (`_defs()`: cylinders, brushed metal, glass, laminate), light from the upper left. Chips: `ShopArt.CHIPS`
  (the six classic flavours: crème sure et oignons, ketchup, barbecue, nature, sel et vinaigre, fromage) on a gondola
  (`chips_gondola`, flavour names as labels in the header; click it to buy a random bag, 1,75 $). Also: a red frieze under the
  ceiling, stock on high shelves, hanging aisle signs, exit sign, extinguisher, bulletin board (with the lost-cat poster),
  security cameras (blinking light), baskets, wet-floor sign, floor wear, recessed ceiling panels (one flickers) with light
  cones and pools on the floor, cold glow before the fridges, daylight through the door, the neon OUVERT (`NeonSign`) and a
  lucky cat on the counter that waves only when clicked (`_LuckyCat.wave()`); the blurred foreground is a red shopping basket (`"basket"`).
- `world/shop.gd` (`Shop`, extends `Interior`): what the corner stores share (the clerk, `_wall_label`, `_hang` aisle signs, `_buy`,
  `_buy_chips`, `_buy_milk`, `_thanks`, the clock, a blinking camera light, a stuttering panel). `scenes/depanneur.gd` (Xin-Xin) and
  `scenes/ohbon.gd` extend it.
- `scenes/ohbon.gd` (dépanneur **Oh Bon!**, rue Holt: its black glass door on the 6e corner, `holt.gd` `_build_doors`): the opposite
  of Xin-Xin, bright and tidy. White walls with a red-and-white checkerboard frieze, a pale floor (`RoomShell.tile_colors`),
  everything in straight rows with room to walk (`ShopArt.modern_counter`, `tidy_back_shelves`, candy wall, chips gondola,
  fridges, dairy, coffee, a fruit stand, flowers, a card rack, a gumball machine, a water cooler). A BIG TV mounted high above
  the counter plays the shows by itself (`TvScreen.auto_cycle`, `turn_on`; click it for the next channel). Shopkeeper: a bald,
  slightly heavy man with Cambodian features (`look.build`, `eyes = "almond"`). Xin-Xin is made crowded on purpose
  (`_build_clutter`: boxes on top of the fridges, a pallet, a hand truck, a ladder, a cart, a mop, a full bin, crooked price cards; the floor
  is kept clear of small items; the crowding also shows in a long row of blurred foreground shelves, `Interior._build_foreground` kind
  "shelves" [x, "shelves", seed], one every ~340 px) so the two feel different.
- Shop walls get advertising posters, never house picture frames: `ShopArt.ad_poster(kind)` (`AD_POSTERS`: coffee, ice cream, slush, hot dogs, cold drinks), hung with `Shop._ad(kind, x, bottom, scale)` (title label over the strip).
- `tools/shop_objects.tscn` is the catalogue of every `ShopArt` object, twelve to a page, to judge their drawing: `Godot --path . --screen 1 res://tools/shop_objects.tscn -- --screenshot=/path/p.png --page=0` (pages 0–5; wait for `RenderingServer.frame_post_draw` before capturing in a tool scene, or the shot comes out transparent).
- More shop objects in `ShopArt` (shopping cart, old cash register, spinner rack, produce crates, flower buckets, gumball machine,
  box stacks, pallet of cases, hand truck, mop and bucket, broom, step ladder, A-frame sign, open sign, bin, newspapers, vending
  machine, egg tray, water cooler, toy rack, salt bag, tin pyramid, CCTV monitor, `floor_junk`): pick from these
  when a new shop or street scene needs props.
- The parents go about chores: `world/family_routine.gd` (`FamilyRoutine`) walks one character between tasks
  (`MOM_TASKS` / `DAD_TASKS` in house.gd: dicts {x, facing, task, prop, secs, say}); `Character.task` poses ("stir", "read", "phone",
  "type", "wash", "drink", "fridge", "exercise", "watch", set in `_task_pose()`), props are drawn by `FamilyRoutine._Prop`; their click
  spot and "!" mark follow them, and `pause(secs, toward_x)` stops them when Charlotte talks to them. Shops have walking customers
  (`world/shop_customer.gd`, `ShopCustomer`, `Shop._add_customers`).
- Charlotte's parents, from `reference/personnages/mere_charlotte.jpg` / `pere_charlotte.jpg`: `CharacterLook.mom()` (long wavy light-brown
  hair, brown eyes, teal floral dress, tights, boots) in the kitchen, `CharacterLook.dad()` (short brown hair, no cap,
  clean-shaven, blue eyes, navy T-shirt with the "bike" top pattern) in the salon; both stand at 1.18× Charlotte's scale. Click them and they say a line (`MOM_LINES` / `DAD_LINES`
  in house.gd).
- By her bedroom door, her height in pencil straight on the wall (`world/growth_marks.gd`, `GrowthMarks`): a line and "N ans" from 3 up to `GameState.age`.
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
- Arms have an elbow and hands with fingers: each arm is three sprites, upper arm (shoulder pivot; `_arm_front`/`_arm_back`, whose
  `rotation` is the shoulder angle), forearm (child, `rotation = -elbow flex`) and hand (child of the forearm, one of four pictures
  `relaxed` / `open` / `flat` / `grip`, chosen by `_hand_goal`). `CharacterArt._upper_arm_svg/_forearm_svg/_hand_svg` draw them (long sleeves
  carry on over the elbow; hand size by age, `HAND_SCALE`); the rig has `upper_len`, `fore_len`, `hand_center`, `arm_len` (shoulder to the middle of
  the palm, as before: `hand_position()` is that point). Poses set shoulder angles and elbow goals in `Character._apply_pose`: `_arms_rest` (swing),
  `_ik`/`_reach_blend` (two-bone reach: carrying, pouring, handlebars), `_aim(i, old_degrees, reach)` (chores: a hand where a straight arm at that angle
  would put it, the elbow slightly bent), `_finish_arms` (eases the elbow, picks the hand). Carried things may set meta `hands` (the hand shape; a cat:
  "open") and `keep_upright` (not mirrored); `hand_mode` forces the front hand's shape (a dog walker's "grip"). Riding: each shoulder slides forward along the chest (and the arm stretches a little if needed) so both hands land on the grip. Design sheet: `tools/arms.tscn`
  (`--set=0..3`, `--only=N`, `--zoom=`: standing/walking/running, gestures/pet/carry, chores, ages and sleeves).
- Legs have knees: each leg is a thigh (hip pivot; `_leg_front`/`_leg_back`, `rotation` = hip angle) and a shin with its shoe (child at the knee,
  `_shin_front`/`_shin_back`, `rotation` = knee flex, the lower leg folding back). `CharacterArt._leg_body` draws the whole leg once and
  `_thigh_svg` / `_shin_svg` cut it at `rig.knee_y` (half the leg); the shin has a round cap with a knee crease so the bend stays clean (boots
  start below the knee). `Character._knees` bends the swinging leg when walking (more when running), `_stance_drop` lowers the hips so the
  lower foot stays on the ground; a lunge (petting) keeps both legs straight and symmetrical so both feet stay down; hop and exercise tuck the
  knees; on a bike `_pedal_legs` solves thigh and shin to the pedal (IK).
- Clothes carry light and detail: `CharacterArt.CLOTH_DEFS` (a sheen from the upper left, shade toward the hem; `_sheen(path)` lays it over any garment
  outline: `TOP_BODY`, `DRESS_SKIRT`, `DRESS_BODICE`, `COAT_BODY`), `LEG_DEFS` (light across a leg). Tops have a slight waist and a curved hem;
  T-shirts a ribbed collar and a stitched hem; sweaters and hoodies knitted ribbing, a rolled neck and (hoodie) a stitched kangaroo pocket; dresses
  darts, panel seams and piping along the hem; coats pockets with flaps, belt and buckle, epaulettes, two buttons rows and a sewn hem; overalls a
  bib pocket, denim texture and stitching; trousers a stitched cuff and an outer seam; socks a ribbed cuff with a stripe; shoes laces and eyelets,
  a buckled strap, a tread on the sole; caps seams, tuques a sheen, scarves knitted rows. Charlotte's own `overrides` (exact colours) still win over
  the derived palette, so her usual dress keeps its colours (a design sheet that changes `outfit_color` must clear `look.overrides`).
- Faces have expressions: the head picture is only the bare face (skin, ears, blush, nose, beard); the eyes, brows, mouth and glasses are layers of their
  own (`CharacterArt.face_texture(layer, kind)`, made when first wanted from `FACE_CROPS`; kinds `EYE_KINDS` / `BROW_KINDS` / `MOUTH_KINDS`, round or
  almond eyes, lashes, beard and moustache handled) between the head and the hair. `Character.EXPRESSIONS` maps a name (normal, happy, grin, yum, laugh,
  focus, effort, surprised, wonder, sad, worry, sleep, yawn, talk, sip) to [eyes, brows, mouth]. `_auto_expression()` chooses from what she is
  doing (running: grin, petting or waving: happy, stretching: yawn, pouring: focus, holding a cat: happy via meta `face`, chores by `TASK_FACES`),
  `expression` forces one, `express(name, seconds)` shows one for a moment. `Bubble.say` makes whoever stands under the bubble "talk" (mouth
  cycling `talk_a/b/c`), `Interior._treat` gives "yum", the house tidy quest "worry" / "laugh", a petted dog's owner "happy". Closed or smiling eyes
  suppress the blink. `tools/arms.tscn --set=5` and `--set=6` show every expression.
- Eye colours must read at game size: the iris is a dark rim (`iris_dark`) round the flat colour (`iris`), lighter low down (`iris_light`), with a small pupil. `CharacterLook.EYES` (hazel, blue, green, two browns) for passersby; keep its size so the random draws don't move. Dad is bright blue, the twins a paler grey-blue, Mom and Charlotte brown.
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
  `squirrel.trees` shares the scene's `_tree_sprites` array, filled later). Squirrels also climb the utility poles now and then (`squirrel.poles` shares the scene's `_pole_xs`, filled later; states `to_pole`, `pole_up`, `wire`, `wire_sit`, `pole_down`): they step onto the thick cable (`UtilityPoles.CABLE_Y`, sag `WireBirds.SAG`), walk and sit along the spans, go on to the next pole or back down, and are drawn above the poles (z_index 1) while up there, `CritterDraw` (shared static drawing helpers for the
  animals: shaded outlined bodies, tapered limbs/tails built from convex quads, glossy eyes, hearts).
  `PropArt` generates trees, lamp posts, hydrants, bikes, leaves as textures. `PropArt.car()`/`wheel()` still exist but
  cars were removed from both scenes on purpose (2026-10-31); see git history to bring them back.
- Cyclists ride by in the traffic lane now and then (`world/cyclist.gd`, `Cyclist.random`: the bike is drawn, the rider is
  a `Character` with `riding = true`: each leg split at the knee (`_pedal_legs`, two-bone IK, foot on the turning pedal); `StreetScene._spawn_cyclists`,
  `_traffic`, own RNG, rarer in winter, sometimes ringing).
- Squirrels in the lanes (`ruelle.gd` `_build_lane_squirrels`, `SQUIRRELS_MIDDLE` 6, `SQUIRRELS_CROSS` 2, own RNG): along the foot of the fences (`SQUIRREL_Y`), up the poles and the yard trees. They are drawn over the lane's ground, in front of the trees, so `Squirrel.slips_behind` moves one just behind the tree it climbs (`_home_index`) and back when it lands.
- Background life: `WireBirds` (`world/wire_birds.gd`: pigeons and sparrows on the poles' cable, fly off when
  Charlotte comes close or runs, others land later; streets and lanes), children playing in the lanes (not on the
  streets): a `JumpRopeKid` (`world/jump_rope_kid.gd`, `StreetScene._build_kid`) and a `BallKid` (`world/ball_kid.gd`) in
  each lane, own RNG, clickable; few passersby on the streets (`passerby_ages`: 2 on the avenues, 1 on Dandurand/Holt), winter chimney smoke (`_build_life`).
- Every corner has planted curb extensions (`world/curb_garden.gd`, `CurbGarden`, `StreetScene._build_curb_gardens`, from
  `reference/rue/terre_plein_01.png et 02`): the curb bulges into the parking lane on both sides of each cross street, perennials
  by season, striped flexible bollards; drawn in front of people.
- Tree limbs (`PropArt.tree`, `LIMB_TIPS`): the trunk outline's two limb ends are flat cuts that random foliage may not hide, so both limbs go on as thinner rounded branches with a fork (also in winter, before `_bare_crown`), and in leaf seasons a small tuft (own RNG, seed 5, so the tree's draws don't change) sits at each tip. Never end a branch in a flat cut.
- Seniors lean forward only 1.5° (`rig.lean`); 5° made the head hang well ahead of the feet.
- Garbage bag with a squirrel (`world/trash_bag.gd`, `TrashBag`; `StreetScene._build_trash_bag`, about one street visit in three, global random numbers, clear of cross streets/trees/lamps/hydrants/racks and Charlotte's start): a black bag with a knot; its own `Squirrel` (`bag` set) sits beside it in state "gnaw" (`_draw_gnaw`), the hole (`TrashBag.hole` 0..1, ~20 s) grows and scraps spill out (chip bag, crust, apple core, crumbs). Charlotte inside `SCARE` (or `SCARE_RUNNING`) makes it flee as usual; the torn bag stays, and once she is far off (`_bag_is_quiet`) the squirrel may come back (`to_bag`) and carry on.
- Charlotte's mouth is always the closed smile (`CharacterLook.usual()` and `charlotte()` force `mouth = "smile"`, also for old saved outfits); other characters keep a random smile or open smile.
- Tree shadows (`_build_tree_shadows`): the canopy's copy is sheared (`TREE_SHADOW_LEAN`) about the trunk's foot, so the shadow starts at the foot of the tree and leans right up the wall; it is no longer an offset copy floating beside it.
- Nothing overlaps on the sidewalk (`StreetScene._separate_props`, run after the tree sizes are known): lamps (`_lamp_x`, also clear of canopies), hydrants and bike racks (their fractional `hydrants_at` / `racks_at` are moved to the nearest free spot) keep clear of cross streets, tree pits (`TRUNK_CLEAR`) and each other; the utility poles keep clear of whole canopies, lamps, hydrants, racks and the bag (`_bag_range`); the bag clears all of them. Anything new on the sidewalk must be added to these footprints.
- Where the middle lane ends on a cross lane (Julien's logic: a true T; `LaneArt.tee`, `ruelle.gd` `_build_tee`, `TEE_END`, `TEE_HALF`): there is no lot past the opening. We look toward 6e, the cross lane comes past us and runs on, one-point perspective, a short way to the avenue close by (its sidewalks, road and plexes). Across the avenue the plexes leave the next block's lane entrance, and `LaneArt._lanes_beyond` draws the lanes carrying on in line, avenue after avenue, to the vanishing point (Julien's logic, from the map; own RNG). On the middle lane's side: its first lot's plex, whose side wall starts at that lot's back (`back(rng, w, own, brick)`, roof height from its third result) over the yard fence, in the real plex's brick (`_walls_along`). On the far side: the real corner building, then the yards of the buildings behind seen along their backs, and a board fence going off past the camera at the left of the view. Two sprites: the far part under the ground, the near part (`_tee_near`, slabs, weeds, that fence) over it. `_Ground`: `mouths` (no edge, grass or drift across an opening), `stems` (a cross lane's crack joined by the middle lane's), `crack` (how far it runs). Lot indices in the middle lane start at the first real lot (`OWN_LOT` 7; `LostCats` found_at).
- Where a cross lane meets an avenue (Julien's logic, by the camera's compass): the Holt lane looks south, the green lane north, so the avenues run the way we look, not across the view. Each end of a cross lane (`ruelle.gd` `_build_avenues`) is a `CrossStreet` vista (`from_lane`: no planted curb extensions before us, a long sky fade that leaves the sun) with that street's real facades on our block's side (`_walls_along(script, gap, ∓1)`: right wall at a lane's left end, left wall at its right end; `_walls_along` adds the school past Dandurand), plain plexes across; `Part.MOUTH` carries its sidewalks and road on past the lane's mouth to the bottom of the view (dropped curb on the lane's side). Walking in from the avenue we face the corner plex's side wall (`LaneArt.side_wall`, lot kind "wall", the first facade's height and brick), then its one yard (`SIDE_LOTS`), the middle lane going off ("↑ Ruelle", `LaneArt.junction`), one more yard or garage and the other corner's side wall, then the other avenue. No lane has blurred leaf piles or shrubs: the near side's fence always runs along the bottom of the view, blurred (`LaneArt.near_fence`, `_build_foreground`, top at `NEAR_FENCE_TOP`, in a parallax layer, its ends lined up for when the camera stops at the ends; creeper with `_vine` on `NEAR_FENCE_VINES` of its stretches, bare stems in winter), stopping only where a cross lane or an avenue opens toward us. She stands on the avenue's sidewalk at the lane's end (`_sidewalk_spot`, `o.x`, the bounds), never on the road; click the vista or ↑ there to come out on that street, where she can go either way.
- The trees behind the buildings (`Skyline._backyard_trees`, streets and lanes): `LaneArt._distant_tree` too, hazy, four pictures per season cached in `Skyline._trees`; never plain circles.
- Trees seen from afar in the lanes (`LaneArt._distant_tree`, down `junction` and `tee`): never a ball on a stick. The trunk tapers, each limb leaves it at its own height and carries a clump (`_foliage`), the clumps fanned out wider than tall with sky between them, upper-left ones lit and drawn last; bare limbs and twigs in winter.
- Lane vegetation (`LaneArt`, section "Vegetation", from `reference/ruelle/`): real leaves (`_leaf`, broad and pointed) massed over a dark shade and lit from the upper left. `_foliage(rng, c, r, colors, leaf, count)` is the mass for hedges, shrubs, tree crowns and creeper patches; it adds enough leaves to cover its size, and draws bare twigs (`_twigs`, red berries on some) when `colors` is empty, i.e. in winter. `_vine` hangs over a fence's top with trailing strands, `_climber` covers a stretch of wall in a sheet (not drawn as a shape with an outline: leaves show at its edge), `_grass`, `_bloom`, `shrub_colors()`, `grass_colors()`. Every one of them consumes the same random numbers in every season, as the seasons rule asks. On the ground (`_Ground`, one `Street._Batch` mesh): grass clumps along the fences (`_clump`), wild flowers or seed heads, the crack's strip of weeds with rosettes, leaf drifts along the fences. Don't go back to ellipses or triangles.
- The lane running away from us (`LaneArt.junction(rng, w)`): one-point perspective on `CrossStreet.HORIZON_Y` (`at(p, d)`, like `CrossStreet._at`). Far to near: the sky down the gap (a gradient in strips, fading in at the top and at both sides, hiding the distant city), what closes the far end (the far lane's fence), the plex backs with windows and galleries, yard trees arching over, the cracked concrete with the central strip of weeds and drifted leaves, then, sorted by depth (`near`): stretches of board, green chain-link, picket, tôle and shed, creeper, shrubs spilling onto the concrete, grass, poles and wires.
- Tree foliage (`PropArt.tree`, `_tree_leaves`, streets, vistas and lanes alike): the scalloped clumps are only the shaded shape now; about a thousand leaves (`LaneArt._leaf`, own random numbers) lie over them, each taking its clump's colour most of the time, turned outward and lit from the upper left. The shared `rng` still draws exactly what it used to, including for the old ellipse leaves (a loop that only consumes them), so the rest of the street doesn't move; winter's `_bare_crown` is unchanged.
- Clotheslines (`_Clotheslines`): the laundry hangs near the gallery's pulley (t 0.06–0.3 along the line, smaller scale), not out in the sky over the lane.
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
- Street doors and stairs follow `reference/rue/portes.jpg` and `reference/rue/escaliers.jpg`: generator `DOOR_STYLES` (double,
  panel, oval, leaded stained glass, diamond, 1950s slots, slit, planks, slats, fan_top, grid, sunburst, porthole, grille,
  horizontal, arched_panels, double_leaded), optional stained-glass `sidelights`, and `door_surround` (lintel, cornice on brackets, pediment,
  arch with fanlight), door lights by `lamp_style` (lantern, globe, coach, cylinder, box, a single one hung over the
  door, or one on the left; `_door_lamps`), `ornate` stair railings (spades, scrolled newel), `stair_kind` "landing" (L with a landing on
  posts) or "curve"; drawn last in `_variant` so other draws don't move. Spiral staircases only in the lane
  (`LaneArt._spiral`), never on the street side.
- Lane entrances are wide (generator widths: `ruelle` 560, `ruelle_verte` 640, about a plex); and every block's lanes are in line (Julien's logic): `_lane_through` draws, far to near under an open sky hiding the skyline (`_lane_sky`, colours copied from `Season.sky()` since a `--script` run can't load `Season`), this lane's yards, the next avenue (`_lane_avenue`), then the next blocks' lane entrances (`_lane_stretch`: facades, corner sides, fences, plex backs, trees), four blocks down to the vanishing point. Labels on them go by the texture's width.
- Lane entrances seen from the street (generator `_ruelle_verte`, `_ruelle`) use `_fine_tree` (trunk, limbs split three
  times, hundreds of small leaves in this season's colours, bare and snowy in winter) instead of round blobs; the Holt-side
  entrance is drawn in perspective (fences, tôle garage, creeper, clothesline, weeds, bin, bunting).
- `art/decor/*.svg`: house façades, **generated**. Edit `tools/generate_houses.gd` and regenerate instead of hand-editing:
  `Godot --headless --path . --script res://tools/generate_houses.gd`
- `art/logo.png` is cut out of `art/logo.jpg` by `tools/cutout_logo.gd` (same headless invocation).
- `reference/` holds real-world reference photos, sorted (see `reference/LISEZMOI.md`): `personnages/`, `maison_charlotte/` (with `interieur/`), `coin_dandurand/`, `coin_holt/`, `ruelle/`, `rue/` (doors, stairs, curb gardens, example houses), `cartes/`, `logo/`. It is gitignored; new pictures go in the matching folder.

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

## The map

- `ui/town_map.gd` is the `TownMap` autoload (CanvasLayer 76): button left of the notebook's, or the **C** or **M** key (Shift+M now mutes), opens "Mon quartier",
  a big sheet of drawing paper drawn like a child (wax crayon, `CuteArt._shape/_stroke/_crayon_line`, wobbly lettering): north up,
  Rue Holt (north, on top) and Rue Dandurand (south), 5e Avenue (west) and 6e (east), 4e and 7e faded, her block washed in yellow with the
  houses in rows, the lanes as an H, her house (`HOUSE_X`), Oh Bon!, Xin-Xin, the school across Dandurand (below it), a compass (N, S, O, E), and a stop sign "Pas le droit d'aller plus loin toute seule !" while `GameState.age < StreetScene.CROSS_AGE`.
  A little Charlotte (`_You`) shows "Je suis ici !" where she is: `TownMap._here()` maps each scene (street scenes by how far along
  far along she is, lanes, the house, the shops) onto the sheet. The game pauses while it is open; Esc, C or a click outside closes it; the
  notebook (N) and the menu (Esc) ignore their keys while it is open. The roads keep the real proportions measured on `reference/cartes/google_map_immediate_area.png`: a block is about 3× as long (Holt to Dandurand) as wide (5e to 6e), the lanes about 18 % in from each street; the title, compass and stop sign sit in the paper margin left of `SIDE`. Geometry constants (`HOLT_Y`, `DAND_Y`, `SIX_X`, lanes…) are at the
  top of the file: a new place on the block = a drawing in `_Sheet` + a case in `_here()`.
- Whatever she can't reach is coloured over in grey crayon (`_Sheet._reachable`, `_grey_out`, names, title and doodles on top): before `CROSS_AGE` all but her block and the streets round it; from then on the corners across them and the school come back, and 7e, 4e and the houses farther west stay grey (no scene goes there). A new place she can reach = widen `_reachable`.
- `--map` (a user arg, after `--`) opens it one second after the scene starts, for screenshots: `Godot --path . --screen 1 res://scenes/holt.tscn -- --screenshot=/path/map.png --wait=2.5 --map`.

## Where she is

- `ui/place_label.gd` is the `PlaceLabel` autoload (CanvasLayer 52: above the grade, under the bedtime night and every window; clicks go through it): a plate at the top middle of the screen naming the place, from `NAMES` (key: the scene file's name; a scene not listed, like the title screen or `tools/`, shows no plate) or the scene's own `room_name()` (the house: "Chez moi : le salon", "Ma chambre"; it follows her as she walks). **A new place = one line in `NAMES`** (or `room_name()` for a scene with rooms).

## Quests and growing up

- Vision (Julien): Charlotte starts at 7 (`GameState.age`, saved). As she completes quests and makes friends she grows up,
  may go farther in the neighbourhood and gets more advanced quests. A year is slow: all four seasons must pass and dozens
  of quests be done (the ageing rule isn't implemented yet). Gate new quests and places by age.
- `world/quests.gd` (`Quests`): the catalogue (`ORDER`, `ALL`: `title`, `hint` = where to go, `find` = clue shown before it
  starts, `age`, optional `after` = quest it waits for, `reward` in $). Several quests can be on at once. State in
  `GameState.quests` (absent / "active" / "done"); `available`, `start`, `complete` (adds the reward), `stars`, `money_text`.
- `ui/notebook.gd` is the `Notebook` autoload (CanvasLayer 75): button left of the mute button (N key), "Mon carnet" with
  two pages behind coloured tabs on its edge (`Notebook.TABS`, click or ←/→): Missions (En cours + hint, Réussies with yellow stars, À découvrir with clues) and Mes amis (`Notebook.FRIENDS`: name, note, story flag; **a new friend = one line there**); age and pocket money; crayon doodles, ribbon bookmark, elastic,
  washi tape on the page; pauses the game while open. Hidden
  on the title and `tools/` scenes. `Notebook.announce()` (called by `Quests`) pops "Nouvelle quête" / "Quête réussie !".
- `QuestMark.make(at, condition, scale)` (`world/quest_mark.gd`): a bobbing yellow "!" over a quest giver, or over where
  to go next, while `condition` is true.
- The quests so far:
  - milk: Mom gives it, buy the pint of milk (a one-litre carton, `ShopArt.milk_pint`, its name "Québon" a plain label) at the
    dépanneur (free, `flags.has_milk`); Charlotte carries it in her arms (`Carry.milk()`, restored in every scene) to Mom;
  - everything she holds in her arms goes through `world/carry.gd` (`Carry`): ONE saved flag `flags.carried` ("milk", "can" or
    "cat:<id>"), one thing at a time. `Carry.take(who, kind, id)` is the only way to put something in her arms and returns
    false when her hands are full (say `Carry.FULL_HANDS`); `put_down`, `has(kind)`, `busy()`, `cat_id()`; scenes call
    `Carry.restore` as they open, so it follows her through doors and saves (old saves are migrated). A NEW thing to carry =
    one more case in `Carry._build()`, then `Carry.take` / `Carry.put_down` in the quest: nothing else to remember;
  - amies: Mom gives it, the very first one she gives: go and make friends in the middle lane, where the twins Turcotte play; meeting them (`Twins._meet`, flag `met_twins`) completes it, and if she met them first Mom just congratulates her; the notebook's friends page lists them from that flag;
  - hamster: Dad gives it; feeding sets `flags.hamster_fed` (cleared at bedtime); going to bed unfed is refused, fed completes it;
  - lost cats, `world/lost_cats.gd` (`LostCats.ALL`, ids = quest ids cat, cat2, cat3, chained by `after`): Pistache
    (found on Dandurand, home 5684 6e Av.), Caramel (in the lane, home 5679 5e Av.), Bijou (in the lane, home 2655 rue
    Holt). `StreetScene._build_lost_cats()` (streets and the lane): the "PERDU" `LostCats.Poster` on the street's pole (taken down once the cat is found, `poster_up`)
    starts it; the collared cat waits at `found_at` (`_found_x`; lane = lot index); petting it, Charlotte picks it up
    (`GameState.flags.carrying`, `Character.carry(node)` / `is_holding()`, `LostCats.held(id)`, kept across scenes and
    indoors); at the owner's front door (`_door_x(art)` from `art/decor/doors.json`, written by the generator; "!" and
    house number) the owner comes out (`_bring_home`), takes the cat in her arms (`Character.carry`, `LostCats.held`), thanks Charlotte, quest done, and goes back in through her door with it. Owners are always at a front
    door on a street, never in the lane.
  - menage (Mom gives it, after the milk; the toys can't be picked up before): 11 things on the bedroom floor (`MESS`,
    `InteriorArt.mess`). Charlotte picks each one up IN HER ARMS (`Carry` kind "toy:<item>", so only one at a time), says
    where it goes ("Mon toutou va sur mon lit !", from `ITEMS` / `DESTS`: bed, laundry basket, toy corner, shelf, desk, by
    the door) and a "!" marks that spot; the child clicks the right place to put it away (a wrong one: "Pas ici !" and
    she says it again); `flags.tidied` lists what is put away; the last one completes the quest;
  - plants (Dad gives it): five thirsty plants (`_plant(id, kind, …)`, `InteriorArt.house_plant(kind, thirsty)`:
    monstera and a pothos on a stool by the window in the salon, a fern on a low stool and a fiddle-leaf fig in the corridor, a peace lily
    in the bedroom; thirsty = drooping, yellowed, brown tips, dry soil, dead leaves; the sprite swaps to the healthy
    picture when watered; she stands beside the pot (`POUR_REACH`), steps up toward the wall (`POUR_STEP`, the plants stand
    against it), lifts the can with her hands on its handle (`Character.carry_lift`, `carry_grip`), tips it, and drops arc
    from the spout (`CAN_SPOUT`) onto the soil (`InteriorArt.plant_soil`)) and the watering can in the kitchen (`InteriorArt.watering_can`, carried with
    `Character.carry`, `flags.has_can`); `flags.watered`; the can goes back when all have drunk.
- The twins' house, `duplex_jumelles` (generator entry, 5716 6e Avenue, `reference/maison_jumelles/`, replaces `plex_08` in `main.gd`'s layout, the second house before the Holt lane): warm brown brick with dark mortar, black-framed windows under brick arches, a glass door (door style `glass`), white concrete balcony, black open-tread stair curving to the right, low black fence; Halloween decorations kept.
- Charlotte's own house, `duplex_charlotte`, follows `reference/maison_charlotte/`: dark red-brown brick with pale mortar, white-framed windows, a varnished wood door with glass sidelights and iron scrollwork (door style `grille`), the white balcony under a dark metal awning with a bamboo shade (`bamboo`) and the numbers 5674 / 5672 beside the doors, a black mailbox (`mailbox`), a straight black stair to the right, the porch's steps at the LEFT (`steps_side`, `_side_steps`), two bikes at the fence (`bikes`, `_bike`). Its door is at SVG x 348: the game reads it from `doors.json` (`StreetScene._door_x`). Halloween decorations kept.
- Alphée and Constance Turcotte, twins (spelling: **Alphée**), from `reference/personnages/alfée-et-constance-turcotte.jpg`, nearly identical, a little under a head taller than Charlotte (age `"tween"`, a rig in `CharacterArt.RIGS`, not in `CharacterLook.AGES` so no random passerby gets it), who will be her best friends and give her quests (which ones: not decided, Julien will say). `CharacterLook.alphee()` (hair down, teal T-shirt with a heart, `look.necklace`), `constance()` (ponytail, beige sweater with the `"birds"` pattern, `look.earring`); which is which was my guess from the photo. `world/twins.gd` (`Twins`): in the middle lane at `TWINS_LOT`, only once the "amies" quest is active or done (or they were met); "!" until the first click, the meeting (`MEETING`, Charlotte hands off, `flags.met_twins`, cleared by the debug menu's "Tout effacer"); then the one clicked says one of her `LINES`. **Their quests go in `Twins.interact`.**
- Julien's list of quest ideas for later is in `docs/idees-de-quetes.md` (pizza hidden by a squirrel, jogging with Dad,
  buying sour-cream-and-onion chips at the dépanneur…): read it before inventing new quests, and tick them off there.
- The dépanneurs have real Montréal prices (2026), in `Shop.PRICES` (candy 1,25 $, lollipop 0,75 $, chips 2,99 $, sloche 2,75 $, hot chocolate 2,25 $, popsicle 1,75 $, juice 2,25 $, pint of milk 3,29 $, bread 3,99 $, coffee 2,00 $; the specials board and the "CAFÉ 2 $" poster use them). `Shop._buy(picture, text, price)` first opens `ui/buy_dialog.gd` (`BuyDialog`, CanvasLayer 62, group "modal": item, price, pocket money and what is left, "Acheter" / "Non merci"; when short, how much is missing and only "D'accord"), then pays from `GameState.money`. Start money is 5,00 $ and quest rewards are 1–3 $ so a snack costs one or two quests.

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
- `ui/cute_art.gd` (`CuteArt`): little drawings on any CanvasItem (cat, dog, hamster heads, `capybara` / `capybara_head` with an orange on its head: Julien wants some in the children's doodles on the menu, the map and the notebook, flower, heart, star, sun,
  house, Charlotte's self-portrait), clean or `crayon` (hatched fill clipped to the shape, wobbly double outline). The
  notebook's doodles use the crayon style, the menu card the clean one.
- `ui/game_menu.gd` (`GameMenu` autoload, CanvasLayer 78): ☰ button top-left or Escape (unless the notebook is open)
  pauses and opens Reprendre / Options (Musique and Effets sonores volume sliders on those buses, Plein écran) /
  Écran titre / Quitter le jeu (both save through the scene's `Saver` first). Options in `user://settings.cfg` [options]. The card is notebook paper like the notebook and the map (grain, ruled lines, washi tape, the pets peeking): crayon-lettered titles (`_CrayonTitle`), sticker-style coloured buttons with a little drawing (`_big_button(text, action, colour, icon)`), coloured sliders with a round handle and a percentage, a drawn check box; the card pops up when opened, sits on two crooked sheets (`_Pages`), the pets on it bob, crayon doodles drift round it (`_Doodles`), buttons shine and grow a little under the mouse, and a line gives her age, pocket money and the season.
- `ui/mute_button.gd` (`MuteButton` autoload): speaker button top-right on every screen, or Shift+M, mutes the Master bus;
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
  teleports to any place (`DebugMenu.PLACES`: streets, corners, lanes, rooms of her flat, spots in the shop; **when you add a new
  place, add it to `PLACES`** — a scene missing from the list shows under "Autres lieux" anyway),
  and lists every quest with "Effacer" (not started, its flags in `QUEST_FLAGS` cleared) / "Activer" / "Finir" (done, reward paid) / "Tout effacer" to test them again.
- Nothing stands behind Mount Royal: the cross-street vista paints open sky over the distant city first. Mount Royal (`CrossStreet._mountain_picture`, cached per season: ridge, woods in clumps, mist at its foot, cross and tower) shows only when the street runs west (`CrossStreet.facing = "west"`, Montreal compass); other ways end in sky and clouds.

## Conventions

- Art is made procedurally in code: SVG strings or `_draw()`. There are no hand-drawn sprites except the logo.
- **Real brands and their logos are allowed** (Julien's decision, 2026-11-01; it replaces the old "original artwork, never real
  logos" rule). Put the logo file in `art/brands/` (a transparent PNG or SVG, cropped from the brand's site, Wikimedia Commons
  or a product photo such as Open Food Facts), write where it comes from in `art/brands/SOURCES.md`, and lay it over the drawn
  art with `ShopArt._stamped(w, h, svg, [[file, Rect2i]])` (or as a Sprite/label in a scene). Chips: crème sure et oignons is
  always **Ruffles**. Not covered by this: TV shows and characters stay original (see the TV catalogue).
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
