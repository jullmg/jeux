class_name CostumeArt
extends RefCounted
## Halloween costumes. One `look.costume` id dresses the whole puppet: `ALL[id]` says what clothes to put on (the ordinary
## wardrobe fields, so the torso and legs draw themselves as usual) and which extra pieces to add — headwear (through
## `CharacterArt._hat()`), a cape and wings behind her, a tail at her hip, face paint over her eyes.
##
## A NEW costume = one line in `ALL` (and, if it needs a piece nobody has yet, one case in `hat`, `cape`, `wings`, `tail`
## or `mask`). Nothing else: the wardrobe lists `ALL`, and `apply()` dresses her.

## Where each extra piece hangs on the body, in the torso's own units (its canvas is 130 x 152 before the rig's scale).
const CAPE_CANVAS := Vector2(240, 230)
const CAPE_PIVOT := Vector2(120, 14)
const WINGS_CANVAS := Vector2(260, 200)
const WINGS_PIVOT := Vector2(130, 46)
const TAIL_CANVAS := Vector2(170, 160)
## The root of the tail, at her hip. On the right of the canvas, because the shapes are drawn curling to the
## right and then mirrored (see `tail`).
const TAIL_PIVOT := Vector2(144, 44)

## Every costume: `name` is what the wardrobe shows. The clothing keys are ordinary `CharacterLook` fields; the rest are the
## extra pieces. `keep_hair` leaves her own hair showing under the headwear (a hood hides it by itself).
const ALL := {
	"chat": {
		"name": "Chat noir", "outfit": "hoodie", "outfit_color": "#2B2B33", "accent_color": "#FF9DBB", "pattern": "none",
		"legwear": "tights", "legwear_color": "#2B2B33", "shoes": "boot", "shoe_color": "#2B2B33",
		"hat": "cat_ears", "hat_color": "#2B2B33", "tail": "cat", "tail_color": "#2B2B33", "mask": "whiskers",
	},
	"sorciere": {
		"name": "Sorcière", "outfit": "dress", "outfit_color": "#4B2E73", "accent_color": "#F2C230", "pattern": "stars",
		"legwear": "tights", "legwear_color": "#2B2B33", "shoes": "boot", "shoe_color": "#2B2B33",
		"hat": "witch", "hat_color": "#2B2B33", "cape": "plain", "cape_color": "#4B2E73", "cape_lining": "#2B2B33",
	},
	"fantome": {
		"name": "Fantôme", "outfit": "hoodie", "outfit_color": "#F4F2EC", "accent_color": "#D9D4C8", "pattern": "none",
		"legwear": "pants", "legwear_color": "#F4F2EC", "shoes": "sneaker", "shoe_color": "#F4F2EC",
		"hat": "ghost", "hat_color": "#F7F5EF", "cape": "plain", "cape_color": "#F7F5EF", "cape_lining": "#DCD6C8",
		"mask": "ghost",
	},
	"citrouille": {
		"name": "Citrouille", "outfit": "sweater", "outfit_color": "#E8812E", "accent_color": "#8A4A14", "pattern": "pumpkin",
		"legwear": "tights", "legwear_color": "#2E6B32", "shoes": "boot", "shoe_color": "#5E4228",
		"hat": "pumpkin", "hat_color": "#2E6B32", "mask": "jack",
	},
	"squelette": {
		"name": "Squelette", "outfit": "tshirt", "outfit_color": "#23232B", "accent_color": "#F4F2EC", "pattern": "bones",
		"legwear": "pants", "legwear_color": "#23232B", "shoes": "sneaker", "shoe_color": "#23232B",
		"hat": "", "mask": "skull",
	},
	"vampire": {
		"name": "Vampire", "outfit": "tshirt", "outfit_color": "#1E1E28", "accent_color": "#C8202A", "pattern": "none",
		"legwear": "pants", "legwear_color": "#1E1E28", "shoes": "boot", "shoe_color": "#1E1E28",
		"cape": "collar", "cape_color": "#2B1020", "cape_lining": "#C8202A", "mask": "fangs",
	},
	"pirate": {
		"name": "Pirate", "outfit": "tshirt", "outfit_color": "#F4F2EC", "accent_color": "#C8202A", "pattern": "stripes",
		"legwear": "pants", "legwear_color": "#3A3A48", "shoes": "boot", "shoe_color": "#5E4228",
		"hat": "pirate", "hat_color": "#23232B", "mask": "patch",
	},
	"princesse": {
		"name": "Princesse", "outfit": "dress", "outfit_color": "#F7A8C4", "accent_color": "#F2C230", "pattern": "hearts",
		"legwear": "tights", "legwear_color": "#FBE3EC", "shoes": "mary_jane", "shoe_color": "#F2C230",
		"hat": "crown", "hat_color": "#F7A8C4", "cape": "plain", "cape_color": "#F7A8C4", "cape_lining": "#FBE3EC",
	},
	"super": {
		"name": "Super-héros", "outfit": "tshirt", "outfit_color": "#2C5FC4", "accent_color": "#F2C230", "pattern": "star",
		"legwear": "pants", "legwear_color": "#2C5FC4", "shoes": "boot", "shoe_color": "#C8202A",
		"cape": "plain", "cape_color": "#C8202A", "cape_lining": "#F2C230", "mask": "domino",
	},
	"dinosaure": {
		"name": "Dinosaure", "outfit": "hoodie", "outfit_color": "#4E9A52", "accent_color": "#F2C230", "pattern": "none",
		"legwear": "pants", "legwear_color": "#4E9A52", "shoes": "sneaker", "shoe_color": "#2E6B32",
		"hat": "dino", "hat_color": "#4E9A52", "tail": "dino", "tail_color": "#4E9A52",
	},
	"abeille": {
		"name": "Abeille", "outfit": "sweater", "outfit_color": "#F2C230", "accent_color": "#23232B", "pattern": "stripes",
		"legwear": "tights", "legwear_color": "#23232B", "shoes": "mary_jane", "shoe_color": "#23232B",
		"hat": "antennae", "hat_color": "#23232B", "wings": "bee",
	},
	"licorne": {
		"name": "Licorne", "outfit": "dress", "outfit_color": "#F4F2EC", "accent_color": "#C9A0E8", "pattern": "stars",
		"legwear": "tights", "legwear_color": "#FBE3EC", "shoes": "mary_jane", "shoe_color": "#C9A0E8",
		"hat": "unicorn", "hat_color": "#F4F2EC", "tail": "unicorn", "tail_color": "#F4F2EC",
	},
	"robot": {
		"name": "Robot", "outfit": "sweater", "outfit_color": "#9AA0A6", "accent_color": "#1FB5C4", "pattern": "none",
		"legwear": "pants", "legwear_color": "#9AA0A6", "shoes": "boot", "shoe_color": "#5E6368",
		"hat": "robot", "hat_color": "#B9BEC4",
	},
	"astronaute": {
		"name": "Astronaute", "outfit": "hoodie", "outfit_color": "#F4F2EC", "accent_color": "#2C5FC4", "pattern": "none",
		"legwear": "pants", "legwear_color": "#F4F2EC", "shoes": "boot", "shoe_color": "#9AA0A6",
		"hat": "space", "hat_color": "#F4F2EC",
	},
	"momie": {
		"name": "Momie", "outfit": "sweater", "outfit_color": "#E8E0CC", "accent_color": "#C9BFA6", "pattern": "bandages",
		"legwear": "pants", "legwear_color": "#E8E0CC", "shoes": "sneaker", "shoe_color": "#E8E0CC",
		"hat": "mummy", "hat_color": "#E8E0CC", "mask": "mummy",
	},
	"renard": {
		"name": "Renard", "outfit": "hoodie", "outfit_color": "#E8812E", "accent_color": "#F4F2EC", "pattern": "none",
		"legwear": "pants", "legwear_color": "#E8812E", "shoes": "boot", "shoe_color": "#5E4228",
		"hat": "fox", "hat_color": "#E8812E", "tail": "fox", "tail_color": "#E8812E", "mask": "whiskers",
	},
	"diable": {
		"name": "Petit diable", "outfit": "tshirt", "outfit_color": "#C8202A", "accent_color": "#23232B", "pattern": "none",
		"legwear": "pants", "legwear_color": "#C8202A", "shoes": "boot", "shoe_color": "#23232B",
		"hat": "devil", "hat_color": "#C8202A", "tail": "devil", "tail_color": "#C8202A",
		"cape": "plain", "cape_color": "#C8202A", "cape_lining": "#23232B",
	},
	"fee": {
		"name": "Fée", "outfit": "dress", "outfit_color": "#BFE3F0", "accent_color": "#F2C230", "pattern": "stars",
		"legwear": "tights", "legwear_color": "#F4F2EC", "shoes": "mary_jane", "shoe_color": "#BFE3F0",
		"hat": "headband", "hat_color": "#F2C230", "wings": "fairy",
	},
	"clown": {
		"name": "Clown", "outfit": "sweater", "outfit_color": "#4FA3E0", "accent_color": "#E8542F", "pattern": "stripes",
		"legwear": "pants", "legwear_color": "#E8542F", "shoes": "sneaker", "shoe_color": "#F2C230",
		"hat": "clown", "hat_color": "#E8542F", "mask": "clown",
	},
	"chauvesouris": {
		"name": "Chauve-souris", "outfit": "hoodie", "outfit_color": "#2B2B38", "accent_color": "#7E57C2", "pattern": "none",
		"legwear": "tights", "legwear_color": "#2B2B38", "shoes": "boot", "shoe_color": "#2B2B38",
		"hat": "bat", "hat_color": "#2B2B38", "wings": "bat",
	},
	"cowboy": {
		"name": "Cowboy", "outfit": "tshirt", "outfit_color": "#D9A23A", "accent_color": "#8E3A26", "pattern": "none",
		"legwear": "pants", "legwear_color": "#5E7FA8", "shoes": "boot", "shoe_color": "#8E5A36",
		"hat": "cowboy", "hat_color": "#A9743A", "mask": "freckles",
	},
	"ninja": {
		"name": "Ninja", "outfit": "hoodie", "outfit_color": "#2E3440", "accent_color": "#C8202A", "pattern": "none",
		"legwear": "pants", "legwear_color": "#2E3440", "shoes": "sneaker", "shoe_color": "#2E3440",
		"hat": "ninja", "hat_color": "#2E3440", "mask": "ninja",
	},
}

## The ids in the order the wardrobe shows them.
const ORDER := ["chat", "sorciere", "fantome", "citrouille", "squelette", "vampire", "pirate", "princesse", "super",
	"dinosaure", "abeille", "licorne", "robot", "astronaute", "momie", "renard", "diable", "fee", "clown",
	"chauvesouris", "cowboy", "ninja"]


static func name_of(id: String) -> String:
	return str(ALL.get(id, {}).get("name", ""))


static func parts(id: String) -> Dictionary:
	return ALL.get(id, {})


## Dresses `look` in its costume (it keeps its own face, skin and hair): the clothing fields are set here, so the torso,
## legs and headwear draw themselves as they always do. Does nothing when she wears no costume.
static func apply(look: CharacterLook) -> void:
	var c: Dictionary = ALL.get(look.costume, {})
	if c.is_empty():
		return
	for field in ["outfit", "pattern", "legwear", "shoes", "hat"]:
		if c.has(field):
			look.set(field, c[field])
	for field in ["outfit_color", "accent_color", "legwear_color", "shoe_color", "hat_color"]:
		if c.has(field):
			look.set(field, Color(c[field]))
	# A costume is a costume: her own exact colours and her everyday trimmings step aside.
	look.overrides = {}
	look.scarf = ""
	look.necklace = ""
	look.backpack = ""
	if c.has("sleeve"):
		look.sleeve = c.sleeve


# ── The extra pieces ────────────────────────────────────────

## The headwear a costume adds, drawn in the head's own space like `CharacterArt._hat()` (the head is about x 30-195, its
## top near y 10). Returns "" for a kind nobody draws here, so the ordinary hats still work.
static func hat(kind: String, color: String, line: String, light: String) -> String:
	match kind:
		"ghost":
			# A whole sheet thrown over her head: it hides her hair and her face, with two holes cut for the eyes,
			# a soft fold along the brow and a torn hem under the chin.
			var s := '<path d="M4 236 C-6 110 36 -16 121 -16 C206 -16 248 110 238 236 Q226 252 214 236 Q200 256 186 238 Q172 258 158 240 Q144 260 130 240 Q116 260 102 240 Q88 258 74 240 Q60 258 46 238 Q32 256 18 236 Q10 250 4 236 Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [color, line]
			s += '<path d="M22 150 C30 50 70 2 118 2 C92 22 56 72 48 168 Z" fill="%s" opacity="0.6"/>' % light
			s += '<path d="M30 108 C70 92 172 92 212 108" stroke="%s" stroke-width="3" fill="none" opacity="0.35"/>' % line
			s += '<path d="M28 188 C70 178 172 178 214 188" stroke="%s" stroke-width="2.5" fill="none" opacity="0.25"/>' % line
			# The eye holes, right where her eyes are, and a little round mouth.
			s += '<ellipse cx="94" cy="130" rx="19" ry="24" fill="#2B2430"/><ellipse cx="149" cy="130" rx="19" ry="24" fill="#2B2430"/>'
			s += '<ellipse cx="90" cy="121" rx="5" ry="6" fill="#4A4458" opacity="0.7"/>'
			return s + '<ellipse cx="121" cy="178" rx="15" ry="13" fill="#2B2430"/>'
		"pumpkin":
			# The stalk and a curl of vine on top of her head.
			return ('<path d="M100 24 q6 -34 22 -40 q10 16 4 40 z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [color, line]
				+ '<path d="M124 -4 q22 -8 26 10 q-14 10 -22 -2" fill="%s" stroke="%s" stroke-width="2.5"/>' % [light, line]
				+ '<path d="M98 -4 q-20 -6 -26 10" stroke="%s" stroke-width="4" fill="none" stroke-linecap="round"/>' % line)
		"pirate":
			# A red bandana knotted at the side, with the skull patch.
			var s := '<path d="M28 68 C32 24 74 8 112 8 C152 8 192 24 196 68 C150 56 74 56 28 68 Z" fill="#C8202A" stroke="#8E1A20" stroke-width="3"/>'
			s += '<path d="M34 56 Q112 40 190 56" stroke="#8E1A20" stroke-width="2" fill="none" opacity="0.6"/>'
			s += '<path d="M190 60 q26 -12 34 2 q-20 6 -34 10 z" fill="#C8202A" stroke="#8E1A20" stroke-width="2.5" stroke-linejoin="round"/>'
			s += '<path d="M196 72 q22 10 26 30 q-20 -6 -30 -22 z" fill="#C8202A" stroke="#8E1A20" stroke-width="2.5" stroke-linejoin="round"/>'
			s += '<circle cx="86" cy="40" r="11" fill="#F4F2EC"/><circle cx="82" cy="38" r="2.4" fill="#23232B"/><circle cx="91" cy="38" r="2.4" fill="#23232B"/>'
			return s + '<path d="M80 48 h12 v4 h-12 z" fill="#F4F2EC"/>'
		"dino":
			# A green hood with a row of spikes over the crown.
			var s := '<path d="M14 100 C12 32 60 -6 112 -6 C166 -6 214 32 212 100 C170 88 54 88 14 100 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [color, line]
			s += '<path d="M40 70 C60 46 164 46 184 70" stroke="%s" stroke-width="3" fill="none" opacity="0.4"/>' % line
			for spike in [[62.0, 22.0], [90.0, -2.0], [122.0, -8.0], [154.0, 8.0], [180.0, 34.0]]:
				s += '<path d="M%s %s l10 -22 l12 20 z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [spike[0], spike[1], light, line]
			return s + '<path d="M44 60 Q58 24 98 10" stroke="%s" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.35"/>' % light
		"antennae":
			return ('<path d="M86 22 q-14 -36 -30 -44 M138 22 q14 -36 30 -44" stroke="%s" stroke-width="5" fill="none" stroke-linecap="round"/>' % color
				+ '<circle cx="54" cy="-26" r="10" fill="%s" stroke="%s" stroke-width="2.5"/>' % [light, color]
				+ '<circle cx="170" cy="-26" r="10" fill="%s" stroke="%s" stroke-width="2.5"/>' % [light, color]
				+ '<path d="M40 76 C44 36 76 18 112 18 C150 18 180 36 184 76" stroke="%s" stroke-width="7" fill="none"/>' % color)
		"unicorn":
			# The golden horn, two ears and a rainbow mane along the brow.
			var s := '<path d="M100 16 L118 -58 L134 14 Z" fill="#F2C230" stroke="#C99410" stroke-width="3" stroke-linejoin="round"/>'
			s += '<path d="M104 2 L126 -6 M106 -12 L128 -20 M110 -26 L128 -32" stroke="#C99410" stroke-width="2.5" stroke-linecap="round"/>'
			s += '<path d="M72 36 L70 0 L98 24 Z M146 22 L172 0 L170 38 Z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
			s += '<path d="M78 28 L77 10 L92 24 Z" fill="#F7A8C4"/><path d="M152 22 L166 10 L165 30 Z" fill="#F7A8C4"/>'
			for i in 5:
				var mane: String = ["#F7A8C4", "#C9A0E8", "#9AD1F0", "#A8E6A1", "#F2C230"][i]
				s += '<path d="M%s 30 q-22 22 -14 56 q16 -16 26 -52 z" fill="%s" opacity="0.95"/>' % [58.0 + i * 9.0, mane]
			return s
		"robot":
			# A box worn ON her head, not balanced over it: the face looks out of a square opening, with a lit
			# strip, bolts, two ear discs, a grille under the chin and an aerial on top.
			# Four plates round a square opening, so her own face looks out of the box.
			var s := '<rect x="14" y="-4" width="214" height="104" rx="16" fill="%s" stroke="%s" stroke-width="3.5"/>' % [color, line]
			s += '<rect x="14" y="96" width="36" height="124" fill="%s" stroke="%s" stroke-width="3.5"/>' % [color, line]
			s += '<rect x="192" y="96" width="36" height="124" fill="%s" stroke="%s" stroke-width="3.5"/>' % [color, line]
			s += '<rect x="14" y="192" width="214" height="28" rx="12" fill="%s" stroke="%s" stroke-width="3.5"/>' % [color, line]
			# The lit strip and the dials on the forehead plate.
			s += '<rect x="40" y="18" width="162" height="40" rx="10" fill="#2E3440" stroke="%s" stroke-width="3"/>' % line
			s += '<rect x="52" y="30" width="46" height="13" rx="6" fill="#1FB5C4"/><rect x="144" y="30" width="46" height="13" rx="6" fill="#1FB5C4"/>'
			s += '<circle cx="121" cy="36" r="7" fill="#C8202A"/>'
			s += '<rect x="60" y="70" width="122" height="14" rx="7" fill="#5E6368"/>'
			for i in 5:
				s += '<rect x="%s" y="196" width="9" height="18" rx="4" fill="#5E6368"/>' % (78 + i * 18)
			for b: Array in [[30.0, 12.0], [212.0, 12.0], [30.0, 206.0], [212.0, 206.0]]:
				s += '<circle cx="%s" cy="%s" r="7" fill="%s" stroke="%s" stroke-width="2"/>' % [b[0], b[1], light, line]
			# The ear discs and the aerial.
			s += '<circle cx="4" cy="146" r="18" fill="%s" stroke="%s" stroke-width="3"/>' % [light, line]
			s += '<circle cx="238" cy="146" r="18" fill="%s" stroke="%s" stroke-width="3"/>' % [light, line]
			s += '<rect x="117" y="-40" width="8" height="38" fill="%s"/><circle cx="121" cy="-46" r="11" fill="#C8202A" stroke="#8E1A20" stroke-width="2"/>' % line
			return s + '<path d="M34 42 Q42 4 80 0" stroke="%s" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.6"/>' % light
		"space":
			# A bubble helmet right over her head: the glass, its white rim and collar, and the sun caught in it.
			var s := '<path d="M-2 196 C-10 58 44 -28 121 -28 C198 -28 252 58 244 196 Z" fill="#CFE6F2" opacity="0.42" stroke="%s" stroke-width="5"/>' % color
			s += '<path d="M-6 190 H248 Q252 224 244 238 H-2 Q-10 224 -6 190 Z" fill="%s" stroke="#B9B4AA" stroke-width="3"/>' % color
			s += '<path d="M-4 200 H246" stroke="#FFFFFF" stroke-width="4" fill="none" opacity="0.5"/>'
			s += '<path d="M34 92 Q44 14 100 -8" stroke="#FFFFFF" stroke-width="16" fill="none" stroke-linecap="round" opacity="0.55"/>'
			s += '<path d="M28 140 Q32 70 70 30" stroke="#FFFFFF" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.4"/>'
			s += '<circle cx="206" cy="42" r="11" fill="#F2C230" stroke="#C99410" stroke-width="2" opacity="0.9"/>'
			return s + '<path d="M-2 196 H244" stroke="#B9B4AA" stroke-width="3" fill="none"/>'
		"mummy":
			# Bandages wound round her head, one end hanging loose.
			var s := '<path d="M16 96 C14 30 60 -8 112 -8 C166 -8 212 30 210 96 C170 84 56 84 16 96 Z" fill="%s" stroke="#C9BFA6" stroke-width="3"/>' % color
			for i in 5:
				s += '<path d="M%s %s Q112 %s %s %s" stroke="#C9BFA6" stroke-width="2.5" fill="none" opacity="0.8"/>' % [
					18.0 + i * 3.0, 86.0 - i * 18.0, 62.0 - i * 20.0, 208.0 - i * 3.0, 78.0 - i * 18.0]
			return s + '<path d="M186 84 q26 14 22 44 q-18 -4 -30 -26 z" fill="%s" stroke="#C9BFA6" stroke-width="2.5" stroke-linejoin="round"/>' % color
		"fox":
			var s := '<path d="M18 98 C16 36 62 2 112 2 C164 2 208 36 206 98 C168 88 56 88 18 98 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [color, line]
			s += '<path d="M54 44 L44 -16 L100 20 Z M128 18 L182 -18 L172 44 Z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
			s += '<path d="M62 36 L57 2 L88 22 Z M136 20 L168 2 L164 36 Z" fill="#23232B"/>'
			return s + '<path d="M40 76 C70 60 154 60 184 76" fill="#F4F2EC" opacity="0.85"/>'
		"devil":
			return ('<path d="M72 20 q-16 -34 2 -46 q16 14 20 42 z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
				+ '<path d="M152 20 q16 -34 -2 -46 q-16 14 -20 42 z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
				+ '<path d="M40 74 C44 34 76 16 112 16 C150 16 180 34 184 74" stroke="%s" stroke-width="8" fill="none"/>' % color)
		"clown":
			# A frizzy wig with a tiny hat perched on it.
			var s := ""
			for i in 9:
				var a: float = PI * (0.08 + i * 0.105)
				var cx: float = 112.0 - cos(a) * 92.0
				var cy: float = 54.0 - sin(a) * 66.0
				s += '<circle cx="%.1f" cy="%.1f" r="26" fill="%s"/>' % [cx, cy, color]
				s += '<circle cx="%.1f" cy="%.1f" r="14" fill="%s" opacity="0.55"/>' % [cx - 6.0, cy - 6.0, light]
			s += '<path d="M126 -12 l44 -10 l10 30 l-44 10 z" fill="#2C5FC4" stroke="#1B3E85" stroke-width="2.5" stroke-linejoin="round"/>'
			return s + '<path d="M120 10 l58 -12" stroke="#F2C230" stroke-width="6" stroke-linecap="round"/>'
		"bat":
			var s := '<path d="M20 96 C18 34 64 0 112 0 C162 0 208 34 206 96 C168 86 58 86 20 96 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [color, line]
			s += '<path d="M56 36 L38 -14 L96 14 Z M130 12 L188 -16 L170 36 Z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
			return s + '<path d="M64 30 L54 2 L86 16 Z M140 14 L172 2 L162 30 Z" fill="#7E57C2" opacity="0.8"/>'
		"cowboy":
			return ('<path d="M-4 86 Q112 52 228 86 Q112 112 -4 86 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [color, line]
				+ '<path d="M56 82 C54 28 86 6 112 6 C140 6 172 28 170 82 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [color, line]
				+ '<path d="M96 10 Q112 24 128 10" stroke="%s" stroke-width="3" fill="none"/>' % line
				+ '<rect x="52" y="60" width="122" height="14" fill="#5E4228"/><rect x="104" y="58" width="18" height="18" fill="#F2C230" stroke="#C99410" stroke-width="2"/>')
		"ninja":
			# The hood of a ninja: it comes right down the sides of her head and over her shoulders, with only a
			# band across the eyes left open (the mask draws the cloth above and below it).
			var s := '<path d="M22 150 C20 26 62 -14 121 -14 C180 -14 222 26 220 150 Q222 196 214 226 L192 220 Q202 178 198 142 C198 64 166 28 121 28 C76 28 44 64 44 142 Q40 178 50 220 L28 226 Q20 196 22 150 Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [color, line]
			s += '<path d="M36 118 C40 50 76 16 121 16 C166 16 202 50 206 118 Q121 98 36 118 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [color, line]
			s += '<path d="M222 70 q30 12 34 38 q-26 0 -38 -20 z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
			s += '<path d="M226 104 q22 24 16 54 q-18 -10 -24 -36 z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, line]
			return s + '<path d="M48 72 Q60 26 104 12" stroke="%s" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.25"/>' % light
	return ""


## The cape hanging from her shoulders, drawn behind her. Canvas CAPE_CANVAS, the collar at CAPE_PIVOT.
static func cape(kind: String, color: String, lining: String) -> String:
	var s := ""
	# The cloth: narrow at the shoulders, spreading out and scalloped along the hem.
	var body := "M86 10 Q120 0 154 10 L196 180 Q174 196 150 186 Q120 200 90 186 Q66 196 44 180 Z"
	s += '<path d="%s" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [body, lining, _dark(color)]
	s += '<path d="M96 14 Q120 6 144 14 L178 176 Q150 190 120 182 Q90 190 62 176 Z" fill="%s"/>' % color
	s += '<path d="M104 20 Q120 14 136 20 L160 168" stroke="%s" stroke-width="3" fill="none" opacity="0.35"/>' % _dark(color)
	s += '<path d="M110 22 L82 170" stroke="#FFFFFF" stroke-width="5" fill="none" opacity="0.16"/>'
	if kind == "collar":
		# A vampire's stand-up collar.
		s += '<path d="M78 16 Q66 -34 96 -40 L108 12 Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [lining, _dark(color)]
		s += '<path d="M162 16 Q174 -34 144 -40 L132 12 Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [lining, _dark(color)]
	s += '<path d="M84 12 Q120 2 156 12" stroke="%s" stroke-width="9" fill="none" stroke-linecap="round"/>' % _dark(color)
	s += '<circle cx="120" cy="10" r="8" fill="#F2C230" stroke="#C99410" stroke-width="2"/>'
	return s


## Wings behind her back. Canvas WINGS_CANVAS, between the shoulders at WINGS_PIVOT.
static func wings(kind: String) -> String:
	var s := ""
	match kind:
		"bee":
			for side in [-1.0, 1.0]:
				s += '<g transform="translate(130 40) scale(%s 1)">' % side
				s += '<path d="M6 0 Q86 -32 104 26 Q92 72 36 44 Q10 28 6 0 Z" fill="#DFF1F8" opacity="0.85" stroke="#A8C6D4" stroke-width="3"/>'
				s += '<path d="M14 10 Q70 -4 92 32" stroke="#A8C6D4" stroke-width="2" fill="none" opacity="0.8"/>'
				s += '<path d="M10 24 Q58 20 76 50" stroke="#A8C6D4" stroke-width="2" fill="none" opacity="0.6"/>'
				s += "</g>"
		"fairy":
			for side in [-1.0, 1.0]:
				s += '<g transform="translate(130 32) scale(%s 1)">' % side
				s += '<path d="M2 2 Q92 -54 118 6 Q102 62 26 40 Z" fill="#F7D8EC" opacity="0.85" stroke="#D9A6CC" stroke-width="3"/>'
				s += '<path d="M6 40 Q78 36 98 92 Q58 122 18 82 Z" fill="#DFF1F8" opacity="0.85" stroke="#A8C6D4" stroke-width="3"/>'
				s += '<path d="M14 10 Q70 -22 104 12 M16 54 Q62 54 86 90" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.85"/>'
				s += '<path d="M24 20 Q74 -4 98 18" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.5"/>'
				for d: Array in [[72.0, -12.0], [96.0, 22.0], [54.0, 72.0]]:
					s += '<circle cx="%s" cy="%s" r="4" fill="#FFFFFF" opacity="0.8"/>' % [d[0], d[1]]
				s += "</g>"
		"bat":
			for side in [-1.0, 1.0]:
				s += '<g transform="translate(130 30) scale(%s 1)">' % side
				s += '<path d="M0 14 L30 -52 L48 -8 L96 -62 L108 -10 L160 -56 L158 18 L142 54 L122 32 L104 76 L84 42 L62 86 L42 48 L18 70 Z" fill="#2B2B38" stroke="#17171F" stroke-width="3" stroke-linejoin="round"/>'
				s += '<path d="M8 16 L32 -44 M22 22 L96 -52 M40 34 L154 -48" stroke="#4A4A5E" stroke-width="3" fill="none" stroke-linecap="round"/>'
				s += '<path d="M0 14 L30 -52 L48 -8 Z" fill="#3C3C4E" opacity="0.7"/>'
				s += "</g>"
	return s


## A tail at her hip, drawn behind her. Canvas TAIL_CANVAS, its root at TAIL_PIVOT.
## The whole body is flipped by `facing`, so a tail curling to the RIGHT of its root came out in front of her as
## soon as she walked to the right (Julien saw it on the cat and the dinosaur). The shapes below are still drawn
## curling right — that is how they read — and the whole thing is mirrored here, so the tail always trails behind.
static func tail(kind: String, color: String) -> String:
	var shape := _tail_shape(kind, color)
	if shape.is_empty():
		return ""
	return '<g transform="translate(%s 0) scale(-1 1)">%s</g>' % [TAIL_CANVAS.x, shape]


# The tail itself, curling to the right of (26, 44); `tail` mirrors it.
static func _tail_shape(kind: String, color: String) -> String:
	match kind:
		"cat":
			return ('<path d="M22 44 Q86 54 110 20 Q130 -8 118 -40" stroke="%s" stroke-width="22" fill="none" stroke-linecap="round"/>' % color
				+ '<path d="M22 44 Q86 54 110 20 Q130 -8 118 -40" stroke="%s" stroke-width="10" fill="none" stroke-linecap="round" opacity="0.25"/>' % _light(color)
				+ '<path d="M118 -40 q-8 -18 2 -26" stroke="%s" stroke-width="18" fill="none" stroke-linecap="round"/>' % color)
		"fox":
			return ('<path d="M20 40 Q78 58 108 36 Q140 12 128 -30 Q106 -6 80 8 Q48 22 20 24 Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [color, _dark(color)]
				+ '<path d="M128 -30 q-20 2 -30 16 q22 10 30 -16 z" fill="#F4F2EC"/>'
				+ '<path d="M34 32 Q74 44 100 28" stroke="%s" stroke-width="5" fill="none" opacity="0.35"/>' % _light(color))
		"dino":
			var s := '<path d="M18 48 Q86 58 120 28 Q146 4 140 -26 Q112 6 76 20 Q44 30 18 28 Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [color, _dark(color)]
			for i in 4:
				s += '<path d="M%s %s l6 -20 l14 14 z" fill="#F2C230" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % [34.0 + i * 26.0, 34.0 - i * 10.0, _dark(color)]
			return s
		"devil":
			return ('<path d="M22 44 Q90 56 114 24 Q134 -2 124 -34" stroke="%s" stroke-width="14" fill="none" stroke-linecap="round"/>' % color
				+ '<path d="M124 -34 l-18 -4 l12 -16 l16 10 z" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>' % [color, _dark(color)])
		"unicorn":
			var s := ""
			for i in 5:
				var c: String = ["#F7A8C4", "#C9A0E8", "#9AD1F0", "#A8E6A1", "#F2C230"][i]
				s += '<path d="M20 %s Q80 %s 120 %s" stroke="%s" stroke-width="9" fill="none" stroke-linecap="round"/>' % [
					32.0 + i * 7.0, 58.0 + i * 7.0, 10.0 + i * 9.0, c]
			return s
	return ""


## Face paint and small pieces worn on the face, drawn over her eyes and under the fringe. Head space, like the hats:
## her eyes sit at (94, 130) and (149, 130), the face's middle is x 122, the nose tip y 152, the mouth y 170, the
## forehead y 96 and the chin y 196 — everything here is placed on those, so nothing lands on the wrong feature.
static func mask(kind: String) -> String:
	match kind:
		"whiskers":
			# A little nose on the nose, and three whiskers a side out over the cheeks, clear of her smile.
			var s := '<path d="M110 142 h24 q2 8 -12 17 q-14 -9 -12 -17 z" fill="#2B2B33"/>'
			for i in 3:
				var y: float = 150.0 + i * 11.0
				var lift: float = -4.0 + i * 4.0
				s += '<path d="M56 %s q22 %s 44 %s" stroke="#2B2B33" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.9"/>' % [y, lift, lift * 0.4]
				s += '<path d="M188 %s q-22 %s -44 %s" stroke="#2B2B33" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.9"/>' % [y, lift, lift * 0.4]
			return s
		"ghost":
			# Under the sheet: her face goes pale, nothing more (two painted holes read as bruises).
			return ('<ellipse cx="111" cy="132" rx="76" ry="72" fill="#F4F2EC" opacity="0.38"/>'
				+ '<ellipse cx="111" cy="132" rx="76" ry="72" fill="none" stroke="#DAD3C4" stroke-width="2" opacity="0.5"/>')
		"jack":
			# Jack-o-lantern brows over her own, and a soft orange glow on the face.
			return ('<ellipse cx="111" cy="134" rx="74" ry="70" fill="#E8812E" opacity="0.18"/>'
				+ '<path d="M72 102 l26 -12 l2 16 z" fill="#8A4A14" opacity="0.85"/>'
				+ '<path d="M170 102 l-26 -12 l-2 16 z" fill="#8A4A14" opacity="0.85"/>')
		"skull":
			# Painted on, not a blindfold: the sockets are see-through, so her eyes still show.
			return ('<ellipse cx="94" cy="130" rx="27" ry="30" fill="#23232B" opacity="0.5"/>'
				+ '<ellipse cx="149" cy="130" rx="25" ry="29" fill="#23232B" opacity="0.5"/>'
				+ '<path d="M114 150 l9 -15 l9 15 z" fill="#23232B" opacity="0.75"/>'
				+ '<path d="M86 170 h74" stroke="#23232B" stroke-width="3.5" opacity="0.6"/>'
				+ '<path d="M98 160 v20 M112 160 v20 M126 160 v20 M140 160 v20 M154 162 v16" stroke="#23232B" stroke-width="2.6" opacity="0.6"/>')
		"fangs":
			# Two little fangs under her lip, and dark arched brows.
			return ('<path d="M110 172 l5 15 l5 -15 z" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="1"/>'
				+ '<path d="M128 172 l5 15 l5 -15 z" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="1"/>'
				+ '<path d="M74 102 q18 -12 36 -4 M172 100 q-18 -12 -36 -4" stroke="#2B1020" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
		"patch":
			# Over one eye, its strap round the head.
			return ('<path d="M36 118 Q110 100 188 116" stroke="#23232B" stroke-width="5" fill="none"/>'
				+ '<ellipse cx="94" cy="130" rx="25" ry="23" fill="#23232B"/>'
				+ '<ellipse cx="87" cy="123" rx="7" ry="5" fill="#FFFFFF" opacity="0.18"/>')
		"domino":
			# A hero mask with real eye holes (even-odd: the two ellipses are cut out of the band).
			return ('<path fill-rule="evenodd" fill="#2C5FC4" stroke="#1B3E85" stroke-width="3" stroke-linejoin="round"'
				+ ' d="M44 112 Q122 94 200 112 Q206 150 170 160 Q122 168 74 160 Q38 150 44 112 Z'
				+ ' M94 112 m-20 0 a20 15 0 1 0 40 0 a20 15 0 1 0 -40 0'
				+ ' M152 112 m-19 0 a19 15 0 1 0 38 0 a19 15 0 1 0 -38 0 Z"/>')
		"mummy":
			# Bandages across the forehead and the chin: her eyes and her smile stay clear.
			return ('<path d="M38 104 Q112 86 192 106" stroke="#E8E0CC" stroke-width="18" fill="none" opacity="0.92"/>'
				+ '<path d="M38 104 Q112 86 192 106" stroke="#C9BFA6" stroke-width="2" fill="none" opacity="0.6"/>'
				+ '<path d="M54 202 Q112 216 174 198" stroke="#E8E0CC" stroke-width="14" fill="none" opacity="0.92"/>'
				+ '<path d="M54 202 Q112 216 174 198" stroke="#C9BFA6" stroke-width="2" fill="none" opacity="0.5"/>'
				+ '<path d="M168 112 l16 -8 l6 14 z" fill="#E8E0CC" stroke="#C9BFA6" stroke-width="1.5" opacity="0.95"/>')
		"clown":
			# The red nose on her nose, a painted smile round her mouth, diamonds over the eyes and two round cheeks.
			return ('<circle cx="76" cy="162" r="14" fill="#F7A8C4" opacity="0.85"/><circle cx="164" cy="160" r="14" fill="#F7A8C4" opacity="0.85"/>'
				+ '<path d="M86 166 Q123 206 160 164" stroke="#E8542F" stroke-width="5" fill="none" stroke-linecap="round"/>'
				+ '<path d="M94 92 l9 14 l-9 14 l-9 -14 z" fill="#2C5FC4" opacity="0.85"/>'
				+ '<path d="M149 92 l9 14 l-9 14 l-9 -14 z" fill="#2C5FC4" opacity="0.85"/>'
				+ '<circle cx="123" cy="152" r="14" fill="#E8542F" stroke="#B5361A" stroke-width="2.5"/>'
				+ '<circle cx="117" cy="147" r="5" fill="#FFFFFF" opacity="0.7"/>')
		"ninja":
			# Hood and face cloth, with a band of her own face left between them.
			return ('<path d="M34 72 Q112 54 190 72 L190 108 Q112 96 34 110 Z" fill="#2E3440"/>'
				+ '<path d="M38 152 Q112 142 186 152 L182 214 Q112 228 42 214 Z" fill="#2E3440"/>'
				+ '<path d="M40 112 Q112 100 188 114" stroke="#1A1E26" stroke-width="2" fill="none" opacity="0.6"/>'
				+ '<path d="M40 156 Q112 146 186 156" stroke="#1A1E26" stroke-width="2" fill="none" opacity="0.6"/>')
		"freckles":
			var s := ""
			for i in 8:
				var fx: float = [68.0, 82.0, 94.0, 76.0, 150.0, 164.0, 176.0, 158.0][i]
				var fy: float = [152.0, 160.0, 152.0, 168.0, 150.0, 158.0, 150.0, 166.0][i]
				s += '<circle cx="%s" cy="%s" r="2.6" fill="#B5603F" opacity="0.7"/>' % [fx, fy]
			return s
	return ""


static func _dark(c: String) -> String:
	return "#" + Color(c).darkened(0.35).to_html(false)


static func _light(c: String) -> String:
	return "#" + Color(c).lightened(0.3).to_html(false)
