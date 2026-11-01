class_name ShopArt
extends RefCounted
## Shop furniture drawn as SVG at runtime, for interiors like dépanneur Xin-Xin (the same idea as InteriorArt,
## one function per piece, canvas size noted). Everything generic: no brands or logos.


static func tex(w: float, h: float, body: String) -> ImageTexture:
	return InteriorArt.tex(w, h, body)


static func _bright(rng: RandomNumberGenerator) -> String:
	return ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC", "#FF7BA3", "#1FB5C4"][rng.randi_range(0, 7)]


## Canvas 210x440: the shop door from inside: glass behind a white grille, a bell on a spring above it.
static func door() -> ImageTexture:
	var s := '<rect x="0" y="10" width="210" height="430" fill="#E8E4DA" stroke="#A9A398" stroke-width="3"/>'
	s += '<rect x="20" y="30" width="170" height="410" fill="#F2F0EA" stroke="#B9B5AC" stroke-width="2.5"/>'
	s += '<rect x="34" y="44" width="142" height="300" fill="#BFD8E6"/>'
	s += '<path d="M40 50 L90 50 L40 200 Z" fill="#FFFFFF" opacity="0.35"/>'
	for y in range(52, 340, 22):
		s += '<rect x="34" y="%d" width="142" height="2.5" fill="#FFFFFF" opacity="0.9"/>' % y
	for x in range(42, 176, 22):
		s += '<rect x="%d" y="44" width="2.5" height="300" fill="#FFFFFF" opacity="0.9"/>' % x
	s += '<rect x="34" y="360" width="142" height="70" fill="#E8E4DA" stroke="#B9B5AC" stroke-width="2"/>'
	s += '<rect x="150" y="250" width="10" height="40" rx="4" fill="#9A968E"/>'
	s += '<rect x="64" y="120" width="82" height="40" rx="4" fill="#C8202A"/><rect x="70" y="126" width="70" height="28" rx="3" fill="none" stroke="#FFFFFF" stroke-width="2"/>'
	s += '<path d="M105 10 V0" stroke="#7E7A72" stroke-width="2"/><path d="M93 10 q12 -26 24 0 z" fill="#E3C26A" stroke="#A88A2E" stroke-width="2"/>'
	return tex(210, 440, s)


## Canvas 560x240: the counter: laminate front, the till and a lottery-ticket display on top, gum racks.
static func counter() -> ImageTexture:
	var s := '<rect x="0" y="70" width="560" height="22" fill="#D9CFC0" stroke="#A89A84" stroke-width="2"/>'
	s += '<rect x="10" y="92" width="540" height="148" fill="#C9A26E" stroke="#8A6A40" stroke-width="2"/>'
	for x in range(10, 550, 60):
		s += '<rect x="%d" y="100" width="52" height="132" fill="#D4AE78" stroke="#8A6A40" stroke-width="1"/>' % (x + 4)
	# Till.
	s += '<path d="M330 70 L340 30 H430 L440 70 Z" fill="#3A3F48" stroke="#22262C" stroke-width="2"/>'
	s += '<rect x="350" y="36" width="70" height="20" fill="#7FD4A0"/><rect x="356" y="42" width="40" height="8" fill="#2E6E44"/>'
	for i in 6:
		s += '<rect x="%d" y="60" width="10" height="6" fill="#C9CED6"/>' % (348 + i * 13)
	# Scratch tickets fanned out in a display.
	s += '<rect x="80" y="0" width="160" height="70" fill="#F4F2EC" stroke="#9A968E" stroke-width="2"/>'
	for i in 8:
		var c: String = ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC", "#FF7BA3", "#1FB5C4"][i]
		s += '<rect x="%d" y="8" width="16" height="54" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/>' % [88 + i * 19, c]
		s += '<circle cx="%d" cy="22" r="4" fill="#FFFFFF" opacity="0.8"/>' % (96 + i * 19)
	# Gum and candy-bar racks on the front.
	s += '<rect x="250" y="40" width="64" height="30" fill="#E8E4DA" stroke="#9A968E" stroke-width="1.5"/>'
	for i in 4:
		s += '<rect x="%d" y="46" width="12" height="20" rx="2" fill="%s"/>' % [254 + i * 15, ["#7CCB5A", "#FF7BA3", "#4FA3E0", "#FFD23F"][i]]
	s += '<rect x="470" y="46" width="70" height="24" rx="4" fill="#F2F2EF" stroke="#9A968E" stroke-width="1.5"/><circle cx="505" cy="58" r="7" fill="#E04F5F"/>'
	return tex(560, 240, s)


## Canvas 480x440: the candy wall: shelves of bright bags, jars of jellybeans and lollipops (sign in the game).
static func candy_wall() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := '<rect x="0" y="0" width="480" height="440" fill="#F4E6D2" stroke="#B5946A" stroke-width="3"/>'
	s += '<rect x="20" y="10" width="440" height="44" rx="8" fill="#FF7BA3" stroke="#C84A72" stroke-width="2"/>'
	for row in 4:
		var y := 90.0 + row * 88.0
		s += '<rect x="10" y="%s" width="460" height="10" fill="#B5946A"/>' % (y + 70)
		var x := 22.0
		while x < 450.0:
			var c := _bright(rng)
			if row % 2 == 0:
				s += '<rect x="%s" y="%s" width="30" height="62" rx="4" fill="%s" stroke="#FFFFFF" stroke-width="2"/>' % [x, y + 8, c]
				s += '<circle cx="%s" cy="%s" r="8" fill="#FFFFFF" opacity="0.6"/>' % [x + 15, y + 34]
				x += 36.0
			else:
				s += '<rect x="%s" y="%s" width="44" height="60" rx="10" fill="#E8F4FA" fill-opacity="0.8" stroke="#9AB8C8" stroke-width="2"/>' % [x, y + 10]
				for k in 9:
					s += '<circle cx="%s" cy="%s" r="5" fill="%s"/>' % [x + 10 + (k % 3) * 12, y + 30 + (k / 3) * 12, _bright(rng)]
				s += '<rect x="%s" y="%s" width="36" height="8" rx="3" fill="#E04F5F"/>' % [x + 4, y + 4]
				x += 52.0
	# A jar of lollipops on top.
	for i in 5:
		s += '<line x1="%s" y1="440" x2="%s" y2="400" stroke="#FFFFFF" stroke-width="3"/>' % [400 + i * 10, 396 + i * 12]
	return tex(480, 440, s)


## Canvas 380x340: a shelf unit of chip bags and boxes of crackers.
static func chips_shelf() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var s := '<rect x="0" y="0" width="380" height="340" fill="#E6E2D8" stroke="#9A968E" stroke-width="3"/>'
	for row in 3:
		var y := 20.0 + row * 106.0
		s += '<rect x="6" y="%s" width="368" height="10" fill="#B9B5AC"/>' % (y + 92)
		var x := 14.0
		while x < 352.0:
			var c := _bright(rng)
			s += '<path d="M%s %s q4 -8 20 -8 q16 0 20 8 l-2 72 q-18 6 -36 0 z" fill="%s" stroke="#FFFFFF" stroke-width="2"/>' % [x, y + 20, c]
			s += '<circle cx="%s" cy="%s" r="9" fill="#FFF3B0"/>' % [x + 20, y + 52]
			x += 44.0
	return tex(380, 340, s)


## Canvas 440x480: a drinks fridge with three glass doors, lit inside, bottles and cartons on the shelves.
static func drinks_fridge() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var s := '<rect x="0" y="0" width="440" height="480" fill="#D9DDE2" stroke="#8E949A" stroke-width="3"/>'
	s += '<rect x="10" y="8" width="420" height="30" fill="#2E5FB0"/>'
	for d in 3:
		var x := 14.0 + d * 140.0
		s += '<rect x="%s" y="46" width="132" height="420" fill="#EAF6FC" stroke="#8E949A" stroke-width="3"/>' % x
		for row in 4:
			var y := 60.0 + row * 100.0
			s += '<rect x="%s" y="%s" width="124" height="5" fill="#B9C9D2"/>' % [x + 4, y + 86]
			var bx := x + 10.0
			while bx < x + 120.0:
				var c: String = ["#FF8A3D", "#7CCB5A", "#FFFFFF", "#E04F5F", "#4FA3E0", "#FFD23F"][rng.randi_range(0, 5)]
				if row == 3:
					s += '<path d="M%s %s v-34 l6 -8 h12 l6 8 v34 z" fill="%s" stroke="#8E949A" stroke-width="1.5"/>' % [bx, y + 86, c]
					bx += 30.0
				else:
					s += '<rect x="%s" y="%s" width="16" height="44" rx="6" fill="%s" stroke="#8E949A" stroke-width="1"/><rect x="%s" y="%s" width="8" height="10" fill="#8E949A"/>' % [bx, y + 40, c, bx + 4, y + 30]
					bx += 22.0
		s += '<rect x="%s" y="220" width="6" height="60" rx="3" fill="#8E949A"/>' % (x + 118)
		s += '<path d="M%s 50 L%s 50 L%s 300 Z" fill="#FFFFFF" opacity="0.25"/>' % [x + 10, x + 50, x + 10]
	return tex(440, 480, s)


## Canvas 320x170: a chest freezer with a sliding glass lid full of ice pops and ice-cream sandwiches.
static func freezer() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var s := '<rect x="0" y="40" width="320" height="130" rx="10" fill="#F4F6F8" stroke="#9AA8B4" stroke-width="3"/>'
	s += '<rect x="12" y="52" width="296" height="40" fill="#2E5FB0"/>'
	s += '<path d="M0 40 L20 0 H300 L320 40 Z" fill="#D6EAF5" fill-opacity="0.85" stroke="#9AA8B4" stroke-width="3"/>'
	for i in 14:
		var x := 30.0 + i * 19.0
		var c: String = ["#E04F5F", "#FFD23F", "#7CCB5A", "#FF8A3D", "#C084FC", "#4FA3E0"][rng.randi_range(0, 5)]
		s += '<rect x="%s" y="%s" width="14" height="22" rx="5" fill="%s"/><rect x="%s" y="%s" width="4" height="8" fill="#E8D2A8"/>' % [x, 8 + (i % 2) * 10, c, x + 5, 30 + (i % 2) * 10]
	s += '<path d="M40 4 L120 4 L60 38 Z" fill="#FFFFFF" opacity="0.35"/>'
	return tex(320, 170, s)


## Canvas 130x210: a wire rack of newspapers and magazines.
static func newspaper_rack() -> ImageTexture:
	var s := '<rect x="10" y="20" width="110" height="180" fill="none" stroke="#5A5F63" stroke-width="4"/>'
	for i in 3:
		var y := 30.0 + i * 58.0
		s += '<rect x="18" y="%s" width="94" height="50" fill="#F4F2EC" stroke="#9A968E" stroke-width="1.5"/>' % y
		s += '<rect x="24" y="%s" width="60" height="8" fill="#2B2B2B"/><rect x="24" y="%s" width="40" height="18" fill="%s"/>' % [y + 6, y + 20, ["#4FA3E0", "#E04F5F", "#7CCB5A"][i]]
	s += '<path d="M10 200 l-6 10 M120 200 l6 10" stroke="#5A5F63" stroke-width="4"/>'
	return tex(130, 210, s)


## Canvas 200x140: an autumn display: a crate of little pumpkins and a cauldron of Halloween candy.
static func halloween_display() -> ImageTexture:
	var s := '<rect x="4" y="70" width="110" height="66" fill="#A0703E" stroke="#6E4E32" stroke-width="2"/>'
	for p in [[30, 66], [60, 60], [90, 66], [44, 48], [76, 46]]:
		s += '<ellipse cx="%s" cy="%s" rx="16" ry="12" fill="#F28C28" stroke="#A84E10" stroke-width="1.5"/><path d="M%s %s q2 -6 5 -7" stroke="#5A6B2A" stroke-width="3" fill="none"/>' % [p[0], p[1], p[0], p[1] - 11]
	s += '<path d="M120 80 Q120 136 158 136 Q196 136 196 80 Z" fill="#2B2B2B" stroke="#111111" stroke-width="2"/><rect x="116" y="74" width="84" height="10" rx="5" fill="#3A3A3A"/>'
	for c in [[134, 72, "#FF8A3D"], [150, 66, "#C084FC"], [166, 70, "#7CCB5A"], [182, 68, "#FFD23F"]]:
		s += '<rect x="%s" y="%s" width="14" height="10" rx="3" fill="%s"/>' % c
	return tex(200, 140, s)


## Canvas 160x200: a lottery poster: stars and a big golden ball (the word is a label in the game).
static func lotto_poster() -> ImageTexture:
	var s := '<rect x="2" y="2" width="156" height="196" fill="#1D4F91" stroke="#16285C" stroke-width="3"/>'
	s += '<circle cx="80" cy="120" r="44" fill="#FFD23F" stroke="#C99410" stroke-width="3"/>'
	for st in [[30, 50], [130, 40], [24, 170], [138, 172], [80, 30]]:
		s += '<path d="M%s %s l4 9 l10 1 l-8 6 l3 10 l-9 -5 l-9 5 l3 -10 l-8 -6 l10 -1 z" fill="#FFF3B0"/>' % [st[0], st[1] - 10]
	return tex(160, 200, s)


## Canvas 64x64: a treat from the shop ("candy" a bag of jellies, "popsicle", "juice" a juice box, "lollipop").
static func treat(kind: String) -> ImageTexture:
	var s := ""
	match kind:
		"popsicle":
			s = '<rect x="20" y="6" width="24" height="38" rx="10" fill="#FF8A3D"/><rect x="20" y="6" width="24" height="14" rx="8" fill="#E04F5F"/><rect x="28" y="42" width="8" height="18" rx="2" fill="#E8D2A8"/>'
		"juice":
			s = '<rect x="16" y="14" width="32" height="44" rx="3" fill="#7CCB5A" stroke="#3E8E5A" stroke-width="2"/><circle cx="32" cy="38" r="9" fill="#FF8A3D"/><path d="M40 14 L44 2" stroke="#F4F2EC" stroke-width="3"/>'
		"slush":
			s = '<path d="M18 16 H46 L42 60 H22 Z" fill="#3D7FD0" stroke="#FFFFFF" stroke-width="2"/><rect x="16" y="10" width="32" height="8" rx="3" fill="#F4F2EC"/><path d="M36 10 L42 0" stroke="#E04F5F" stroke-width="3"/><path d="M22 30 q10 -6 20 0" stroke="#7FC4E0" stroke-width="3" fill="none"/>'
		"milk":
			s = '<path d="M14 18 q18 -10 36 0 l4 38 q-22 10 -44 0 z" fill="#FFFFFF" stroke="#C9D2D8" stroke-width="2"/><rect x="16" y="34" width="34" height="9" fill="#4FA3E0"/>'
		"chocolate":
			s = '<path d="M16 22 H48 L44 58 H20 Z" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2"/><rect x="14" y="16" width="36" height="8" rx="3" fill="#5A3A22"/><path d="M26 10 q4 -6 0 -10 M38 10 q4 -6 0 -10" stroke="#C9C2B4" stroke-width="2" fill="none"/>'
		"lollipop":
			s = '<circle cx="32" cy="24" r="18" fill="#FF7BA3"/><path d="M32 24 m-12 0 a12 12 0 1 1 24 0 a8 8 0 1 1 -16 0" stroke="#FFFFFF" stroke-width="4" fill="none"/><rect x="30" y="40" width="4" height="22" fill="#F4F2EC"/>'
		_:
			s = '<path d="M14 10 L50 10 L46 58 L18 58 Z" fill="#C084FC" stroke="#7E57C2" stroke-width="2"/><rect x="12" y="6" width="40" height="8" rx="3" fill="#7E57C2"/>'
			for p in [[26, 30, "#FFD23F"], [38, 34, "#7CCB5A"], [30, 44, "#E04F5F"], [40, 46, "#4FA3E0"]]:
				s += '<circle cx="%s" cy="%s" r="5" fill="%s"/>' % p
	return tex(64, 64, s)


## Canvas 640x300: the wall shelves behind the counter, crammed with small things (batteries, gum, candy boxes,
## soap, toothpaste, chargers), yellow price tags under each group.
static func back_shelves() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var s := '<rect x="0" y="0" width="640" height="300" fill="#D9D2C2" stroke="#9A8F78" stroke-width="3"/>'
	for row in 4:
		var y := 12.0 + row * 72.0
		s += '<rect x="4" y="%s" width="632" height="8" fill="#A89A80"/>' % (y + 56)
		var x := 12.0
		while x < 616.0:
			var w := rng.randf_range(14.0, 30.0)
			var h := rng.randf_range(24.0, 50.0)
			var c := _bright(rng)
			match rng.randi_range(0, 3):
				0:
					s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/>' % [x, y + 56 - h, w, h, c]
				1:
					s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="5" fill="%s"/><rect x="%.1f" y="%.1f" width="%.1f" height="6" fill="#FFFFFF" opacity="0.6"/>' % [x, y + 56 - h, w, h, c, x, y + 62 - h, w]
				2:
					for k in 3:
						s += '<rect x="%.1f" y="%.1f" width="7" height="18" rx="2" fill="%s" stroke="#2B2B2B" stroke-width="1"/>' % [x + k * 8, y + 38, c]
					w = 26.0
				_:
					s += '<path d="M%.1f %.1f q%.1f -8 %.1f 0 l-2 %.1f h-%.1f z" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/>' % [x, y + 56 - h, w / 2, w, h, w - 4, c]
			if rng.randf() < 0.45:
				s += '<rect x="%.1f" y="%.1f" width="16" height="9" fill="#FFD23F" stroke="#C99410" stroke-width="1"/>' % [x, y + 64]
			x += w + rng.randf_range(4.0, 9.0)
	return tex(640, 300, s)


## Canvas 440x200: a low freestanding gondola in the middle of the shop: three shelves of cans, boxes and bags,
## price tags, red "special" tags on the end.
static func gondola() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var s := '<rect x="0" y="0" width="440" height="200" fill="#E8E4DA" stroke="#9A968E" stroke-width="3"/>'
	s += '<rect x="0" y="188" width="440" height="12" fill="#7E7A72"/>'
	for row in 3:
		var y := 8.0 + row * 60.0
		s += '<rect x="4" y="%s" width="432" height="6" fill="#B9B5AC"/>' % (y + 52)
		var x := 10.0
		while x < 420.0:
			var c := _bright(rng)
			if rng.randf() < 0.5:
				s += '<rect x="%.1f" y="%.1f" width="18" height="34" rx="4" fill="%s" stroke="#8E949A" stroke-width="1"/><rect x="%.1f" y="%.1f" width="18" height="8" fill="#FFFFFF" opacity="0.5"/>' % [x, y + 18, c, x, y + 30]
				x += 22.0
			else:
				s += '<rect x="%.1f" y="%.1f" width="30" height="44" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/><circle cx="%.1f" cy="%.1f" r="7" fill="#FFFFFF" opacity="0.55"/>' % [x, y + 8, c, x + 15, y + 26]
				x += 34.0
		s += '<rect x="%s" y="%s" width="18" height="10" fill="#FFD23F"/><rect x="%s" y="%s" width="22" height="12" fill="#E0303A"/>' % [rng.randf_range(20, 380), y + 56, rng.randf_range(20, 380), y + 54]
	return tex(440, 200, s)


## Canvas 440x480: an open-front dairy cooler (lit), with Québec's 4 L milk bags, cartons, yogurts, eggs, butter.
static func milk_cooler() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var s := '<rect x="0" y="0" width="440" height="480" fill="#D9DDE2" stroke="#8E949A" stroke-width="3"/>'
	s += '<rect x="10" y="8" width="420" height="36" fill="#4FA3E0"/>'
	s += '<rect x="16" y="52" width="408" height="380" fill="#DCEAF3"/>'
	for row in 4:
		var y := 60.0 + row * 92.0
		s += '<rect x="16" y="%s" width="408" height="8" fill="#B9C9D2"/>' % (y + 82)
		var x := 24.0
		while x < 410.0:
			match row:
				0:
					s += '<path d="M%.1f %.1f q18 -10 36 0 l4 52 q-22 10 -44 0 z" fill="#FBFDFF" stroke="#7E95A8" stroke-width="2"/><rect x="%.1f" y="%.1f" width="36" height="10" fill="%s"/>' % [x, y + 28, x + 2, y + 50, ["#4FA3E0", "#E04F5F", "#7CCB5A"][rng.randi_range(0, 2)]]
					x += 50.0
				1:
					s += '<path d="M%.1f %.1f v-46 l8 -10 h16 l8 10 v46 z" fill="#FBFDFF" stroke="#7E95A8" stroke-width="2"/><rect x="%.1f" y="%.1f" width="32" height="14" fill="%s"/>' % [x, y + 80, x, y + 44, _bright(rng)]
					x += 40.0
				2:
					s += '<path d="M%.1f %.1f l4 -26 h20 l4 26 z" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/><rect x="%.1f" y="%.1f" width="24" height="5" fill="#FFFFFF"/>' % [x, y + 80, _bright(rng), x + 2, y + 54]
					x += 32.0
				_:
					s += '<rect x="%.1f" y="%.1f" width="60" height="22" rx="3" fill="#E8D9B8" stroke="#B9A47A" stroke-width="1.5"/>' % [x, y + 58]
					for k in 5:
						s += '<circle cx="%.1f" cy="%.1f" r="4.5" fill="#F6EBD8"/>' % [x + 8 + k * 11, y + 58]
					x += 68.0
	s += '<rect x="16" y="440" width="408" height="32" fill="#7E8A94"/>'
	for x in range(24, 420, 10):
		s += '<rect x="%d" y="446" width="4" height="20" fill="#5E6A74"/>' % x
	s += '<rect x="16" y="52" width="408" height="10" fill="#FFFFFF" opacity="0.9"/>'
	return tex(440, 480, s)


## Canvas 220x320: a slush machine on its stainless cabinet: two clear bowls (blue, red) with taps. The swirling
## inside is drawn by the scene on top of it.
static func slush_machine() -> ImageTexture:
	var s := '<rect x="10" y="190" width="200" height="130" fill="#C9CED6" stroke="#8E949A" stroke-width="3"/>'
	s += '<rect x="20" y="200" width="180" height="40" fill="#E8EDF2"/>'
	for i in 2:
		var x := 22.0 + i * 92.0
		s += '<rect x="%s" y="40" width="84" height="120" rx="20" fill="%s" fill-opacity="0.85" stroke="#8E949A" stroke-width="3"/>' % [x, ["#3D7FD0", "#E0303A"][i]]
		s += '<rect x="%s" y="150" width="84" height="40" fill="#5E6A74"/><rect x="%s" y="160" width="20" height="26" rx="4" fill="#2B2B2B"/>' % [x, x + 32]
		s += '<path d="M%s 48 L%s 48 L%s 120 Z" fill="#FFFFFF" opacity="0.35"/>' % [x + 10, x + 30, x + 10]
	s += '<rect x="14" y="20" width="192" height="24" rx="8" fill="#F4F2EC" stroke="#8E949A" stroke-width="2"/>'
	return tex(220, 320, s)


## Canvas 280x280: the coffee and hot-chocolate corner: a brewer with its carafes, stacks of cups and lids.
static func coffee_station() -> ImageTexture:
	var s := '<rect x="0" y="150" width="280" height="130" fill="#8A6440" stroke="#5E4228" stroke-width="2"/>'
	s += '<rect x="0" y="140" width="280" height="14" fill="#C9B48A"/>'
	s += '<rect x="20" y="20" width="120" height="120" rx="6" fill="#2B2B2B"/><rect x="30" y="32" width="100" height="30" fill="#5E6A74"/>'
	for i in 2:
		s += '<path d="M%s 96 h34 l-4 40 h-26 z" fill="#3E2A1E" fill-opacity="0.85" stroke="#C9CED6" stroke-width="2"/><rect x="%s" y="90" width="34" height="8" fill="#E04F5F"/>' % [36 + i * 52, 36 + i * 52]
	for i in 3:
		s += '<path d="M%s 140 l4 -60 h20 l4 60 z" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="1.5"/>' % (160 + i * 36)
	return tex(280, 280, s)


## Canvas 220x360: a wire rack of sliced bread and buns in their bags.
static func bread_rack() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var s := '<rect x="10" y="10" width="200" height="340" fill="none" stroke="#5A5F63" stroke-width="4"/>'
	for row in 4:
		var y := 20.0 + row * 82.0
		s += '<rect x="10" y="%s" width="200" height="4" fill="#5A5F63"/>' % (y + 72)
		for k in 3:
			var x := 18.0 + k * 64.0
			s += '<rect x="%s" y="%s" width="58" height="50" rx="14" fill="#FBF7EE" stroke="#C9C2B4" stroke-width="1.5"/><rect x="%s" y="%s" width="58" height="14" fill="%s"/>' % [x, y + 22, x, y + 40, _bright(rng)]
			s += '<rect x="%s" y="%s" width="36" height="24" rx="10" fill="#D9A04A" opacity="0.6"/>' % [x + 11, y + 28]
	s += '<path d="M10 350 l-8 10 M210 350 l8 10" stroke="#5A5F63" stroke-width="4"/>'
	return tex(220, 360, s)


## Canvas 150x340: a cash machine (screen, keypad, card slot); its sign is a label in the game.
static func atm() -> ImageTexture:
	var s := '<rect x="10" y="20" width="130" height="320" rx="10" fill="#3A4452" stroke="#22282F" stroke-width="3"/>'
	s += '<rect x="10" y="20" width="130" height="40" rx="10" fill="#1D4F91"/>'
	s += '<rect x="26" y="80" width="98" height="70" rx="4" fill="#7FD4F0"/><rect x="34" y="90" width="60" height="8" fill="#FFFFFF"/><rect x="34" y="106" width="80" height="6" fill="#FFFFFF" opacity="0.6"/>'
	for r in 4:
		for c in 3:
			s += '<rect x="%d" y="%d" width="22" height="14" rx="3" fill="#C9CED6"/>' % [34 + c * 28, 170 + r * 20]
	s += '<rect x="40" y="260" width="70" height="8" rx="3" fill="#111111"/><rect x="34" y="290" width="82" height="10" rx="3" fill="#111111"/>'
	return tex(150, 340, s)


## Canvas 120x120: the convex security mirror in a top corner, the shop reflected small and curved in it.
static func security_mirror() -> ImageTexture:
	var s := '<circle cx="60" cy="60" r="54" fill="#B9C9D2" stroke="#5E6A74" stroke-width="6"/>'
	s += '<path d="M20 70 Q60 40 100 70 L100 90 Q60 100 20 90 Z" fill="#E8E4DA" opacity="0.8"/>'
	s += '<rect x="40" y="58" width="40" height="16" fill="#C8202A" opacity="0.6"/>'
	s += '<path d="M30 34 Q50 18 74 22" stroke="#FFFFFF" stroke-width="6" fill="none" opacity="0.7" stroke-linecap="round"/>'
	return tex(120, 120, s)


## Canvas 240x170: the specials chalkboard (its words are labels in the game).
static func specials_board() -> ImageTexture:
	var s := '<rect x="0" y="0" width="240" height="170" fill="#A0703E" rx="6"/><rect x="10" y="10" width="220" height="150" fill="#2E3A34"/>'
	s += '<path d="M24 52 H216" stroke="#F4F2EC" stroke-width="2" opacity="0.5"/>'
	return tex(240, 170, s)


## Canvas 170x440: the grey metal back door to the stockroom, with a push bar ("PRIVÉ" is a label).
static func back_door() -> ImageTexture:
	var s := '<rect x="0" y="0" width="170" height="440" fill="#7E8A94" stroke="#5E6A74" stroke-width="3"/>'
	s += '<rect x="12" y="12" width="146" height="428" fill="#9AA6B0" stroke="#5E6A74" stroke-width="2"/>'
	s += '<rect x="24" y="220" width="120" height="16" rx="6" fill="#C9CED6" stroke="#5E6A74" stroke-width="1.5"/>'
	s += '<rect x="40" y="40" width="90" height="34" fill="#F4F2EC"/>'
	return tex(170, 440, s)
