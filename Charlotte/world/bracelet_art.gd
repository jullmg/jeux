class_name BraceletArt
extends RefCounted
## What the friendship-bracelet studio (`ui/bracelet_studio.gd`) draws: the knotted strip pinned to a knee (rows of `W` knots,
## each knot a little slanted loop of thread lit from the upper left), the loose threads hanging under it, the letter beads, the
## charm, and the finished bracelet as a loop. A bracelet is a Dictionary: colors (hex strings, 2 to 6), pattern
## (`PATTERNS`), word (letters for the beads), charm (`CHARMS`).
## **A new pattern = `PATTERNS` + a case in `knot_index`; a new charm = `CHARMS` + a case in `draw_charm`.**

const W := 6
const ROWS := 30
const PITCH := 11.0
const KNOT := Vector2(15.0, 13.0)
const PALETTE := ["#E04F5F", "#FF8A3D", "#FFD23F", "#9BD84B", "#3E8E5A", "#2FB7B0", "#4FA3E0", "#1D4F91", "#7E57C2", "#C77DFF",
	"#FF7BA3", "#F7C7D2", "#FFFFFF", "#2B2B2B", "#8D6E63", "#BFE3F7", "#C9EDB3", "#FFE9A8"]
const PATTERNS := [["chevrons", "Chevrons"], ["rayures", "Rayures"], ["losanges", "Losanges"], ["damier", "Damier"]]
const CHARMS := [["", "Aucune"], ["coeur", "Cœur"], ["etoile", "Étoile"], ["lune", "Lune"], ["fleur", "Fleur"], ["trefle", "Trèfle"]]
const LINE := Color("#3A3048")
# How far each column is from the middle (a V for the chevrons).
const DEPTH := [2, 1, 0, 0, 1, 2]


## Which of her colours the knot at (`row`, `col`) is.
static func knot_index(data: Dictionary, row: int, col: int) -> int:
	var n: int = maxi(1, (data.colors as Array).size())
	match str(data.pattern):
		"rayures":
			return (row + col) % n
		"losanges":
			var r := absi(row % 8 - 4)
			return (absi(r - int(DEPTH[col])) + row / 8) % n
		"damier":
			return (row / 2 + col / 2) % n
	return (row + int(DEPTH[col])) % n


static func knot_color(data: Dictionary, row: int, col: int) -> Color:
	var colors: Array = data.colors
	if colors.is_empty():
		return Color.WHITE
	return Color(colors[knot_index(data, row, col)])


# Chevrons lean in toward the middle; the stripes all lean one way.
static func _slant(data: Dictionary, col: int) -> float:
	if str(data.pattern) == "rayures":
		return 1.0
	return -1.0 if col < W / 2 else 1.0


## One knot: a fat slanted loop of thread with its shade, a highlight and the crease where the thread wraps.
static func draw_knot(ci: CanvasItem, c: Vector2, col: Color, slant: float, s := 1.0, pop := 1.0) -> void:
	var rx := KNOT.x * 0.55 * s * pop
	var ry := KNOT.y * 0.5 * s * pop
	var rot := slant * 0.55
	var pts := PackedVector2Array()
	for k in 18:
		var a := TAU * k / 18.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	ci.draw_colored_polygon(pts, col.darkened(0.35))
	var inner := PackedVector2Array()
	for k in 18:
		var a := TAU * k / 18.0
		inner.append(c + Vector2(-0.6, -0.8) * s + Vector2(cos(a) * rx * 0.82, sin(a) * ry * 0.74).rotated(rot))
	ci.draw_colored_polygon(inner, col)
	ci.draw_line(c + Vector2(-rx * 0.5, 0).rotated(rot), c + Vector2(rx * 0.5, 0).rotated(rot), col.darkened(0.25), 1.2 * s, true)
	ci.draw_circle(c + Vector2(-rx * 0.35, -ry * 0.35).rotated(rot), ry * 0.28, Color(1, 1, 1, 0.45))


## The strip with `rows` rows tied, its top at `top` (the middle of the first row), and the loose threads under it, `hang` px long.
static func draw_strip(ci: CanvasItem, top: Vector2, data: Dictionary, rows: int, s := 1.0, hang := 110.0, pop := 1.0) -> void:
	var colors: Array = data.colors
	var n: int = maxi(1, colors.size())
	# The loose threads: two per colour, fanning a little and swaying at their ends.
	var strands := n * 2
	var from_y := top.y + (rows - 0.4) * PITCH * s
	for k in strands:
		var u := (k + 0.5) / strands - 0.5
		var x0 := top.x + u * W * KNOT.x * 0.85 * s
		var line := PackedVector2Array()
		for j in 11:
			var t := j / 10.0
			line.append(Vector2(x0 + u * 26.0 * s * t + sin(t * 3.0 + k) * 2.0 * s, from_y + t * hang * s))
		var col := Color(colors[(k / 2) % n]) if n > 0 else Color.WHITE
		ci.draw_polyline(line, col.darkened(0.3), 3.6 * s, true)
		ci.draw_polyline(line, col, 2.2 * s, true)
	for r in rows:
		for c in W:
			var at := top + Vector2((c - (W - 1) / 2.0) * KNOT.x * 0.92, r * PITCH) * s
			draw_knot(ci, at, knot_color(data, r, c), _slant(data, c), s, pop if r == rows - 1 else 1.0)


## The letter beads down the middle of the strip, from row `from`.
static func draw_beads(ci: CanvasItem, top: Vector2, word: String, s := 1.0, from := 9) -> void:
	var font := ThemeDB.fallback_font
	for i in word.length():
		var c := top + Vector2(0, (from + i * 1.9) * PITCH) * s
		var r := Rect2(c - Vector2(10, 10) * s, Vector2(20, 20) * s)
		ci.draw_rect(Rect2(r.position + Vector2(1.5, 2) * s, r.size), Color(0, 0, 0, 0.25))
		ci.draw_rect(r, Color("#FFFDF7"))
		ci.draw_rect(r, Color("#B9B0A2"), false, 1.4 * s)
		ci.draw_line(r.position + Vector2(2, 2) * s, r.position + Vector2(18, 2) * s, Color.WHITE, 1.4 * s)
		var letter := word[i]
		var size := int(16 * s)
		var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		ci.draw_string(font, c + Vector2(-w / 2.0, 6.0 * s), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#E04F5F") if i % 2 == 0 else Color("#1D4F91"))


## A charm `r` px across hanging at `at` (its ring on top).
static func draw_charm(ci: CanvasItem, at: Vector2, charm: String, r: float) -> void:
	if charm == "":
		return
	ci.draw_arc(at + Vector2(0, -r * 0.95), r * 0.28, 0.0, TAU, 14, Color("#C9A43A"), maxf(1.4, r * 0.12), true)
	var gold := Color("#F2C230")
	var deep := Color("#B58A1E")
	var pts := PackedVector2Array()
	match charm:
		"coeur":
			for k in 36:
				var a := TAU * k / 36.0
				pts.append(at + Vector2(16.0 * pow(sin(a), 3.0), -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) / 17.0 * r * 0.75)
			gold = Color("#FF5E8A")
			deep = Color("#C2185B")
		"etoile":
			for k in 10:
				pts.append(at + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * (r * 0.75 if k % 2 == 0 else r * 0.33))
		"lune":
			for k in 25:
				var a := PI * 0.35 + PI * 1.3 * k / 24.0
				pts.append(at + Vector2.from_angle(a) * r * 0.72)
			for k in 25:
				var a := PI * 1.65 - PI * 1.3 * k / 24.0
				pts.append(at + Vector2(r * 0.26, 0) + Vector2.from_angle(a) * r * 0.55)
			gold = Color("#E8E4F7")
			deep = Color("#8E84B8")
		"fleur":
			for k in 5:
				var c := at + Vector2.from_angle(-PI / 2.0 + TAU * k / 5.0) * r * 0.4
				ci.draw_circle(c, r * 0.32, Color("#B58AD9"))
			ci.draw_circle(at, r * 0.24, Color("#FFD23F"))
			return
		"trefle":
			for k in 4:
				var c := at + Vector2.from_angle(PI / 4.0 + TAU * k / 4.0) * r * 0.32
				ci.draw_circle(c, r * 0.3, Color("#5BB85B"))
			ci.draw_line(at, at + Vector2(r * 0.2, r * 0.7), Color("#3E8E3E"), r * 0.1, true)
			return
	if pts.size() >= 3:
		var shade := PackedVector2Array()
		for p: Vector2 in pts:
			shade.append(p + Vector2(1.5, 2.0))
		ci.draw_colored_polygon(shade, Color(0, 0, 0, 0.2))
		ci.draw_colored_polygon(pts, gold)
		pts.append(pts[0])
		ci.draw_polyline(pts, deep, maxf(1.2, r * 0.08), true)
		ci.draw_circle(at + Vector2(-r * 0.2, -r * 0.2), r * 0.1, Color(1, 1, 1, 0.75))


## The finished bracelet as a loop seen from a little above, centred on `c`.
static func draw_loop(ci: CanvasItem, c: Vector2, data: Dictionary, s := 1.0) -> void:
	var rx := 120.0 * s
	var ry := 54.0 * s
	var count := 44
	# The back of the loop first, in its shade, then the front.
	for half in [0, 1]:
		for i in count:
			var a := TAU * i / count
			var front := sin(a) > 0.0
			if front != (half == 1):
				continue
			var p := c + Vector2(cos(a) * rx, sin(a) * ry)
			for col in W:
				var at := p + Vector2(0, (col - (W - 1) / 2.0) * 5.6 * s)
				var k := knot_color(data, i, col)
				if not front:
					k = k.darkened(0.3)
				draw_knot(ci, at, k, 1.0 if cos(a) > 0.0 else -1.0, s * 0.62)
	var word := str(data.get("word", ""))
	var font := ThemeDB.fallback_font
	for i in word.length():
		var a := PI / 2.0 - (i - (word.length() - 1) / 2.0) * 0.2
		var p := c + Vector2(cos(a) * rx, sin(a) * ry)
		var r := Rect2(p - Vector2(9, 9) * s, Vector2(18, 18) * s)
		ci.draw_rect(r, Color("#FFFDF7"))
		ci.draw_rect(r, Color("#B9B0A2"), false, 1.2 * s)
		var size := int(14 * s)
		var w := font.get_string_size(word[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		ci.draw_string(font, p + Vector2(-w / 2.0, 5.0 * s), word[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#E04F5F") if i % 2 == 0 else Color("#1D4F91"))
	draw_charm(ci, c + Vector2(rx * 0.55, ry * 0.84 + 26.0 * s), str(data.get("charm", "")), 26.0 * s)


## Her colours as the CharacterLook keeps them on a wrist ("#a,#b,#c").
static func wrist(data: Dictionary) -> String:
	return ",".join(data.colors)
