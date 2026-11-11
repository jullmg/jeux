# streetview

Takes Street View pictures of the neighbourhood, to draw the Charlotte game from. Every picture comes with
its civic number, its street and its pin on a map.

It uses Google's official APIs (Street View Static, its metadata endpoint, Geocoding), not screenshots of the
Google Maps site. Python 3.10+; Pillow only for the PNG maps. The map tiles come from OpenStreetMap (a few dozen requests,
cached in `tiles/`).

## Setup, once

1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and attach a billing
   account (Google asks for a card even for free use).
2. Enable **Street View Static API** and **Geocoding API**.
3. Create an API key (APIs & Services → Credentials) and restrict it to those two APIs.
4. Put it in `utils/streetview/.env` (gitignored):

   ```
   GOOGLE_MAPS_API_KEY=your-key
   ```

## Use

```sh
python3 utils/streetview/capture.py                    # everything in places.json
python3 utils/streetview/capture.py --only "6e Avenue" # one street
python3 utils/streetview/capture.py --street "Rue Masson" --from 2800 --to 2990 --parity odd  # another area, one side
python3 utils/streetview/capture.py --street "Main Street" --from 10 --to 80 --city "Burlington, VT, USA"
python3 utils/streetview/capture.py --maps-only          # redraw maps and index from index.json, no Google calls
python3 utils/streetview/capture.py --detail           # plus six close-ups of each facade
```

Then open `Charlotte/reference/streetview/index.html`: a map with an arrow where each picture was taken,
pointing the way the camera looks, the list of addresses, and the picture beside it.

Output, in `Charlotte/reference/streetview/` (gitignored, like the rest of `reference/`):

- `<street>/<number>_<street>_<side>_<pano>.jpg`: the pictures, 640×640 (the API's maximum);
- `<street>/detail/…_r<row>c<column>.jpg`: with `--detail`, a 3×2 grid of close-ups (bottom row `r0`);
- `index.json`: for each picture its file, address, number, street, latitude and longitude, heading,
  panorama id, the month Google took it, and a link that opens the same view in Google Maps;
- `INDEX.md`: the same index written for an AI agent: one table per street, the pictures of Charlotte's
  block in the order the game shows them (left to right), the game scene they belong to, how to read it;
- `maps/<street>.png`: a map per street or range for an AI agent (it can open a PNG, not `index.html`): OpenStreetMap
  with a blue dot where each camera stood, a line to a red dot on the facade it looks at and its civic number;
  `maps/tout.png` shows everything. Needs Pillow (`pip3 install pillow`), else the maps are skipped;
- `index.html`: the interactive map for a person;
- `cache.json`: Google's answers, so a second run costs nothing for what is already known.

Every area goes into the same folder and the same index, one section per street or range. Pictures already on disk are not downloaded again. A run with `--only` adds to the index instead of replacing it.

## What to photograph: `places.json`

- `walks`: a street between two points. The script takes every panorama along it (about one every 10 m,
  `--step`), looks at both sides (`"sides": ["left"]` for one; left and right of the direction walked) and
  down the street from each end (`"ends": false` to skip). `from` and `to` are intersections ("A & B") or
  `[latitude, longitude]`.
  `game` names the game scene that street is, and `our_side` the side Charlotte's block is on.
- `ranges`: every building of a street between two civic numbers, anywhere:
  `{"street": "Rue Masson", "from": 2800, "to": 2990, "parity": "odd"}`. Each number is looked up and
  photographed from the nearest panorama with the camera turned to its door. Numbers that don't exist and
  numbers on the same facade as the one before are skipped. `parity` (`even` / `odd`) keeps one side of the
  street. `"between": ["Rue Dandurand", "Rue Holt"]` (or `--between Dandurand Holt`) keeps only that block and
  orders the pictures along it in that order (the game's left to right), with a wide range of numbers
  as a net. One geocoding call per number, so a long range costs a little more than a walk.
- `addresses`: one picture of a given address, the camera turned toward its door.

## Good to know

- **Resolution**: the Street View Static API caps every picture at 640×640 and has no `scale` option, so a sharper
  picture means a narrower view, not a bigger file. The main picture (90°) is for context; `--detail` adds six
  30° close-ups per building (three across, two up), three times the pixels per degree: bricks, number plates, door
  and railing details are readable. Use `--detail` for anything that will be drawn. (Stitching Google's raw panorama
  tiles would be sharper still but isn't an official API: not done.)
- **Only Google's own pictures**: Street View also serves pictures from others (the city's SIRR pictures, users'
  photospheres): darker, from another camera. The tool checks each panorama's copyright and refuses all but
  "© Google"; it looks around the spot for a Google one instead.

- The civic number of a walk's picture is the address Google finds nearest to the facade the camera looks
  at (14 m to the side of the car). It can be one door off, and at a corner it may be on the cross street;
  the map marks it as approximate. An entry in `addresses` is exact.
- The back lanes have no Street View: the car doesn't go there.
- The picture may be a few years old; its date is in the index and on the map.
- Cost: metadata calls are free. A full run of the block is around 150 pictures and as many geocoding
  calls, far under Google's free monthly allowance (check the current pricing page). `--detail` makes seven
  times the pictures.
- Google's terms restrict keeping and redistributing its imagery: these pictures are private drawing
  reference only. Keep them out of git (they are) and never put them in the game itself.

## Drawing the game from the pictures

The agent's instructions are in `Charlotte/docs/drawing-from-streetview.md` (INDEX.md points to them). Ask, for example: "Read `Charlotte/docs/drawing-from-streetview.md`, then make 5680 6e Avenue match the real building."
