class_name ClassArt
extends RefCounted
## Inside the school, drawn as SVG at runtime: Madame Nadia's classroom (scenes/classe.gd) and the service de garde
## (scenes/service_de_garde.gd). Each canvas has its foot on the bottom edge (or hangs from its top), light from the upper left.
## Words (on the board, the frieze, the banner) are labels in the scenes: SVG text doesn't render in these textures.

const WOOD := "#B9824C"
const WOOD_DARK := "#8A5A30"
const WOOD_LIGHT := "#D9A56A"
const METAL := "#8E979C"
const INK := "#3A3A48"


static func _svg(w: float, h: float, body: String) -> ImageTexture:
	return PropArt.tex('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [w, h, w, h, body])


static func _rect(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


static func _shadow(cx: float, y: float, rx: float) -> String:
	return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="5" fill="#000" fill-opacity="0.18"/>' % [cx, y, rx]


# ── The classroom ───────────────────────────────────────────────

## Canvas w × h (hung): the green board in its oak frame, chalk dust wiped across it, the tray with its chalk and brush.
## The scene writes on it (labels).
static func blackboard(w: float, h: float) -> ImageTexture:
	var s := '<defs><linearGradient id="slate" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3F6B52"/>'
	s += '<stop offset="1" stop-color="#2C4F3C"/></linearGradient></defs>'
	s += _rect(0, 0, w, h - 18.0, WOOD, 'rx="4"')
	s += _rect(0, 0, w, 4.0, WOOD_LIGHT)
	s += _rect(12, 12, w - 24.0, h - 42.0, "url(#slate)")
	# Old wipes of chalk.
	for i in 5:
		var y := 30.0 + i * (h - 80.0) / 5.0
		s += '<path d="M%.1f %.1f q%.1f -14 %.1f 0" stroke="#FFFFFF" stroke-opacity="0.06" stroke-width="22" fill="none"/>' % [30.0 + i * 40.0, y, w * 0.3, w * 0.6]
	s += _rect(12, 12, w - 24.0, 5.0, "#000", 'fill-opacity="0.15"')
	# The tray, a few sticks of chalk and the brush.
	s += _rect(-6, h - 30.0, w + 12.0, 10.0, WOOD_DARK)
	s += _rect(-6, h - 30.0, w + 12.0, 3.0, WOOD_LIGHT)
	for k in 3:
		s += _rect(60.0 + k * 26.0, h - 36.0, 18.0, 5.0, ["#FFFFFF", "#FFD866", "#F7A9C4"][k], 'rx="2"')
	s += _rect(w - 110.0, h - 42.0, 52.0, 12.0, WOOD_LIGHT, 'rx="3"')
	s += _rect(w - 110.0, h - 32.0, 52.0, 4.0, "#3A3A3A")
	return _svg(w, h, s)


## Canvas 150 × 320 (foot on the floor): a classroom door in its painted casing: the oak leaf with its narrow wired window,
## the kick plate, the round handle.
static func door(casing: String) -> ImageTexture:
	var w := 150.0
	var h := 320.0
	var s := _rect(0, 0, w, h, casing)
	s += _rect(0, 0, 6, h, "#FFFFFF", 'fill-opacity="0.25"')
	s += _rect(14, 14, w - 28.0, h - 14.0, WOOD)
	s += _rect(14, 14, 6, h - 14.0, WOOD_LIGHT)
	s += _rect(w - 22.0, 14, 8, h - 14.0, WOOD_DARK)
	s += _rect(54, 36, 42, 110, "#3C2420")
	s += _rect(58, 40, 34, 102, "#9FC1D6")
	for k in 6:
		s += '<line x1="58" y1="%.1f" x2="92" y2="%.1f" stroke="#2E3B44" stroke-opacity="0.4" stroke-width="0.8"/>' % [44.0 + k * 17.0, 44.0 + k * 17.0]
	s += '<polygon points="60,44 76,44 60,80" fill="#FFFFFF" fill-opacity="0.3"/>'
	s += _rect(14, h - 50.0, w - 28.0, 50, "#C9CCCF")
	s += '<circle cx="%.1f" cy="%.1f" r="8" fill="#D9B860"/>' % [w - 36.0, h * 0.55]
	return _svg(w, h, s)


## Canvas 300 × 160: Madame Nadia's desk: an oak top on a drawer pedestal, her mug, a stack of notebooks, a red apple, the pot
## of pencils.
static func teacher_desk() -> ImageTexture:
	var w := 300.0
	var h := 160.0
	var s := _shadow(150, h - 4.0, 140)
	s += _rect(10, 64, w - 20.0, 14.0, WOOD, 'rx="3"')
	s += _rect(10, 64, w - 20.0, 4.0, WOOD_LIGHT)
	s += _rect(190, 78, 96, h - 84.0, WOOD_DARK)
	for k in 3:
		s += _rect(196, 86.0 + k * 22.0, 84, 18, WOOD)
		s += _rect(230, 93.0 + k * 22.0, 16, 4, "#E9D9B8")
	s += _rect(20, 78, 10, h - 84.0, WOOD_DARK)
	s += _rect(28, 78, 160, 8, "#000", 'fill-opacity="0.15"')
	# On the desk.
	for k in 4:
		s += _rect(36.0 + k * 2.0, 52.0 - k * 6.0, 70, 6, ["#4A6FA5", "#E04F5F", "#FFD23F", "#3E8E5A"][k], 'rx="1"')
	s += '<circle cx="146" cy="52" r="11" fill="#D9342B"/><circle cx="142" cy="48" r="4" fill="#F07A70"/>'
	s += '<path d="M146 41 q2 -6 6 -7" stroke="#5A3A22" stroke-width="2" fill="none"/><ellipse cx="153" cy="36" rx="5" ry="2.5" fill="#4E9A44"/>'
	s += _rect(184, 36, 22, 28, "#FFFFFF", 'rx="3" stroke="#C9C2B4" stroke-width="1.5"')
	s += '<path d="M206 42 q10 2 0 14" stroke="#C9C2B4" stroke-width="3" fill="none"/>'
	s += _rect(232, 40, 20, 24, "#E8812E", 'rx="2"')
	for k in 4:
		s += _rect(234.0 + k * 4.0, 22.0 + (k % 2) * 6.0, 3, 20, ["#FFD23F", "#4A6FA5", "#E04F5F", "#3E8E5A"][k])
	return _svg(w, h, s)


## Canvas 150 × 100: a pupil's desk seen from the side (she sits to its left, facing right): the top, the box under it with
## a book sticking out, the tubular legs; a pencil case and an open notebook on top.
static func pupil_desk(rng: RandomNumberGenerator) -> ImageTexture:
	var w := 150.0
	var h := 100.0
	var s := _shadow(75, h - 3.0, 66)
	s += _rect(6, 26, w - 12.0, 9.0, "#D9B98C", 'rx="2"')
	s += _rect(6, 26, w - 12.0, 3.0, "#EBD3AE")
	s += _rect(22, 35, w - 44.0, 22.0, "#7C8C96")
	s += _rect(28, 39, 40, 14, ["#E04F5F", "#4A6FA5", "#3E8E5A", "#FFD23F"][rng.randi_range(0, 3)])
	for x in [18.0, w - 24.0]:
		s += _rect(x, 35, 6, h - 40.0, METAL)
		s += _rect(x, 35, 2, h - 40.0, "#C3CACD")
	s += _rect(12, h - 8.0, 24, 4, "#5F6164", 'rx="2"')
	s += _rect(w - 36.0, h - 8.0, 24, 4, "#5F6164", 'rx="2"')
	s += _rect(40, 18, 46, 8, "#FFFFFF", 'stroke="#B8C4D0" stroke-width="1"')
	s += '<line x1="63" y1="18" x2="63" y2="26" stroke="#B8C4D0"/>'
	s += _rect(96, 18, 34, 8, ["#FF8A3D", "#7E57C2", "#1FB5C4", "#FFB3C7"][rng.randi_range(0, 3)], 'rx="4"')
	return _svg(w, h, s)


## Canvas 70 × 110: a pupil's chair seen from the side, its seat 46 px up, the back on the left (she faces right).
static func pupil_chair(color: String) -> ImageTexture:
	var w := 70.0
	var h := 110.0
	var s := _shadow(35, h - 3.0, 30)
	s += _rect(6, 4, 9, 54, color, 'rx="3"')
	s += _rect(6, 4, 3, 54, "#FFFFFF", 'fill-opacity="0.25"')
	s += _rect(6, h - 52.0, w - 10.0, 8.0, color, 'rx="3"')
	for x in [10.0, w - 14.0]:
		s += _rect(x, h - 44.0, 5, 40, METAL)
	return _svg(w, h, s)


## Canvas w × 330: the cubbies along the back wall: a wooden rack of pigeonholes with a hook under each, a coat, a scarf or a
## backpack on each hook (winter coats in winter), boots on the tray below.
static func cubbies(w: float, rng: RandomNumberGenerator) -> ImageTexture:
	var h := 330.0
	var n := int(w / 70.0)
	var cw := w / n
	var s := _shadow(w / 2.0, h - 4.0, w / 2.0)
	s += _rect(0, 0, w, 64, WOOD, 'rx="3"')
	s += _rect(0, 0, w, 4, WOOD_LIGHT)
	for i in n:
		var x := i * cw
		s += _rect(x + 4, 8, cw - 8, 50, "#6E4A2C")
		s += _rect(x + 8, 30, cw - 16, 26, ["#E04F5F", "#4A6FA5", "#FFD23F", "#3E8E5A", "#7E57C2"][rng.randi_range(0, 4)], 'rx="4"')
	s += _rect(0, 64, w, 10, WOOD_DARK)
	var coats := ["#E04F5F", "#4A6FA5", "#FF8A3D", "#3E8E5A", "#7E57C2", "#1FB5C4", "#FFB3C7", "#2E3440"]
	for i in n:
		var cx := i * cw + cw / 2.0
		s += '<circle cx="%.1f" cy="84" r="4" fill="#5F6164"/>' % cx
		var c: String = coats[rng.randi_range(0, coats.size() - 1)]
		if Season.is_winter() or rng.randf() < 0.5:
			s += _coat(cx, c, rng)
		else:
			s += _rect(cx - 16, 92, 32, 40, c, 'rx="8"')
			s += _rect(cx - 10, 100, 20, 14, "#000", 'fill-opacity="0.15" rx="4"')
	# The boot tray and the boots on it.
	s += _rect(0, h - 22.0, w, 12, "#5F6164", 'rx="3"')
	for i in n:
		if rng.randf() < 0.75:
			var bx := i * cw + 10.0
			var bc: String = ["#2E3440", "#E04F5F", "#4A6FA5", "#8D6E63"][rng.randi_range(0, 3)]
			for k in 2:
				s += '<path d="M%.1f %.1f l0 -34 l12 0 l0 22 l14 4 l0 8 z" fill="%s"/>' % [bx + k * 22.0, h - 22.0, bc]
	return _svg(w, h, s)


# A child's coat hung by its hood on the hook: the hood falling behind, the body with its zip and pockets, the sleeves hanging
# along it, lit from the left; a scarf thrown over it now and then in winter.
static func _coat(cx: float, c: String, rng: RandomNumberGenerator) -> String:
	var dark := "#" + Color(c).darkened(0.25).to_html(false)
	var light := "#" + Color(c).lightened(0.2).to_html(false)
	var s := '<path d="M%.1f 84 q-12 2 -12 14 q0 8 12 10 q12 -2 12 -10 q0 -12 -12 -14 z" fill="%s"/>' % [cx, dark]
	s += '<path d="M%.1f 98 q-16 0 -20 10 l-4 54 q12 4 24 4 q12 0 24 -4 l-4 -54 q-4 -10 -20 -10 z" fill="%s"/>' % [cx, c]
	s += '<path d="M%.1f 104 q-6 26 -4 58 l-6 0 q-2 -32 4 -56 z" fill="%s" fill-opacity="0.8"/>' % [cx - 14.0, light]
	for k in [-1.0, 1.0]:
		s += '<path d="M%.1f 106 q%.1f 20 %.1f 50 l%.1f 0 q%.1f -30 %.1f -50 z" fill="%s"/>' % [cx + k * 18.0, k * 6.0, k * 4.0, -k * 8.0, -k * 2.0, -k * 4.0, dark]
	s += '<line x1="%.1f" y1="100" x2="%.1f" y2="164" stroke="%s" stroke-width="2"/>' % [cx, cx, "#D9D9D9"]
	for k in [-1.0, 1.0]:
		s += _rect(cx + k * 9.0 - 5.0, 136, 10, 8, dark, 'rx="2"')
	if Season.is_winter() and rng.randf() < 0.6:
		var sc: String = ["#FFD23F", "#E04F5F", "#FFFFFF", "#1FB5C4"][rng.randi_range(0, 3)]
		s += '<path d="M%.1f 98 q8 4 16 0 l2 8 q-10 4 -20 0 z M%.1f 104 l6 0 l2 30 l-6 0 z" fill="%s"/>' % [cx - 8.0, cx + 2.0, sc]
	return s


## Canvas 340 × 210 (hung): the class sticker chart: a row per child (the names are labels in the scene), a gold star for each
## sticker. `stars`: how many each row has, Charlotte's row first.
static func sticker_chart(stars: Array) -> ImageTexture:
	var w := 340.0
	var h := 210.0
	var s := _rect(0, 0, w, h, "#FFFDF6", 'stroke="#4A6FA5" stroke-width="5" rx="6"')
	s += _rect(0, 0, w, 34, "#4A6FA5", 'rx="6"')
	var rows := stars.size()
	for r in rows:
		var y := 44.0 + r * (h - 54.0) / rows
		s += '<line x1="10" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#C9D3E6" stroke-width="1.5"/>' % [y - 4.0, w - 10.0, y - 4.0]
		var n := mini(int(stars[r]), 9)
		for k in n:
			var cx := 120.0 + k * 24.0
			var cy := y + 14.0
			var pts := ""
			for j in 10:
				var rr := 10.0 if j % 2 == 0 else 4.2
				var a := -PI / 2.0 + j * PI / 5.0
				pts += "%.1f,%.1f " % [cx + cos(a) * rr, cy + sin(a) * rr]
			s += '<polygon points="%s" fill="#FFD23F" stroke="#E0A526" stroke-width="1.2"/>' % pts
	return _svg(w, h, s)


## Canvas 260 × 200 (hung): the seasons poster: four panes, snow, a flower, a sun and a leaf, a little tree in each.
static func seasons_poster() -> ImageTexture:
	var w := 260.0
	var h := 200.0
	var s := _rect(0, 0, w, h, "#FFFFFF", 'stroke="#C9C2B4" stroke-width="2"')
	var panes := [["#DDEBF7", "#FFFFFF"], ["#E6F5DA", "#F7A9C4"], ["#FFF3C4", "#FFD23F"], ["#FBE3CF", "#E2662A"]]
	for k in 4:
		var x := 10.0 + (k % 2) * 122.0
		var y := 34.0 + (k / 2) * 82.0
		s += _rect(x, y, 116, 76, panes[k][0])
		s += _rect(x + 54, y + 40, 8, 30, "#8A5A30")
		if k == 0:
			s += '<path d="M%.1f %.1f l12 -26 l12 26 z" fill="#FFFFFF" stroke="#B8C8D8"/>' % [x + 46, y + 44]
			for j in 6:
				s += '<circle cx="%.1f" cy="%.1f" r="2.5" fill="#FFFFFF" stroke="#B8C8D8" stroke-width="0.6"/>' % [x + 12 + j * 18, y + 10 + (j % 3) * 9]
		else:
			s += '<circle cx="%.1f" cy="%.1f" r="20" fill="%s"/>' % [x + 58, y + 30, ["", "#7BC86C", "#4E9A44", "#E2662A"][k]]
			s += '<circle cx="%.1f" cy="%.1f" r="7" fill="%s"/>' % [x + 96, y + 16, panes[k][1]]
	s += _rect(0, 0, w, 26, "#3E8E5A")
	return _svg(w, h, s)


## Canvas w × 46 (hung): the number line from 0 to 20 along the top of the wainscot, a tick and a coloured dot for each.
static func number_line(w: float) -> ImageTexture:
	var s := _rect(0, 18, w, 6, "#4A6FA5", 'rx="3"')
	for k in 21:
		var x := 14.0 + k * (w - 28.0) / 20.0
		s += _rect(x - 1.5, 10, 3, 22, "#4A6FA5")
		s += '<circle cx="%.1f" cy="40" r="4" fill="%s"/>' % [x, ["#E04F5F", "#FFB42E", "#3E8E5A", "#7E57C2"][k % 4]]
	return _svg(w, 46, s)


## Canvas 80 × 70 (foot on the floor): a backpack left by a desk, slumped, its straps and front pocket.
static func backpack(color: String) -> ImageTexture:
	var dark := "#" + Color(color).darkened(0.3).to_html(false)
	var s := _shadow(40, 66, 34)
	s += '<path d="M12 64 q-6 -40 10 -52 q18 -10 36 0 q14 12 10 52 z" fill="%s"/>' % color
	s += '<path d="M20 64 q-2 -18 20 -20 q22 2 20 20 z" fill="%s"/>' % dark
	s += '<path d="M30 12 q10 -12 20 0" stroke="%s" stroke-width="4" fill="none"/>' % dark
	s += '<path d="M18 22 q-4 -6 4 -8" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="4" fill="none"/>'
	return _svg(80, 70, s)


## Canvas 280 × 200 (hung): the cork board and the children's drawings pinned to it.
static func cork_board(rng: RandomNumberGenerator) -> ImageTexture:
	var w := 280.0
	var h := 200.0
	var s := _rect(0, 0, w, h, WOOD, 'rx="4"')
	s += _rect(8, 8, w - 16.0, h - 16.0, "#C9965E")
	for i in 260:
		s += '<circle cx="%.1f" cy="%.1f" r="1" fill="#A87A44"/>' % [rng.randf_range(10.0, w - 10.0), rng.randf_range(10.0, h - 10.0)]
	var spots := [Vector2(20, 18), Vector2(110, 26), Vector2(196, 16), Vector2(30, 106), Vector2(124, 112), Vector2(198, 100)]
	for i in spots.size():
		var p: Vector2 = spots[i]
		var tilt := rng.randf_range(-6.0, 6.0)
		s += '<g transform="rotate(%.1f %.1f %.1f)">' % [tilt, p.x + 35.0, p.y + 36.0]
		s += _rect(p.x, p.y, 70, 72, "#FFFFFF")
		match i % 3:
			0:
				# A house under a sun.
				s += _rect(p.x + 18, p.y + 36, 30, 26, "#E04F5F")
				s += '<path d="M%.1f %.1f l17 -16 l17 16 z" fill="#4A6FA5"/>' % [p.x + 16, p.y + 36]
				s += '<circle cx="%.1f" cy="%.1f" r="8" fill="#FFD23F"/>' % [p.x + 56, p.y + 14]
			1:
				# A cat.
				s += '<circle cx="%.1f" cy="%.1f" r="16" fill="#FF8A3D"/>' % [p.x + 35, p.y + 40]
				s += '<path d="M%.1f %.1f l4 -12 l6 9 M%.1f %.1f l-4 -12 l-6 9" stroke="#FF8A3D" stroke-width="5" fill="#FF8A3D"/>' % [p.x + 22, p.y + 30, p.x + 48, p.y + 30]
				s += '<circle cx="%.1f" cy="%.1f" r="2" fill="%s"/><circle cx="%.1f" cy="%.1f" r="2" fill="%s"/>' % [p.x + 29, p.y + 38, INK, p.x + 41, p.y + 38, INK]
			2:
				# A rainbow over the grass.
				for k in 4:
					s += '<path d="M%.1f %.1f a%.1f %.1f 0 0 1 %.1f 0" stroke="%s" stroke-width="5" fill="none"/>' % [p.x + 10 + k * 5, p.y + 50, 25 - k * 5, 25 - k * 5, 50 - k * 10, ["#E04F5F", "#FFD23F", "#3E8E5A", "#4A6FA5"][k]]
				s += _rect(p.x + 4, p.y + 58, 62, 10, "#7BC86C")
		s += '</g>'
		s += '<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>' % [p.x + 35, p.y + 4, ["#E04F5F", "#4A6FA5", "#FFD23F"][i % 3]]
	return _svg(w, h, s)


## Canvas 110 × 190 (foot on the floor): the Québec flag on its little stand: the blue field, the white cross, a fleur-de-lis
## in each quarter.
static func quebec_flag() -> ImageTexture:
	var w := 110.0
	var h := 190.0
	var s := _shadow(16, h - 4.0, 16)
	s += _rect(12, 6, 5, h - 12.0, "#C9A35A")
	s += '<circle cx="14.5" cy="6" r="5" fill="#D9B860"/>'
	s += _rect(4, h - 12.0, 22, 8, "#5F6164", 'rx="3"')
	var x0 := 17.0
	var y0 := 12.0
	var fw := 88.0
	var fh := 58.0
	s += _rect(x0, y0, fw, fh, "#1E50A2")
	s += _rect(x0 + fw / 2.0 - 5.0, y0, 10, fh, "#FFFFFF")
	s += _rect(x0, y0 + fh / 2.0 - 5.0, fw, 10, "#FFFFFF")
	for q: Vector2 in [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]:
		var cx := x0 + fw * q.x
		var cy := y0 + fh * q.y
		s += '<path d="M%.1f %.1f q-3 4 0 8 q3 -4 0 -8 z M%.1f %.1f q-7 -2 -7 3 q3 -1 5 2 z M%.1f %.1f q7 -2 7 3 q-3 -1 -5 2 z" fill="#FFFFFF"/>' % [cx, cy - 6, cx - 1, cy, cx + 1, cy]
		s += _rect(cx - 4, cy + 3, 8, 2, "#FFFFFF")
	s += '<path d="M%.1f %.1f q20 6 44 0 q22 -6 44 0 l0 %.1f q-22 -6 -44 0 q-24 6 -44 0 z" fill="#000" fill-opacity="0.08"/>' % [x0, y0 + fh * 0.3, fh * 0.2]
	return _svg(w, h, s)


## Canvas 190 × 230 (foot on the floor): the class aquarium on its low cabinet: the glass, water, gravel, a plant, a little
## castle and a bubbler. The fish swim over it (the scene draws them).
static func aquarium() -> ImageTexture:
	var w := 190.0
	var h := 230.0
	var s := '<defs><linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9ED8EE"/>'
	s += '<stop offset="1" stop-color="#3E8AB0"/></linearGradient></defs>'
	s += _shadow(95, h - 4.0, 90)
	s += _rect(6, h - 100.0, w - 12.0, 96, WOOD, 'rx="3"')
	s += _rect(6, h - 100.0, w - 12.0, 4, WOOD_LIGHT)
	s += _rect(18, h - 86.0, w / 2.0 - 24.0, 72, WOOD_DARK)
	s += _rect(w / 2.0 + 6.0, h - 86.0, w / 2.0 - 24.0, 72, WOOD_DARK)
	s += _rect(14, 20, w - 28.0, h - 124.0, "url(#water)", 'stroke="#5F6164" stroke-width="4"')
	s += _rect(14, 14, w - 28.0, 10, "#2E3440", 'rx="2"')
	s += _rect(18, h - 122.0, w - 36.0, 14, "#C9A86A")
	for k in 12:
		s += '<circle cx="%.1f" cy="%.1f" r="2.5" fill="%s"/>' % [22.0 + k * 13.0, h - 116.0, ["#E04F5F", "#FFD23F", "#4A6FA5"][k % 3]]
	s += '<path d="M40 %.1f q-8 -30 4 -60 q6 30 -4 60 M48 %.1f q10 -24 2 -48" stroke="#3E8E5A" stroke-width="6" fill="none"/>' % [h - 118.0, h - 118.0]
	s += _rect(120, h - 150.0, 30, 32, "#B5AFA5")
	s += '<path d="M120 %.1f l0 -8 l6 0 l0 4 l6 0 l0 -4 l6 0 l0 4 l6 0 l0 -4 l6 0 l0 8 z" fill="#B5AFA5"/>' % (h - 150.0)
	s += _rect(130, h - 132.0, 10, 14, "#3A3A3A", 'rx="5"')
	s += _rect(18, 26, 10, h - 136.0, "#FFFFFF", 'fill-opacity="0.25"')
	return _svg(w, h, s)


## Canvas 230 × 130 (foot on the floor): the low bookcase of the reading corner, picture books of every colour.
static func bookcase(rng: RandomNumberGenerator) -> ImageTexture:
	var w := 230.0
	var h := 130.0
	var s := _shadow(115, h - 3.0, 110)
	s += _rect(4, 4, w - 8.0, h - 8.0, WOOD, 'rx="3"')
	s += _rect(4, 4, w - 8.0, 4, WOOD_LIGHT)
	for row in 2:
		var y := 14.0 + row * 56.0
		s += _rect(12, y, w - 24.0, 48, "#6E4A2C")
		var x := 14.0
		while x < w - 30.0:
			var bw := rng.randf_range(10.0, 18.0)
			var bh := rng.randf_range(32.0, 46.0)
			var c: String = ["#E04F5F", "#4A6FA5", "#FFD23F", "#3E8E5A", "#7E57C2", "#FF8A3D", "#1FB5C4", "#F7A9C4"][rng.randi_range(0, 7)]
			s += _rect(x, y + 48.0 - bh, bw - 1.0, bh, c)
			s += _rect(x + 2, y + 54.0 - bh, bw - 5.0, 3, "#FFFFFF", 'fill-opacity="0.5"')
			x += bw
	return _svg(w, h, s)


## Canvas 120 × 70 (foot on the floor): a fat beanbag to read on.
static func beanbag(color: String) -> ImageTexture:
	var s := _shadow(60, 66, 56)
	s += '<path d="M8 64 q-4 -40 30 -52 q24 -8 48 4 q30 16 26 48 z" fill="%s"/>' % color
	s += '<path d="M20 50 q20 -26 60 -24" stroke="#FFFFFF" stroke-opacity="0.3" stroke-width="6" fill="none"/>'
	return _svg(120, 70, s)


## Canvas 64 × 64: the gold star sticker Madame Nadia gives.
static func sticker() -> ImageTexture:
	var pts := ""
	for k in 10:
		var r := 28.0 if k % 2 == 0 else 12.0
		var a := -PI / 2.0 + k * PI / 5.0
		pts += "%.1f,%.1f " % [32.0 + cos(a) * r, 33.0 + sin(a) * r]
	var s := '<circle cx="32" cy="33" r="30" fill="#FFFFFF" stroke="#E0E0E0" stroke-width="2"/>'
	s += '<polygon points="%s" fill="#FFD23F" stroke="#E0A526" stroke-width="2.5" stroke-linejoin="round"/>' % pts
	s += '<circle cx="27" cy="31" r="2" fill="%s"/><circle cx="37" cy="31" r="2" fill="%s"/>' % [INK, INK]
	s += '<path d="M28 37 q4 4 8 0" stroke="%s" stroke-width="2" fill="none"/>' % INK
	return _svg(64, 64, s)


# ── The service de garde ────────────────────────────────────────

## Canvas 300 × 110 (foot on the floor): the craft table: paper of every colour, glue, scissors, a cup of crayons, glitter.
static func craft_table() -> ImageTexture:
	var w := 300.0
	var h := 110.0
	var s := _shadow(150, h - 3.0, 140)
	s += _rect(8, 44, w - 16.0, 10, "#F2E3C4", 'rx="3"')
	s += _rect(8, 44, w - 16.0, 3, "#FFF4DC")
	for x in [20.0, w - 30.0]:
		s += _rect(x, 54, 8, h - 58.0, "#4A6FA5")
	var papers := ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A", "#F7A9C4", "#FF8A3D"]
	for k in papers.size():
		s += '<g transform="rotate(%d %.1f 40)">' % [(k * 7) % 13 - 6, 40.0 + k * 34.0] + _rect(24.0 + k * 34.0, 38, 32, 7, papers[k]) + '</g>'
	s += _rect(240, 22, 18, 22, "#FFFFFF", 'rx="3" stroke="#C9C2B4"')
	s += _rect(244, 16, 10, 7, "#FF8A3D", 'rx="2"')
	for k in 4:
		s += _rect(214.0 + k * 5.0, 14.0 + (k % 2) * 5.0, 4, 26, ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A"][k])
	s += _rect(208, 30, 28, 14, "#7E57C2", 'rx="3"')
	s += '<circle cx="180" cy="38" r="6" fill="none" stroke="#E04F5F" stroke-width="3"/><circle cx="192" cy="38" r="6" fill="none" stroke="#E04F5F" stroke-width="3"/>'
	s += '<path d="M184 34 l24 -14 M188 34 l-18 -16" stroke="#9AA0A4" stroke-width="3"/>'
	return _svg(w, h, s)


## Canvas 170 × 240 (foot on the floor): the blocks on their mat: a tower `level` blocks high (1–6), more lying about.
static func block_tower(level: int) -> ImageTexture:
	var w := 170.0
	var h := 240.0
	var colors := ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A", "#FF8A3D", "#7E57C2"]
	var s := '<ellipse cx="85" cy="%.1f" rx="82" ry="9" fill="#7BC86C"/>' % (h - 8.0)
	for k in level:
		var y := h - 14.0 - (k + 1) * 30.0
		var x := 60.0 + (k % 2) * 6.0 - 3.0
		s += _rect(x, y, 46, 30, colors[k % colors.size()], 'stroke="#000" stroke-opacity="0.2" stroke-width="1.5"')
		s += _rect(x, y, 46, 5, "#FFFFFF", 'fill-opacity="0.3"')
	for k in 3:
		s += _rect(10.0 + k * 50.0 + (40.0 if k == 1 else 0.0), h - 28.0, 26, 18, colors[(k + 3) % colors.size()], 'stroke="#000" stroke-opacity="0.2" stroke-width="1.5"')
	return _svg(w, h, s)


## Canvas 240 × 140 (foot on the floor): the snack table: a jug of water, cups, a plate of apple slices and crackers.
static func snack_table() -> ImageTexture:
	var w := 240.0
	var h := 140.0
	var s := _shadow(120, h - 3.0, 112)
	s += _rect(8, 72, w - 16.0, 10, "#E9DCC0", 'rx="3"')
	s += _rect(8, 72, w - 16.0, 3, "#FFF4DC")
	for x in [22.0, w - 30.0]:
		s += _rect(x, 82, 8, h - 86.0, "#3E8E5A")
	s += _rect(30, 30, 30, 42, "#CFE8F4", 'rx="4" fill-opacity="0.8" stroke="#9AB8C8" stroke-width="2"')
	s += _rect(32, 44, 26, 26, "#8FCBF2", 'fill-opacity="0.6"')
	for k in 3:
		s += _rect(72.0 + k * 22.0, 54, 16, 18, ["#FFD23F", "#E04F5F", "#4A6FA5"][k], 'rx="2"')
	s += '<ellipse cx="180" cy="70" rx="40" ry="6" fill="#FFFFFF" stroke="#C9C2B4" stroke-width="2"/>'
	for k in 4:
		s += '<path d="M%.1f 68 a9 9 0 0 1 16 0 z" fill="#F4EBD0" stroke="#C0392B" stroke-width="2.5"/>' % (150.0 + k * 13.0)
	s += _rect(186, 58, 18, 8, "#E0B46A", 'rx="1"')
	s += _rect(196, 54, 18, 8, "#D9A85A", 'rx="1"')
	return _svg(w, h, s)


## Canvas 200 × 110 (foot on the floor): a low table with snakes and ladders laid out, the die and two pawns.
static func game_table() -> ImageTexture:
	var w := 200.0
	var h := 110.0
	var s := _shadow(100, h - 3.0, 92)
	s += _rect(10, 52, w - 20.0, 9, "#D9B98C", 'rx="3"')
	for x in [24.0, w - 32.0]:
		s += _rect(x, 61, 8, h - 65.0, "#E04F5F")
	s += '<polygon points="40,52 160,52 150,40 50,40" fill="#FFF4DC" stroke="#C9C2B4"/>'
	for k in 5:
		s += '<line x1="%.1f" y1="40" x2="%.1f" y2="52" stroke="#E0A526" stroke-width="1"/>' % [50.0 + k * 20.0, 40.0 + k * 24.0]
	s += '<path d="M70 50 q10 -8 20 -2 q10 6 22 -4" stroke="#3E8E5A" stroke-width="3" fill="none"/>'
	s += '<path d="M118 51 l14 -10 M124 51 l14 -10" stroke="#8A5A30" stroke-width="2"/>'
	s += _rect(166, 40, 12, 12, "#FFFFFF", 'rx="2" stroke="#9AA0A4"')
	s += '<circle cx="172" cy="46" r="1.6" fill="%s"/>' % INK
	s += '<circle cx="62" cy="40" r="5" fill="#E04F5F"/><circle cx="96" cy="38" r="5" fill="#4A6FA5"/>'
	return _svg(w, h, s)


## Canvas w × 60 (hung): a paper garland of triangular flags across the room.
static func garland(w: float) -> ImageTexture:
	var s := '<path d="M0 6 Q%.1f 30 %.1f 6" stroke="#5F6164" stroke-width="2" fill="none"/>' % [w / 2.0, w]
	var colors := ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A", "#F7A9C4", "#FF8A3D", "#7E57C2"]
	var n := int(w / 40.0)
	for k in n:
		var t := (k + 0.5) / n
		var x := w * t
		var y := 6.0 + 24.0 * 4.0 * t * (1.0 - t)
		s += '<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="%s"/>' % [x - 14, y, x + 14, y, x, y + 26, colors[k % colors.size()]]
	return _svg(w, 60, s)


## Canvas w × h (painted on the wall): a children's mural: a big rainbow over green hills, a sun, clouds.
static func mural(w: float, h: float) -> ImageTexture:
	var s := ""
	var colors := ["#E04F5F", "#FF8A3D", "#FFD23F", "#7BC86C", "#4A9AD8", "#7E57C2"]
	for k in colors.size():
		var r := w * 0.42 - k * 16.0
		s += '<path d="M%.1f %.1f a%.1f %.1f 0 0 1 %.1f 0" stroke="%s" stroke-width="16" fill="none" stroke-opacity="0.85"/>' % [w / 2.0 - r, h - 20.0, r, r * 0.8, 2.0 * r, colors[k]]
	s += '<path d="M0 %.1f q%.1f -60 %.1f -20 q%.1f -50 %.1f 0 l0 %.1f l-%.1f 0 z" fill="#8FCB72"/>' % [h - 10.0, w * 0.25, w * 0.5, w * 0.25, w * 0.5, 10.0, w]
	s += '<circle cx="%.1f" cy="40" r="28" fill="#FFD23F"/>' % (w * 0.86)
	for k in 8:
		var a := k * TAU / 8.0
		s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#FFB42E" stroke-width="5" stroke-linecap="round"/>' % [w * 0.86 + cos(a) * 36, 40 + sin(a) * 36, w * 0.86 + cos(a) * 48, 40 + sin(a) * 48]
	for c in [Vector2(0.14, 46), Vector2(0.5, 30)]:
		s += '<g fill="#FFFFFF"><circle cx="%.1f" cy="%.1f" r="16"/><circle cx="%.1f" cy="%.1f" r="22"/><circle cx="%.1f" cy="%.1f" r="15"/></g>' % [w * c.x - 20, c.y + 4, w * c.x, c.y - 4, w * c.x + 22, c.y + 4]
	return _svg(w, h, s)


## Canvas 260 × 200 (foot on the floor): the toy shelf: three rows of coloured bins, a teddy and a ball peeking out.
static func toy_shelf() -> ImageTexture:
	var w := 260.0
	var h := 200.0
	var s := _shadow(130, h - 3.0, 124)
	s += _rect(6, 6, w - 12.0, h - 12.0, WOOD_LIGHT, 'rx="3"')
	var bins := ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A", "#FF8A3D", "#7E57C2"]
	for r in 3:
		for k in 3:
			var x := 16.0 + k * 78.0
			var y := 16.0 + r * 60.0
			s += _rect(x, y + 14, 70, 40, bins[(r * 3 + k) % bins.size()], 'rx="4"')
			s += _rect(x, y + 14, 70, 6, "#FFFFFF", 'fill-opacity="0.25"')
			s += _rect(x + 26, y + 26, 18, 6, "#000", 'fill-opacity="0.2" rx="3"')
	s += '<circle cx="40" cy="22" r="10" fill="#B07A4A"/><circle cx="33" cy="14" r="4" fill="#B07A4A"/><circle cx="47" cy="14" r="4" fill="#B07A4A"/>'
	s += '<circle cx="190" cy="82" r="10" fill="#E04F5F"/><path d="M180 82 q10 -6 20 0" stroke="#FFFFFF" stroke-width="2" fill="none"/>'
	return _svg(w, h, s)


## Canvas 150 × 240 (foot on the floor): a painting easel with a child's painting on it and a tray of pots.
static func easel(rng: RandomNumberGenerator) -> ImageTexture:
	var w := 150.0
	var h := 240.0
	var s := _shadow(75, h - 3.0, 60)
	s += '<path d="M40 %.1f L70 10 L100 %.1f M70 10 L84 %.1f" stroke="%s" stroke-width="7" fill="none"/>' % [h - 4.0, h - 4.0, h - 4.0, WOOD_DARK]
	s += _rect(24, 30, 102, 110, "#FFFFFF", 'stroke="#C9C2B4" stroke-width="2"')
	for k in 5:
		s += '<path d="M%.1f %.1f q%.1f %.1f %.1f %.1f" stroke="%s" stroke-width="8" fill="none" stroke-linecap="round"/>' % [
			34.0 + rng.randf_range(0, 50), 44.0 + rng.randf_range(0, 70), rng.randf_range(-20, 20), rng.randf_range(-20, 20),
			rng.randf_range(20, 50), rng.randf_range(-10, 10), ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A", "#FF8A3D"][k]]
	s += _rect(20, 140, 110, 8, WOOD)
	for k in 4:
		s += _rect(28.0 + k * 24.0, 128, 14, 12, ["#E04F5F", "#FFD23F", "#4A6FA5", "#3E8E5A"][k], 'rx="2"')
	return _svg(w, h, s)


## Canvas 64 × 64: what she made at the craft table, by the season: a paper snowflake, a leaf, a tulip, a sun.
static func craft() -> ImageTexture:
	var s := ""
	match Season.current:
		"winter":
			for k in 3:
				var a := k * PI / 3.0
				s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#8FCBF2" stroke-width="7" stroke-linecap="round"/>' % [32 - cos(a) * 26, 32 - sin(a) * 26, 32 + cos(a) * 26, 32 + sin(a) * 26]
			s += '<circle cx="32" cy="32" r="8" fill="#FFFFFF" stroke="#8FCBF2" stroke-width="3"/>'
		"autumn":
			s += '<path d="M32 6 l6 14 l12 -4 l-4 12 l12 6 l-14 6 l4 12 l-16 -6 l-16 6 l4 -12 l-14 -6 l12 -6 l-4 -12 l12 4 z" fill="#E2662A" stroke="#B8402A" stroke-width="2"/>'
			s += '<line x1="32" y1="40" x2="32" y2="60" stroke="#8A5A30" stroke-width="3"/>'
		"spring":
			s += '<path d="M20 30 q0 -22 12 -22 q12 0 12 22 q-6 -6 -12 0 q-6 -6 -12 0 z" fill="#F7A9C4" stroke="#E04F5F" stroke-width="2"/>'
			s += '<line x1="32" y1="30" x2="32" y2="60" stroke="#3E8E5A" stroke-width="4"/>'
		_:
			s += '<circle cx="32" cy="32" r="14" fill="#FFD23F" stroke="#E0A526" stroke-width="2"/>'
			for k in 8:
				var a := k * TAU / 8.0
				s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#FF8A3D" stroke-width="4" stroke-linecap="round"/>' % [32 + cos(a) * 19, 32 + sin(a) * 19, 32 + cos(a) * 28, 32 + sin(a) * 28]
	return _svg(64, 64, s)


## Canvas 64 × 64: the snack on its paper plate: apple slices and crackers.
static func snack() -> ImageTexture:
	var s := '<ellipse cx="32" cy="40" rx="28" ry="12" fill="#FFFFFF" stroke="#C9C2B4" stroke-width="2"/>'
	for k in 3:
		s += '<path d="M%.1f 40 a8 8 0 0 1 15 0 z" fill="#F4EBD0" stroke="#C0392B" stroke-width="2.5"/>' % (10.0 + k * 9.0)
	s += _rect(38, 28, 16, 10, "#E0B46A", 'rx="1"')
	s += _rect(42, 22, 16, 10, "#D9A85A", 'rx="1"')
	return _svg(64, 64, s)
