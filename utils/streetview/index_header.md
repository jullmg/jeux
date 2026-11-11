# Street View du quartier : index

Written by `utils/streetview/capture.py`. Reference pictures of the real streets, to draw the Charlotte game from.
Private reference only: never copy a picture into the game or commit it.

How to use it (for an AI agent or a person):

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
- **close-ups**: with `--detail`, six sharper pictures of the same facade in `<street>/detail/`, named
  `…_r<row>c<column>.jpg` (row 0 = ground floor, row 1 = upper floors and cornice; columns left to right).
- The other side of each street and the views down the street (for the cross-street vistas) follow in their own tables.
