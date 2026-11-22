class_name Birthday
extends RefCounted
## Charlotte's birthday, the 1st of February (quest "anniversaire", winter, after the wobbly tooth; Julien: she invites the
## friends SHE chooses, five at most; she stays 7 for now), at home (`house.gd`), step by step (`flags.anniv_step`):
##   1. Maman says it is her birthday soon: the invitation card (`InviteCard`) lists the friends she has met (`GUESTS`) and she
##      ticks the ones she invites (`flags.anniv_invites`, `MAX` at most);
##   2. she decorates the salon: the banner over the sofa, the balloons, the party table (`DECOR`, `flags.anniv_decor`);
##   3. the party: the doorbell, her guests come in, each hands her a present she opens (`flags.anniv_opened`); then Maman
##      brings the cake, everyone sings, she blows out the candles, a slice; the guests go home and the quest is done.

const QUEST := "anniversaire"
const STEP := "anniv_step"
const INVITES := "anniv_invites"
const DECORATED := "anniv_decor"
const OPENED := "anniv_opened"
const HEADING := "🎂  Ma fête"
const MAX := 5
## Her friends: id, name, the flag that says she has met them, their look, their line handing the present, the present
## (a `PartyArt.gift` kind, or "balle"), and what she says opening it.
const GUESTS := [
	["alphee", "Alphée", "met_twins", "Bonne fête, Chachoue ! Ouvre le mien en premier !", "casse_tete", "Un casse-tête de minous ! Merci, Alphée !"],
	["constance", "Constance", "met_twins", "C'est moi qui l'ai choisi !", "vernis", "Du vernis brillant ! Merci, Constance !"],
	["billie", "Billie", "met_billie_auguste", "Bonne fête ! C'est pour bricoler ensemble !", "bricolage", "Des brillants pis des pompons ! Merci, Billie !"],
	["auguste", "Auguste", "met_billie_auguste", "C'est moi qui l'ai emballé tout seul !", "balle", "Une balle qui rebondit ! Merci, Auguste !"],
	["alyzee", "Alyzée", "met_alyzee", "Bonne fête, ma meilleure amie !", "licorne", "Une licorne ! Comme celle que je t'ai donnée !"],
]
## The decorations to put up: id, what she says.
const DECOR := [["banniere", "La bannière au-dessus du sofa !"], ["ballons", "Les ballons !"], ["table", "Pis la table de fête !"]]
const SONG := ["♪ Bonne fête à toi… ♪", "♪ Bonne fête à toi… ♪", "♪ Bonne fête, chère Chachoue… ♪", "♪ Bonne fête à toi ! ♪"]


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## Maman can tell her: winter, the quest free, and at least one friend to invite.
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST) and not friends().is_empty()


## The friends she has met, in `GUESTS` order.
static func friends() -> Array:
	return GUESTS.filter(func(g: Array) -> bool: return GameState.flags.get(g[2], false))


static func invites() -> Array:
	return GameState.flags.get(INVITES, [])


static func guest(id: String) -> Array:
	for g: Array in GUESTS:
		if g[0] == id:
			return g
	return GUESTS[0]


static func look(id: String) -> CharacterLook:
	match id:
		"alphee":
			return CharacterLook.alphee()
		"constance":
			return CharacterLook.constance()
		"billie":
			return CharacterLook.billie()
		"auguste":
			return CharacterLook.auguste()
	return CharacterLook.alyzee()


static func decorated() -> Array:
	return GameState.flags.get(DECORATED, [])


static func opened() -> Array:
	return GameState.flags.get(OPENED, [])


static func mark(flag: String, id: String) -> void:
	var now: Array = GameState.flags.get(flag, []).duplicate()
	if id not in now:
		now.append(id)
	GameState.flags[flag] = now


static func clear() -> void:
	for key in [STEP, INVITES, DECORATED, OPENED]:
		GameState.flags.erase(key)


static func hint() -> String:
	match step():
		1:
			return "C'est bientôt ta fête, le 1er février ! Va voir Maman pour choisir qui tu invites."
		2:
			return "Décore le salon pour ta fête : la bannière, les ballons pis la table (%d sur %d)." % [decorated().size(), DECOR.size()]
		3:
			return "C'est ta fête ! Ouvre les cadeaux de tes amis, pis viens souffler tes chandelles."
	return str(Quests.ALL[QUEST].hint)


## Canvas 80 × 80: Auguste's present, a bouncy ball in rainbow stripes.
static func ball() -> ImageTexture:
	var s := '<circle cx="40" cy="42" r="28" fill="#4DA6FF" stroke="#1D4F91" stroke-width="2"/>'
	s += '<path d="M14 34 Q40 24 66 34" stroke="#FFD23F" stroke-width="8" fill="none"/>'
	s += '<path d="M13 46 Q40 38 67 46" stroke="#FF4D6D" stroke-width="8" fill="none"/>'
	s += '<path d="M17 58 Q40 52 63 58" stroke="#5BD16E" stroke-width="7" fill="none"/>'
	s += '<circle cx="30" cy="28" r="6" fill="#FFFFFF" opacity="0.5"/>'
	return InteriorArt.tex(80, 80, s)


static func present_picture(kind: String) -> Texture2D:
	return ball() if kind == "balle" else PartyArt.gift(kind)


## The invitation card: her friends as tickets to tick (five at most), and "Envoyer les invitations !" once at least one is
## ticked. `sent` gives the ids chosen.
class InviteCard:
	extends CanvasLayer
	signal sent(ids: Array)
	var _chosen: Array = []
	var _buttons := {}
	var _send: Button

	func _init() -> void:
		layer = 62

	func _ready() -> void:
		add_to_group("modal")
		var dim := ColorRect.new()
		dim.color = Color(0.05, 0.08, 0.2, 0.45)
		dim.size = Vector2(1280, 720)
		add_child(dim)
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#FFF8EC")
		style.set_corner_radius_all(18)
		style.border_color = Color("#E86BB0")
		style.set_border_width_all(4)
		style.content_margin_left = 30
		style.content_margin_right = 30
		style.content_margin_top = 22
		style.content_margin_bottom = 22
		card.add_theme_stylebox_override("panel", style)
		add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		card.add_child(box)
		var title := Label.new()
		title.text = "Qui invites-tu à ta fête ?"
		title.add_theme_font_size_override("font_size", 30)
		title.add_theme_color_override("font_color", Color("#1D4F91"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(title)
		var sub := Label.new()
		sub.text = "Le 1er février, chez toi. Cinq amis au plus !"
		sub.add_theme_font_size_override("font_size", 18)
		sub.add_theme_color_override("font_color", Color("#7A5A6A"))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(sub)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(row)
		for g: Array in Birthday.friends():
			var b := Button.new()
			b.custom_minimum_size = Vector2(150, 64)
			b.add_theme_font_size_override("font_size", 20)
			b.text = "☐  " + str(g[1])
			_paint(b, false)
			b.pressed.connect(_toggle.bind(str(g[0]), str(g[1])))
			row.add_child(b)
			_buttons[g[0]] = b
		_send = Button.new()
		_send.text = "Envoyer les invitations !"
		_send.custom_minimum_size = Vector2(320, 56)
		_send.add_theme_font_size_override("font_size", 22)
		_send.disabled = true
		_paint(_send, true, Color("#1D4F91"))
		_send.pressed.connect(func() -> void:
			Sfx.play("chime")
			sent.emit(_chosen.duplicate())
			queue_free())
		var center := CenterContainer.new()
		center.add_child(_send)
		box.add_child(center)
		card.reset_size()
		card.position = (Vector2(1280, 720) - card.size) / 2.0

	func _toggle(id: String, name: String) -> void:
		if id in _chosen:
			_chosen.erase(id)
		elif _chosen.size() < Birthday.MAX:
			_chosen.append(id)
		else:
			return
		Sfx.play("click")
		for key in _buttons:
			var b: Button = _buttons[key]
			var label: String = b.text.substr(3)
			b.text = ("☑  " if key in _chosen else "☐  ") + label
			_paint(b, key in _chosen)
		_send.disabled = _chosen.is_empty()

	# A friend's ticket: cream with pink letters, or pink with white ones once ticked.
	func _paint(b: Button, on: bool, colour := Color("#E86BB0")) -> void:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var st := StyleBoxFlat.new()
			st.bg_color = colour if on else Color("#FFE8F2")
			if state == "hover":
				st.bg_color = st.bg_color.lightened(0.12)
			if state == "disabled":
				st.bg_color = Color("#D9D2CC")
			st.set_corner_radius_all(14)
			st.border_color = colour.darkened(0.2)
			st.set_border_width_all(3)
			b.add_theme_stylebox_override(state, st)
		var ink := Color.WHITE if on else colour.darkened(0.25)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, ink)
