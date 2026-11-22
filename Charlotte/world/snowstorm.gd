class_name Snowstorm
extends RefCounted
## The storm and the snow blower (quest "souffleuse", winter, after the Halloween evening; Julien): one night a storm blows
## (bedtime: "Le lendemain matin… quelle tempête !"), and in the morning
##   1. Papa asks her to help him shovel the front steps and goes out (the "!" over him indoors);
##   2. on 6e Avenue (`SnowRemoval`, in main.gd): snow heaped on her porch and steps, a long windrow along the curb, the city's
##      orange "no parking" signs out for the snow removal (no cars on the street). Papa shovels by the steps and gives her a
##      little shovel (`Carry` "pelle"); she clears each heap (`PILES`, `flags.souffleuse_cleared`);
##   3. the snow removal comes down the street: the big snow blower eating the windrow and blowing it into the dump truck
##      beside it; once it has gone by, Papa thanks her, takes the shovel and they go in: the quest is done.
## The step is `GameState.flags.souffleuse_step`.

const QUEST := "souffleuse"
const STEP := "souffleuse_step"
const CLEARED := "souffleuse_cleared"
const HEADING := "❄  La tempête"
## The heaps on her porch and steps, from the door down to the sidewalk.
const PILES := 4


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## The storm comes at bedtime: winter, and the quest free.
static func storm_tonight() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


## Papa is out front shovelling (not in the flat).
static func dad_outside() -> bool:
	return step() >= 2


static func cleared() -> Array:
	return GameState.flags.get(CLEARED, [])


static func clear_pile(i: int) -> void:
	var now := cleared().duplicate()
	if i not in now:
		now.append(i)
	GameState.flags[CLEARED] = now


static func all_cleared() -> bool:
	return cleared().size() >= PILES


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(CLEARED)


static func hint() -> String:
	match step():
		1:
			return "Toute une tempête cette nuit ! Papa a besoin de toi : va le voir dans le salon."
		2:
			if not Carry.has("pelle"):
				return "Papa pellette devant la maison, sur la 6e Avenue. Va chercher ta petite pelle !"
			return "Déneige l'escalier et le perron avec ta pelle (%d tas sur %d)." % [cleared().size(), PILES]
		3:
			return "La souffleuse arrive ! Regarde-la passer avec Papa."
	return str(Quests.ALL[QUEST].hint)


# ── Pictures ────────────────────────────────────────────────

## Canvas 520 × 320: the city's snow blower seen from the side, going left: the auger in its housing at the front, the tall
## chute bent back over the cab to blow the snow into the truck beside it, the yellow body, the cab, the orange beacon; its
## tyres on the bottom edge. The chute's mouth is at `CHUTE`.
const BLOWER_SIZE := Vector2(520, 320)
const CHUTE := Vector2(196, 20)
static func blower() -> ImageTexture:
	var s := '<defs><linearGradient id="by" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFC233"/><stop offset="1" stop-color="#D98A00"/></linearGradient>'
	s += '<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9FD6F2"/><stop offset="1" stop-color="#3E6E8E"/></linearGradient></defs>'
	# The chute, behind the cab: up from the housing and bent back, its hood turned toward the truck.
	s += '<path d="M84 196 L104 196 L150 40 L130 34 Z" fill="#E09A00" stroke="#7A5200" stroke-width="3" stroke-linejoin="round"/>'
	s += '<path d="M126 36 Q140 6 186 10 L206 30 Q172 26 152 44 Z" fill="#F2A900" stroke="#7A5200" stroke-width="3" stroke-linejoin="round"/>'
	s += '<path d="M112 150 L140 64" stroke="#FFD27A" stroke-width="4" opacity="0.7"/>'
	# The chassis and the engine at the back, its grille and exhaust.
	s += '<path d="M110 190 H500 Q512 190 512 202 V262 H110 Z" fill="url(#by)" stroke="#7A5200" stroke-width="3"/>'
	s += '<path d="M384 128 H496 Q508 128 508 140 V192 H384 Z" fill="url(#by)" stroke="#7A5200" stroke-width="3"/>'
	for i in 6:
		s += '<path d="M%s 140 V182" stroke="#7A5200" stroke-width="3" opacity="0.55"/>' % (400 + i * 16)
	s += '<rect x="470" y="70" width="12" height="62" rx="3" fill="#3A3A3A"/><rect x="466" y="64" width="20" height="10" rx="3" fill="#2A2A2A"/>'
	# Black and yellow stripes across the back.
	for i in 5:
		s += '<path d="M%s 232 l14 -26 h12 l-14 26 Z" fill="#1E1E1E"/>' % (440 + i * 14)
	# The cab: glass all round, its roof, the beacon.
	s += '<path d="M224 192 V84 Q224 70 238 70 H360 Q374 70 374 84 V192 Z" fill="url(#by)" stroke="#7A5200" stroke-width="3"/>'
	s += '<path d="M236 82 H306 V140 H236 Z" fill="url(#bg)" stroke="#2E2E2E" stroke-width="3"/>'
	s += '<path d="M314 82 H362 V140 H314 Z" fill="url(#bg)" stroke="#2E2E2E" stroke-width="3"/>'
	s += '<path d="M244 90 L270 90 L248 128 Z" fill="#FFFFFF" opacity="0.35"/>'
	s += '<rect x="216" y="62" width="168" height="12" rx="4" fill="#C77E00" stroke="#7A5200" stroke-width="2"/>'
	s += '<path d="M282 62 Q282 40 300 40 Q318 40 318 62 Z" fill="#FF7A1A" stroke="#B34A00" stroke-width="2"/>'
	s += '<path d="M290 58 Q292 46 300 46" stroke="#FFE0A0" stroke-width="3" fill="none"/>'
	# The step and grab rail up to the cab.
	s += '<path d="M250 196 V236 M250 214 H280" stroke="#3A3A3A" stroke-width="4"/>'
	s += '<path d="M220 100 V180" stroke="#3A3A3A" stroke-width="4" stroke-linecap="round"/>'
	# The housing at the front: the auger turning inside, the scraper blade under it.
	s += '<path d="M6 186 Q6 172 20 172 H124 V296 H18 Q6 296 6 284 Z" fill="#E09A00" stroke="#7A5200" stroke-width="3"/>'
	s += '<path d="M16 184 H116 V284 H16 Z" fill="#3A2E22"/>'
	for i in 7:
		var x := 10.0 + i * 16.0
		s += '<path d="M%s 186 L%s 282" stroke="#C9C9C9" stroke-width="6" stroke-linecap="round" opacity="0.85"/>' % [x + 14.0, x - 6.0]
	s += '<rect x="58" y="186" width="16" height="96" fill="#7A7A7A"/>'
	s += '<path d="M0 290 H130 V302 H6 Z" fill="#6A6A6A" stroke="#2E2E2E" stroke-width="2"/>'
	s += '<path d="M118 236 H140" stroke="#3A3A3A" stroke-width="10"/>'
	# Two big tyres.
	for x in [190.0, 420.0]:
		s += '<circle cx="%s" cy="270" r="48" fill="#1E1E1E"/><circle cx="%s" cy="270" r="22" fill="#B8B8B8" stroke="#555" stroke-width="3"/>' % [x, x]
		for i in 10:
			var a := TAU * i / 10.0
			s += '<path d="M%s %s L%s %s" stroke="#3A3A3A" stroke-width="5"/>' % [x + cos(a) * 36.0, 270.0 + sin(a) * 36.0, x + cos(a) * 47.0, 270.0 + sin(a) * 47.0]
		s += '<path d="M%s 228 Q%s 210 %s 228" stroke="#C77E00" stroke-width="10" fill="none"/>' % [x - 56.0, x, x + 56.0]
	return InteriorArt.tex(BLOWER_SIZE.x, BLOWER_SIZE.y, s)


## Canvas 600 × 320: the dump truck that drives beside the blower, going left: orange cab, the steel box already heaped with
## snow, three axles; tyres on the bottom edge.
const TRUCK_SIZE := Vector2(600, 320)
static func truck() -> ImageTexture:
	var s := '<defs><linearGradient id="tb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9B2BA"/><stop offset="1" stop-color="#6E7780"/></linearGradient>'
	s += '<linearGradient id="tc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF8C2A"/><stop offset="1" stop-color="#D2600A"/></linearGradient></defs>'
	# The box, its ribs, the snow heaped over its rim.
	s += '<path d="M176 56 H592 V236 H176 Z" fill="url(#tb)" stroke="#3E454C" stroke-width="3"/>'
	for i in 7:
		s += '<path d="M%s 56 V236" stroke="#59616A" stroke-width="5"/>' % (220 + i * 56)
	s += '<path d="M176 70 H592" stroke="#C9D0D6" stroke-width="3"/>'
	s += '<path d="M176 58 Q220 30 270 46 Q320 20 380 42 Q440 22 500 44 Q550 30 592 56 Z" fill="#F4F8FC" stroke="#C7D5E6" stroke-width="2"/>'
	# The cab and its windows, the beacon on the roof.
	s += '<path d="M24 236 V120 Q24 84 54 76 L130 64 Q166 62 168 96 V236 Z" fill="url(#tc)" stroke="#7A3A06" stroke-width="3"/>'
	s += '<path d="M42 124 Q44 96 66 90 L120 82 Q140 82 140 104 V132 H42 Z" fill="#7FB4D6" stroke="#2E2E2E" stroke-width="3"/>'
	s += '<path d="M54 120 L70 96 L90 94 L66 124 Z" fill="#FFFFFF" opacity="0.35"/>'
	s += '<path d="M90 60 Q90 42 106 42 Q122 42 122 60 Z" fill="#FF7A1A" stroke="#B34A00" stroke-width="2"/>'
	s += '<rect x="14" y="200" width="40" height="22" rx="4" fill="#3A3A3A"/><rect x="18" y="176" width="16" height="14" rx="3" fill="#FFE9A8"/>'
	s += '<path d="M96 150 H130" stroke="#7A3A06" stroke-width="3"/>'
	# The chassis and three axles.
	s += '<rect x="20" y="232" width="572" height="18" fill="#2E2E2E"/>'
	for x in [96.0, 420.0, 520.0]:
		s += '<circle cx="%s" cy="272" r="46" fill="#1E1E1E"/><circle cx="%s" cy="272" r="20" fill="#B8B8B8" stroke="#555" stroke-width="3"/>' % [x, x]
		for i in 8:
			var a := TAU * i / 8.0
			s += '<circle cx="%s" cy="%s" r="2.6" fill="#555"/>' % [x + cos(a) * 13.0, 272.0 + sin(a) * 13.0]
	return InteriorArt.tex(TRUCK_SIZE.x, TRUCK_SIZE.y, s)


## Canvas 60 × 150: the city's temporary orange sign for the snow removal, on its stake: the red P struck out (the words go on
## as a label); its stake's foot on the bottom edge.
static func sign() -> ImageTexture:
	var s := '<rect x="27" y="40" width="6" height="110" fill="#8A6A44" stroke="#5A4228" stroke-width="1.5"/>'
	s += '<rect x="4" y="4" width="52" height="74" rx="4" fill="#FF7A00" stroke="#1E1E1E" stroke-width="2.5"/>'
	s += '<circle cx="30" cy="26" r="15" fill="#FFFFFF" stroke="#D42020" stroke-width="4"/>'
	s += '<path d="M25 35 V17 H32 Q38 17 38 23 Q38 29 32 29 H25" fill="none" stroke="#1E1E1E" stroke-width="3.5"/>'
	s += '<path d="M19 15 L41 37" stroke="#D42020" stroke-width="4"/>'
	s += '<path d="M8 76 H52" stroke="#C25A00" stroke-width="2"/>'
	return InteriorArt.tex(60, 150, s)


## Canvas 70 × 110 (`big`: Papa's, 90 × 170): a snow shovel, its scoop at the bottom. Hers is a red plastic one with a yellow
## handle; his a wide black scoop on a wooden shaft.
## A shovel to put in someone's hands: the picture, plus what `Character` reads to hold it properly: `grips` (where the back hand and
## the front hand go, in the shovel's own space: the top of the shaft and a little lower), `rest_rot` (how it is carried, the scoop
## forward and down) and `swing` (how much further the scoop dips on each stroke, with `Character.pet`).
static func shovel_node(big := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = shovel(big)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var h := 170.0 if big else 110.0
	var oy := 30.0 if big else 26.0
	s.scale = Vector2.ONE * (1.5 if big else 1.4)
	s.offset = Vector2(0, oy)
	s.rotation = SHOVEL_REST
	s.set_meta("rest_rot", SHOVEL_REST)
	s.set_meta("swing", -0.9)
	s.set_meta("grips", [Vector2(0, 11.0 - h / 2.0 + oy), Vector2(0, (66.0 if big else 46.0) - h / 2.0 + oy)])
	return s


const SHOVEL_REST := -0.38


static func shovel(big := false) -> ImageTexture:
	var w := 90.0 if big else 70.0
	var h := 170.0 if big else 110.0
	var shaft := "#B07A44" if big else "#F2C230"
	var scoop := "#2A2A2A" if big else "#E5383B"
	var s := '<rect x="%s" y="8" width="8" height="%s" rx="3" fill="%s" stroke="#00000055" stroke-width="1.5"/>' % [w / 2.0 - 4.0, h - 50.0, shaft]
	s += '<path d="M%s 14 h20 v-8 h-20 Z" fill="%s" stroke="#00000055" stroke-width="1.5"/>' % [w / 2.0 - 10.0, shaft]
	s += '<path d="M6 %s H%s L%s %s Q%s %s %s %s H%s Q6 %s 6 %s Z" fill="%s" stroke="#00000066" stroke-width="2"/>' % [h - 46.0, w - 6.0, w - 6.0, h - 12.0, w - 6.0, h - 4.0, w - 14.0, h - 4.0, 14.0, h - 4.0, h - 12.0, scoop]
	s += '<path d="M12 %s H%s" stroke="#FFFFFF" stroke-width="2" opacity="0.35"/>' % [h - 40.0, w - 12.0]
	return InteriorArt.tex(w, h, s)
