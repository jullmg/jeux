# Drawing buildings from the Street View pictures

For an AI agent asked to make or improve a building (or its surroundings) in the game from
`reference/streetview/`. Read `Charlotte/.claude/CLAUDE.md` too: its rules on seasons, random draws and the
generator still apply. The pictures are private reference (Google's imagery): look at them, draw from them,
never copy one into the game or commit it.

## 1. Find the real building

0. **Get the lay of the land first**: `reference/streetview/maps/quartier.png` (the whole neighbourhood) and
   `maps/quartier_detail.png` (the same, zoomed in enough to read street names and civic numbers). They cover
   Rue D'Iberville to Boulevard Saint-Michel (west to east) and Rue de Bellechasse to Boulevard Saint-Joseph Est
   (north to south), turned so that **Montréal's north is up** — the north the streets are named by, the game's
   and its town map's (`ui/town_map.gd`), not true north (both arrows are drawn). Charlotte's block is yellow,
   her house a star, the photographed facades red dots. Use them for anything beyond one street: which streets
   and parks lie around, what a cross-street vista looks toward, how far a place is, where a new scene would sit.
1. Open `reference/streetview/INDEX.md`, then the map named at the top of the street's section (`maps/*.png`).
   It tells you where the building stands: which side of the street, how far from the corner, what is
   beside it and across from it. North is up.
2. Take its row: civic number, picture, camera position. "(approx.)" numbers can be one door off: check the
   number on the door in the photo. For a range of numbers or a missing building, ask for it to be captured
   (`utils/streetview/README.md`, `--street … --from … --to …`, `--detail` for close-ups of bricks, doors and
   cornices).
3. Which building of the game is it? On 6e Avenue the scene's `layout` (`scenes/main.gd`) runs left to right
   from Rue Dandurand to Rue Holt, and civic numbers grow toward Holt (Charlotte's duplex `duplex_charlotte`
   is 5672, the twins' `duplex_jumelles` 5716). Each entry in the generator may carry a `"number"`; the
   other streets' scenes (`holt.gd`, `cinquieme.gd`, `dandurand.gd`) have their own `layout`. A generic
   `plex_NN` is an invented building that the real one can replace. If the real building isn't in the
   layout, say so and ask before changing the layout (widths shift everything after it).

## 2. Look before drawing

Open the main picture, then the close-ups if there are any. Write down, from the photo, not from habit:

- Storeys, width against height, roof line (flat parapet, cornice, pediment), chimneys. **Count the storeys on the main
  picture only, never on the close-ups**: their two rows overlap by about half, so the same balcony, canopy or row of
  windows shows in both, and a duplex laid out as `r1` over `r0` looks like a triplex (it happened: eight duplexes across
  6e Avenue were first drawn with three floors). Count the doors up the facade and the balconies over the street door;
  check the height against the neighbours in the same picture (a duplex beside a triplex is a floor lower); a mansard or
  a tall parapet is the top of the last floor, not a floor of its own. Write the number down before drawing.
- Brick: colours (several, mixed), mortar colour, any stone or painted base, soffits.
- Windows: how many per floor, their x positions, style (hung, casement, arched), lintels and sills.
- Door(s): position, style, surround, lamps, number plate, awning.
- Balcony / gallery: slab, railing kind, posts, awning; the stair: straight, curved, landing, where it starts
  and which way it goes down, its rail, its beam.
- Fence and front garden, trees at the curb, lamp post, hydrant, poles, parked bikes: those belong to the
  street scene, not to the facade.
- What isn't part of the building (see "Draw the building, not the day the photo was taken" below): note it and leave it out.
- What the photo can't tell you (the back, the lane, the inside): don't invent it as fact.

### Draw the building, not the day the photo was taken

The pictures are one moment (most of ours are October 2024, so Halloween is everywhere). The game has its own
seasons and its own decorations (the generator adds Halloween, wreaths, Christmas lights, snow and flowers by
season, and the night of the Halloween quest), so **a seasonal or temporary thing seen in the photo is never
drawn into the building**, or it would stay there all year and double up with the game's own.

Leave out:

- **Halloween and other holiday decoration**: pumpkins, skeletons, ghosts, cobwebs, bats, tombstones, straw
  bales and corn stalks, Christmas lights and wreaths, flags and banners, string lights, signs for a party.
  Don't copy a colour just because a decoration covers it (orange lights, black cloth): look at the wall
  behind it, or at another picture.
- **Seasonal state**: leaves on the ground, snow, flowers and pots on the steps, bare or leafy trees, and the
  light of the hour (a shadow across a facade is not a dark patch of brick). The seasons are the game's job.
- **Anything unusual or temporary on or in front of the building**: scaffolding, a construction fence, a tarp,
  a dumpster or bins, bikes, strollers, a parked car or truck, a moving van, people, signs and posters taped up,
  real-estate or political signs, graffiti and tags, laundry, an air conditioner in a window, patched or
  boarded windows, a satellite dish, extension cords, a ladder.
- **The camera's own artefacts**: blurred faces and number plates, the car's roof in the corner, the Google
  logo and copyright, stitching seams, lens distortion at the edges of a picture.
- **A repair or odd change that clearly isn't the building's design** (a window bricked up, a mismatched door put
  in later): ask the user whether it belongs.

Keep what is part of the building, however small: the bricks and their colours, lintels, cornices, windows and
their sills, doors and their surrounds, stairs and rails, balconies and their posts, lamps and the number
plate, mailboxes, the fence and gate, the meter box and downpipes, fixed awnings. Mailboxes, gates and similar
fixtures are the building's even if they are unusual; **a fixed fixture that is part of the facade stays, an
object that could be moved away tomorrow goes**. When in doubt, compare the building across several pictures
(the main one, its close-ups, a neighbour's picture that shows it from another angle, another capture date if
there is one): what is in all of them is the building, what appears in one is an object.

Mention in your report what you left out on purpose (for example "5671: pumpkins on the stair, a bike, a
parked car: not drawn"), so the user can overrule you.

## Reuse what is identical or similar

Montréal's plexes were often built in rows by one builder: neighbours (and buildings across the street or on the
next block) are frequently the same design, a mirror image of it, or the same with one change (another door, a
bricked-up window, a different railing, a painted base). Don't draw each one from nothing:

- **Compare the pictures** of the building with those of its neighbours and of the existing generator entries
  (`duplex_charlotte`, `duplex_jumelles`, the numbered `plex_NN` … ). Same storeys, window rhythm, door and stair
  position, cornice and lintels = same design.
- **Identical**: don't add a second copy of the data. Point the second building at the same design: the layout
  can list the same SVG name twice, or the generator can write the second name from the same entry. The number plate,
  the brick tone (when the bricks really differ) and what makes it different are the only things to override.
- **Mirror image**: the generator already has `_mirror(cfg)`, which flips the door, windows, balcony, porch, stair
  and basement across the facade. It doesn't know the other side-dependent keys (`steps_side`, `downspout`,
  `awning_posts`, `iron_posts`, `rail_up`/`rail_down`, a fence gate…): flip those yourself and check the result in a screenshot.
- **Similar**: copy the entry's keys with `k.merge(cfg, true)` semantics in mind: start from the closest entry and
  override only what the pictures show differently, with a comment naming the building it is based on and the
  pictures used. A difference seen on one picture only is probably an object (see above), not a design difference.
- **Parts**: a part that recurs across different buildings (a door style, a stair kind, a lamp, a railing, a fence, a
  lintel, a window style, a cornice, a base) is one case in the generator, chosen by a key, not code pasted into
  each house. If the real part isn't there yet, add it once, as a new option, and use it everywhere it applies; check
  that the buildings that already use the old option don't change (same random draws).
- **Surroundings**: the same goes for trees in their pits, fences, curb extensions, lamps and poles: one shared
  builder, parameterised, never a hand-placed copy for one house.
- Tell the user what you reused and from where ("5665 and 5669 are the same design as 5661, mirrored, 5669's door
  repainted"), and when you aren't sure two buildings are the same design, say so instead of merging them.

## 3. Draw it

Facades are **generated**, never hand-edited: `art/decor/*.svg` come from `tools/generate_houses.gd`.

1. Find the entry (a dictionary in the generator's list: `duplex_charlotte`, `duplex_jumelles` are the best
   models of an entry made from photos, with comments citing the reference). Edit it, or add one with the
   data keys the others use (`bricks`, `mortar`, `windows`, `door_cx`, `balcony`, `stair`, `fence`, …).
   The `DEFAULTS` constant lists every key. Something the generator can't draw yet (a new door style, a
   railing, a cornice) is a new case in the generator, in the same style as its neighbours.
2. Regenerate: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/generate_houses.gd`
   (after adding a `class_name` script run `--headless --path . --import` first). It writes every season,
   the Halloween "over" layers, `windows.json` and `doors.json`.
3. Put the building in its scene's `layout` if it isn't there, and keep the street's data in line
   (`trees_after`, `lamps_after`, `hydrants_at`, `racks_at`, `squirrels_at` are indexes or fractions across
   `layout`; inserting a house shifts them all).
4. Surroundings seen in the photo that the street doesn't have yet (planted curb extension, tree pit, fence,
   a stair into the sidewalk) go through the street scene's hooks (`_decorate_house`, `_build_sidewalk_props`,
   `_build_extra_props`) or the shared builders; a feature that appears in many places becomes a generator
   or scene option, not a one-off.

Rules that bite:

- **Same random draws in every season**, and new drawing code goes **last** in the generator's `_variant`,
  so the other houses don't move.
- Keep the game's look: procedural SVG, light from the upper left, leaves never balls, no photo textures.
- Real brands and logos are allowed only as in the project's conventions (`art/brands/`), nothing from the pictures.
- Transcribe numbers and plates exactly (5672, not 5670), in French where there is text.
- Don't touch the other buildings, and don't break the real photographs already used (`reference/maison_charlotte`,
  `coin_holt`, …): when two references disagree, keep the one the user chose and mention it.

## 4. Check it

Always `--screen 1` and `-- --no-save` (never overwrite the player's save).

```
Godot --screen 1 --path . --quit-after 2000 res://scenes/main.tscn -- --screenshot=/path/a.png --x=<x of the building> --wait=2 --no-save
```

Take it in every season (`--season=winter` …) and the night (`--halloween`), then **compare side by side
with the Street View picture**: same number of windows, same door and stair side, same colours in the same
light, same proportions. Fix and repeat until you can't tell what differs; an item you left out on purpose
goes in the report. The user judges by eye and wants every detail as close to the pictures as possible.

Finally: update `Charlotte/.claude/CLAUDE.md` for what changed (building, new generator option, new
surrounding), commit one task at a time on `main` (never push unless asked), and list in your report the
pictures used (file names from INDEX.md) so the user can check.
