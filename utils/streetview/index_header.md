# Street View du quartier : index

Written by `utils/streetview/capture.py`. Reference pictures of the real streets, to draw the Charlotte game from.
Private reference only: never copy a picture into the game or commit it.

How to use it (for an AI agent or a person):

- **The neighbourhood first**: `maps/quartier.png` and `maps/quartier_detail.png`, Rue D'Iberville to Boulevard
  Saint-Michel, Rue de Bellechasse to Boulevard Saint-Joseph Est, Montréal north up (as in the game).
- **Start with the map** named at the top of each section (`maps/*.png`, a picture you can open): street names, the
  buildings' footprints with their civic number ranges, a blue dot where each camera stood, a line to the red dot
  on the facade it looks at, with that facade's number. North is up. Use it to place a building in its street
  (corner, which side, neighbours, trees and parking lanes round it) before opening its photo.
- Each row is one picture. Paths are relative to this folder (`Charlotte/reference/streetview/`). Open the JPEG to
  look at it; `index.json` holds the same rows as data (plus `pano`, `heading`, a `maps` link and the `details` files).
- One section per street walked, in the direction the game scrolls. **m along** is the distance from the walk's
  start: on the side marked "Charlotte's block", rows in increasing order are the facades from left to right on
  screen, so they line up with that scene's `layout` (the game scene is named in the section title).
- Consecutive pictures are about 10 m apart and overlap: one building shows in two or three of them.
- **address** is the civic number and street. "(approx.)" means Google's nearest address to the facade the camera
  looks at: it can be one door off, and at a corner it may be on the cross street. Check the number on the door
  in the picture. Rows under "Adresses demandées" are exact, the camera turned toward that door.
- **taken at** is the camera's latitude, longitude (in the roadway, not at the building). `index.html` shows them on a map.
- **close-ups**: with `--detail`, six narrow-view (30°) pictures of the same facade in `<street>/detail/`, named
  `…_r<row>c<column>.jpg` (row 0 = ground floor, row 1 = upper floors and cornice; columns left to right, about
  ±14° and a little overlapping). The main picture is 90° wide and 640 px: use the close-ups for any detail (bricks,
  number plates, railings, door and window styles).
- The other side of each street and the views down the street (for the cross-street vistas) follow in their own tables.
- **The pictures show one day (often Halloween): decorations, bikes, cars, bins, scaffolding and other temporary or unusual
  objects are not part of the building and must not be drawn** (details in the guide below).
- **To draw a building from these pictures in the game, follow `Charlotte/docs/drawing-from-streetview.md`.**
