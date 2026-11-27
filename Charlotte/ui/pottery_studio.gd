class_name PotteryStudio
extends CanvasLayer
## Pottery with Maman at her wheel in the corridor (Julien: "la poterie avec Maman"). Six steps, Maman's words along the bottom:
##   1. La forme: what to make (`PotteryArt.KINDS`: a bowl, a cup, a vase, a flower pot, a plate);
##   2. Centrer: the ball of clay wobbles on the turning wheel; she holds the button down, wet hands on it, until it runs true;
##   3. Monter: she presses in the middle to open it, then pulls the walls up or down and pushes them out or in where she grabs
##      (the clay dries as she works: the sponge wets it again; "Maman m'aide" eases it to the shape she chose);
##   4. Finitions (leather hard): a handle or two ears, a straight, wavy or spouted lip, lines, waves, dots or a zigzag carved;
##   5. L'émail: dip it (all, three quarters, half), the inside, bands round it, the brush, stamps, drips from the lip; raw glaze
##      is pale and chalky (copper red is even grey-green), "Oups !" takes a step back;
##   6. La cuisson: into the kiln, the needle climbs to 1 240 °C, it glows, cools, the door opens on the real colours.
## `closed` gives {image, kind} (an empty Dictionary if she stopped). The newest `KEEP_MAX` stand on the corridor's shelf
## (`keep`, `kept`, `poteries/` in the slot).

signal closed(result: Dictionary)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#F6EFE4")
const CLAY := Color("#A8735A")
const STEPS := [["forme", "La forme"], ["centrer", "Centrer"], ["monter", "Monter"], ["finir", "Finitions"], ["emailler", "L'émail"], ["cuire", "La cuisson"]]
const STAGE_POS := Vector2(24, 100)
const STAGE_SIZE := Vector2(700, 500)
const BASE := Vector2(350, 420)
const KILN_BASE := Vector2(350, 470)
const KEEP_MAX := 4
const UNDO := 20
const DIPS := [["Tout", 1.0], ["Les trois quarts", 0.75], ["La moitié", 0.5]]
const TOOLS := [["tremper", "Tremper"], ["dedans", "Dedans"], ["bande", "Une bande"], ["pinceau", "Pinceau"], ["tampon", "Tampons"], ["coulures", "Coulures"]]
const TIPS := {
	"centrer": "Mouille tes mains pis appuie sur la terre : garde le bouton enfoncé jusqu'à ce qu'elle arrête de branler !",
	"ouvrir": "Astheure, appuie au milieu de la motte avec tes pouces pour l'ouvrir.",
	"monter": "Tire la terre vers le haut ou vers le bas. Pousse vers l'extérieur pour élargir, vers le centre pour resserrer.",
	"sec": "Ta terre sèche, ma chouette ! Prends l'éponge pour la mouiller.",
	"finir": "Pendant qu'elle sèche, tu peux ajouter une anse, onduler le bord ou graver des dessins.",
	"emailler": "L'émail est tout pâle avant la cuisson… attends de voir les vraies couleurs !",
	"cuire": "Le four monte à 1 240 degrés ! On met ta poterie dedans pis on attend.",
	"chaud": "Ça chauffe… pas touche, c'est ben trop chaud !",
	"fini": "Wow ! C'est toi qui as fait ça ? Elle est magnifique, ma chouette !",
}

## Faster kiln (tests).
var speed := 1.0

var _root: Control
var _panel: Panel
var _stage: _Stage
var _side: VBoxContainer
var _tip: Label
var _chips: HBoxContainer
var _next: Button
var _undo_button: Button
var _step := ""
var _kind := ""
var _pot := {}
var _spin := 0.0
var _time := 0.0
var _wobble := 1.0
var _wet := 1.0
var _pressing := false
var _press := Vector2.ZERO
var _mouse := Vector2(-1, -1)
var _grab_t := 0.5
var _undo: Array = []
var _glaze := "cobalt"
var _tool := "tremper"
var _dip := 1.0
var _stamp := "coeur"
var _stamp_size := 26.0
var _brush := 7.0
var _stroke: Array = []
var _drops: Array = []
var _sparkles: Array = []
var _door := 1.0
var _heat := 0.0
var _fired := false
var _firing := false
var _busy := false
## 0 the pot in the kiln, 1 out of it, big on the table.
var _reveal := 0.0


func _init() -> void:
	layer = 60


func _ready() -> void:
	add_to_group("modal")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_panel = Panel.new()
	_panel.position = Vector2(20, 12)
	_panel.size = Vector2(1240, 696)
	_panel.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 6, 26))
	_root.add_child(_panel)
	_choose()


func _process(delta: float) -> void:
	_time += delta
	match _step:
		"centrer", "monter":
			_spin += delta * 7.0
		"finir":
			_spin += delta * 1.2
	if _step == "centrer" and _pressing and _wobble > 0.0:
		_wobble = maxf(0.0, _wobble - delta * 0.42)
		if _wobble == 0.0:
			_centred()
	for d: Array in _drops:
		d[1] += Vector2(0, 900.0) * delta
		d[0] += d[1] * delta
	_drops = _drops.filter(func(d: Array) -> bool: return d[0].y < BASE.y + 20.0)
	if _stage:
		_stage.queue_redraw()


# ── Step 1: what to make ────────────────────────────────────────

func _clear_panel() -> void:
	for child in _panel.get_children():
		_panel.remove_child(child)
		child.queue_free()
	_stage = null
	_side = null


func _choose() -> void:
	_clear_panel()
	_step = "forme"
	var title := _label("La poterie avec Maman", 34, BLUE)
	title.position = Vector2(0, 22)
	title.size = Vector2(1240, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	var hint := _label("Qu'est-ce qu'on fabrique au tour, aujourd'hui ?", 21, Color(BLUE, 0.75))
	hint.position = Vector2(0, 72)
	hint.size = Vector2(1240, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(hint)
	var x := 38.0
	var tones := ["#E3F1F0", "#FBE6EE", "#E5ECF8", "#FFF1D6", "#E9F3E2"]
	for i in PotteryArt.KINDS.size():
		var id: String = PotteryArt.KINDS[i]
		var card := Button.new()
		card.position = Vector2(x, 124)
		card.size = Vector2(222, 440)
		var normal := _box(Color.WHITE, Color("#C8A27A"), 3, 18)
		normal.shadow_color = Color(0.3, 0.18, 0.05, 0.18)
		normal.shadow_size = 8
		normal.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("normal", normal)
		card.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 4, 18))
		card.add_theme_stylebox_override("pressed", _box(Color("#FFE9A8"), YELLOW, 4, 18))
		card.pressed.connect(_begin.bind(id))
		_panel.add_child(card)
		var back := Panel.new()
		back.position = Vector2(10, 10)
		back.size = Vector2(202, 238)
		back.add_theme_stylebox_override("panel", _box(Color(tones[i]), Color(tones[i]).darkened(0.12), 2, 14))
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(back)
		var pic := _PotCard.new()
		pic.pot = PotteryArt.sample(id)
		pic.position = Vector2(11, 14)
		pic.size = Vector2(200, 230)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(pic)
		var info: Array = PotteryArt.KIND_INFO[id]
		var nm := _label(info[0], 26, BLUE)
		nm.position = Vector2(8, 262)
		nm.size = Vector2(206, 40)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)
		var blurb := _label(info[1], 18, Color(BLUE, 0.8))
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.position = Vector2(15, 312)
		blurb.size = Vector2(192, 110)
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(blurb)
		x += 234.0
	var cancel := _button("Plus tard", 20, func() -> void: _quit(), Vector2(150, 48))
	cancel.position = Vector2(1060, 620)
	_panel.add_child(cancel)


func _begin(kind: String) -> void:
	_kind = kind
	_pot = PotteryArt.new_pot(kind)
	_wobble = 1.0
	_wet = 1.0
	_undo.clear()
	Sfx.play("pop")
	_build_bench()
	_set_step("centrer")


# ── The bench ───────────────────────────────────────────────────

func _build_bench() -> void:
	_clear_panel()
	var title := _label("%s avec Maman" % str(PotteryArt.KIND_INFO[_kind][0]), 30, BLUE)
	title.position = Vector2(0, 10)
	title.size = Vector2(1240, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	_chips = HBoxContainer.new()
	_chips.position = Vector2(24, 58)
	_chips.add_theme_constant_override("separation", 6)
	_panel.add_child(_chips)
	var frame := Panel.new()
	frame.position = STAGE_POS - Vector2(6, 6)
	frame.size = STAGE_SIZE + Vector2(12, 12)
	frame.add_theme_stylebox_override("panel", _box(Color("#E9DFCB"), Color("#C8A27A"), 5, 12))
	_panel.add_child(frame)
	_stage = _Stage.new()
	_stage.studio = self
	_stage.position = STAGE_POS
	_stage.size = STAGE_SIZE
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(_stage)
	_tip = _label("", 19, Color("#7A3E5C"))
	_tip.position = Vector2(24, 606)
	_tip.size = Vector2(1000, 32)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_tip)
	_side = VBoxContainer.new()
	_side.position = Vector2(748, 60)
	_side.size = Vector2(468, 540)
	_side.add_theme_constant_override("separation", 10)
	_panel.add_child(_side)
	var stop := _button("Arrêter", 19, _leave, Vector2(110, 44))
	stop.position = Vector2(24, 642)
	_panel.add_child(stop)
	_undo_button = _button("Oups !", 19, _take_back, Vector2(100, 44))
	_undo_button.position = Vector2(144, 642)
	_panel.add_child(_undo_button)
	_next = _button("Suivant  →", 22, _go_next, Vector2(200, 46))
	_next.position = Vector2(1016, 640)
	_next.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	_panel.add_child(_next)


func _set_step(id: String) -> void:
	_step = id
	_pressing = false
	for c in _chips.get_children():
		c.queue_free()
	var reached := true
	for st: Array in STEPS:
		var chip := _label(("✓ " if reached and st[0] != id else "") + str(st[1]), 17, BLUE if st[0] == id else Color(BLUE, 0.5))
		var on: bool = st[0] == id
		chip.add_theme_stylebox_override("normal", _box(YELLOW if on else Color.WHITE, Color(BLUE, 0.6 if on else 0.25), 2, 12))
		_chips.add_child(chip)
		if st[0] == id:
			reached = false
	_build_side()
	_update_tip()
	_update_buttons()


func _update_buttons() -> void:
	if _next == null:
		return
	_undo_button.visible = _step in ["finir", "emailler"]
	_undo_button.disabled = _undo.is_empty()
	match _step:
		"centrer":
			_next.disabled = _wobble > 0.0
		"monter":
			_next.disabled = not _pot.open
		"emailler":
			_next.disabled = not _has_glaze()
		"cuire":
			_next.visible = _fired
			_next.disabled = false
			_next.text = "Montrer à Maman ♥"
			_next.custom_minimum_size = Vector2(250, 46)
			_next.position.x = 1216.0 - 250.0
		_:
			_next.disabled = false
	if _step != "cuire":
		_next.custom_minimum_size = Vector2(200, 46)
		_next.size = Vector2(200, 46)
		_next.position.x = 1016.0
		_next.visible = true
		_next.text = "Suivant  →" if _step != "emailler" else "Au four !  →"


func _update_tip() -> void:
	var key := _step
	if _step == "monter":
		key = "monter" if _pot.open else "ouvrir"
		if _pot.open and _wet < 0.2:
			key = "sec"
	if _step == "cuire":
		key = "fini" if _fired else ("chaud" if _firing else "cuire")
	_tip.text = "Maman : " + str(TIPS.get(key, ""))


func _go_next() -> void:
	if _busy:
		return
	Sfx.play("click")
	match _step:
		"centrer":
			_set_step("monter")
		"monter":
			_undo.clear()
			_set_step("finir")
		"finir":
			_undo.clear()
			_set_step("emailler")
		"emailler":
			_door = 1.0
			_heat = 0.0
			_set_step("cuire")
		"cuire":
			_finish()


# ── The side panel of each step ─────────────────────────────────

func _build_side() -> void:
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	match _step:
		"centrer":
			_heading("Centrer la terre")
			_text("Le tour tourne. Garde le bouton de la souris enfoncé sur la terre : tes mains mouillées la poussent au milieu.")
		"monter":
			_heading("Monter les parois")
			if not _pot.open:
				_text("Clique au milieu de la motte pour l'ouvrir avec tes pouces.")
			else:
				_text("Attrape la terre là où tu veux la changer :\n↑ ↓  plus haute ou plus basse\n← →  plus large ou plus étroite")
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				_side.add_child(row)
				row.add_child(_button("Éponge", 19, _sponge, Vector2(140, 50)))
				row.add_child(_button("Maman m'aide", 19, _mom_helps, Vector2(170, 50)))
				row.add_child(_button("Recommencer", 17, _restart_shape, Vector2(140, 50)))
		"finir":
			_heading("Les finitions")
			_choices("Une anse ?", [["", "Aucune"], ["anse", "Une anse"], ["oreilles", "Deux oreilles"]], _pot.handle, func(v: String) -> void: _set_part("handle", v))
			_choices("Le bord", [["droit", "Droit"], ["ondule", "Ondulé"], ["bec", "Un bec"]], _pot.rim, func(v: String) -> void: _set_part("rim", v))
			_choices("Des dessins gravés", [["", "Rien"], ["lignes", "Lignes"], ["vagues", "Vagues"], ["pois", "Pois"], ["zigzag", "Zigzag"]], _pot.carve, func(v: String) -> void: _set_part("carve", v))
		"emailler":
			_glaze_side()
		"cuire":
			_heading("La cuisson")
			if _fired:
				_text("Ta poterie est cuite ! Regarde les vraies couleurs de l'émail.")
				_side.add_child(_button("Une autre poterie", 19, _again, Vector2(240, 50)))
			elif _firing:
				_text("Le four chauffe… l'aiguille monte jusqu'à 1 240 °C.")
			else:
				_text("Ta poterie est dans le four. On ferme la porte pis on le met en marche !")
				var go := _button("Allumer le four", 22, _fire, Vector2(260, 60))
				go.add_theme_stylebox_override("normal", _box(Color("#FFB36B"), BLUE, 3, 16))
				_side.add_child(go)


func _glaze_side() -> void:
	_heading("L'émail")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_side.add_child(grid)
	for g: Array in PotteryArt.GLAZES:
		var b := Button.new()
		b.text = str(g[1])
		b.custom_minimum_size = Vector2(110, 40)
		b.add_theme_font_size_override("font_size", 13)
		var col := Color(g[2])
		var ink := Color.WHITE if col.get_luminance() < 0.55 else BLUE
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, ink)
		var on: bool = g[0] == _glaze
		b.add_theme_stylebox_override("normal", _box(col, YELLOW if on else col.darkened(0.3), 5 if on else 2, 10))
		b.add_theme_stylebox_override("hover", _box(col.lightened(0.1), BLUE, 3, 10))
		b.add_theme_stylebox_override("focus", _box(col, YELLOW if on else col.darkened(0.3), 5 if on else 2, 10))
		b.pressed.connect(func() -> void:
			_glaze = str(g[0])
			Sfx.play("click")
			_build_side())
		grid.add_child(b)
	var tools := GridContainer.new()
	tools.columns = 3
	tools.add_theme_constant_override("h_separation", 6)
	tools.add_theme_constant_override("v_separation", 6)
	_side.add_child(tools)
	for t: Array in TOOLS:
		var b := _toggle(str(t[1]), t[0] == _tool, func() -> void:
			_tool = str(t[0])
			_build_side(), Vector2(148, 42))
		tools.add_child(b)
	var opts := HBoxContainer.new()
	opts.add_theme_constant_override("separation", 6)
	match _tool:
		"tremper":
			_text("Clique sur ta poterie pour la tremper dans l'émail.")
			for d: Array in DIPS:
				opts.add_child(_toggle(str(d[0]), is_equal_approx(_dip, float(d[1])), func() -> void:
					_dip = float(d[1])
					_build_side(), Vector2(140, 40)))
		"dedans":
			_text("Clique dans l'ouverture pour émailler l'intérieur.")
		"bande":
			_text("Clique à la hauteur où tu veux une bande tout le tour.")
		"pinceau":
			_text("Peins sur ta poterie, dehors ou dedans.")
			for sz: Array in [["Fin", 4.0], ["Moyen", 7.0], ["Gros", 12.0]]:
				opts.add_child(_toggle(str(sz[0]), is_equal_approx(_brush, float(sz[1])), func() -> void:
					_brush = float(sz[1])
					_build_side(), Vector2(110, 40)))
		"tampon":
			var stamps := GridContainer.new()
			stamps.columns = 3
			stamps.add_theme_constant_override("h_separation", 6)
			stamps.add_theme_constant_override("v_separation", 6)
			for st: Array in PotteryArt.STAMPS:
				stamps.add_child(_toggle(str(st[1]), st[0] == _stamp, func() -> void:
					_stamp = str(st[0])
					_build_side(), Vector2(148, 40)))
			_side.add_child(stamps)
			for sz: Array in [["Petit", 18.0], ["Moyen", 26.0], ["Gros", 38.0]]:
				opts.add_child(_toggle(str(sz[0]), is_equal_approx(_stamp_size, float(sz[1])), func() -> void:
					_stamp_size = float(sz[1])
					_build_side(), Vector2(110, 40)))
		"coulures":
			_text("Clique sur ta poterie : l'émail coule du bord en gouttes.")
	_side.add_child(opts)


func _heading(text: String) -> void:
	_side.add_child(_label(text, 28, BLUE))


func _text(text: String) -> void:
	var l := _label(text, 19, Color(BLUE, 0.85))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(460, 0)
	_side.add_child(l)


func _choices(heading: String, options: Array, current: String, pick: Callable) -> void:
	_side.add_child(_label(heading, 21, BLUE))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_side.add_child(row)
	for o: Array in options:
		row.add_child(_toggle(str(o[1]), o[0] == current, func() -> void: pick.call(str(o[0])), Vector2(88, 42)))


func _toggle(text: String, on: bool, press: Callable, size: Vector2) -> Button:
	var b := _button(text, 17, func() -> void:
		Sfx.play("click")
		press.call(), size)
	if on:
		b.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
		b.add_theme_stylebox_override("focus", _box(YELLOW, BLUE, 3, 14))
	return b


# ── Centring and throwing ───────────────────────────────────────

func _centred() -> void:
	Sfx.play("chime")
	_tip.text = "Maman : Bravo ! Ta terre est ben centrée."
	_update_buttons()
	var later := create_tween()
	later.tween_interval(1.0)
	later.tween_callback(func() -> void:
		if _step == "centrer":
			_set_step("monter"))


func stage_input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
	match _step:
		"centrer":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				_pressing = event.pressed
				if event.pressed:
					Sfx.play("squeak", Vector2.INF, -12.0, 0.6)
		"monter":
			_throw_input(event)
		"emailler":
			_glaze_input(event)


func _throw_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _pot.open:
			var top := BASE + Vector2(0, -float(_pot.h))
			if event.position.distance_to(top) < PotteryArt.radius(_pot, 1.0) + 40.0:
				_open_lump()
			return
		_pressing = event.pressed and _pot.open
		_press = event.position
		_grab_t = clampf((BASE.y - event.position.y) / float(_pot.h), 0.0, 1.0)
		if not event.pressed:
			_update_tip()
		return
	if not (event is InputEventMouseMotion and _pressing):
		return
	var rel: Vector2 = event.relative
	var eff := 0.2 + 0.8 * clampf(_wet, 0.0, 1.0)
	var r: Array = _pot.r
	if absf(rel.y) > absf(rel.x):
		var old_h := float(_pot.h)
		var new_h := clampf(old_h - rel.y * 0.9 * eff, 24.0, 300.0)
		# Taller walls get thinner, a squashed pot spreads.
		var k := pow(old_h / new_h, 0.22)
		for i in r.size():
			r[i] = clampf(float(r[i]) * k, 16.0, 175.0)
		_pot.h = new_h
	else:
		var out := rel.x * (1.0 if _press.x >= BASE.x else -1.0)
		for i in r.size():
			var d := (i / 9.0 - _grab_t) * 9.0 / 1.6
			r[i] = clampf(float(r[i]) + out * 0.9 * eff * exp(-d * d), 16.0, 175.0)
	r[0] = maxf(float(r[0]), 30.0)
	var was_wet := _wet >= 0.2
	_wet = maxf(0.0, _wet - rel.length() * 0.0011)
	if was_wet and _wet < 0.2:
		_update_tip()


func _open_lump() -> void:
	_busy = true
	Sfx.play("squeak", Vector2.INF, -10.0, 0.7)
	var from: Array = _pot.r.duplicate()
	var from_h := float(_pot.h)
	_pot.open = true
	var tw := create_tween()
	tw.tween_method(func(f: float) -> void:
		var r: Array = _pot.r
		for i in r.size():
			r[i] = lerpf(float(from[i]), float(PotteryArt.OPENED[i]), f)
		_pot.h = lerpf(from_h, PotteryArt.OPENED_H, f), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_busy = false
		_set_step("monter"))


func _sponge() -> void:
	_wet = 1.0
	Sfx.play("swoosh")
	for k in 16:
		_drops.append([BASE + Vector2(randf_range(-60, 60), -float(_pot.h) - randf_range(60, 140)), Vector2(randf_range(-30, 30), randf_range(0, 80))])
	_update_tip()


func _mom_helps() -> void:
	if _busy:
		return
	_busy = true
	Sfx.play("swoosh")
	_tip.text = "Maman : Attends, je t'aide un peu… regarde mes mains."
	var target := PotteryArt.shaped(_pot, _kind)
	var from: Array = _pot.r.duplicate()
	var from_h := float(_pot.h)
	_pressing = false
	var tw := create_tween()
	tw.tween_method(func(f: float) -> void:
		var r: Array = _pot.r
		for i in r.size():
			r[i] = lerpf(float(from[i]), float(target.r[i]), f)
		_pot.h = lerpf(from_h, float(target.h), f), 0.0, 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_pot.handle = target.handle
		_wet = 1.0
		_busy = false
		_tip.text = "Maman : Voilà ! Tu peux encore la changer si tu veux.")


func _restart_shape() -> void:
	_pot.r = PotteryArt.OPENED.duplicate()
	_pot.h = PotteryArt.OPENED_H
	_wet = 1.0
	Sfx.play("pop")
	_update_tip()


# ── Finishing and glazing ───────────────────────────────────────

func _snap() -> void:
	_undo.append(_pot.duplicate(true))
	if _undo.size() > UNDO:
		_undo.pop_front()
	_update_buttons()


func _take_back() -> void:
	if _undo.is_empty() or _busy:
		return
	_pot = _undo.pop_back()
	Sfx.play("swoosh")
	_build_side()
	_update_buttons()


func _set_part(key: String, value: String) -> void:
	if _pot[key] == value:
		return
	_snap()
	_pot[key] = value
	Sfx.play("pop")
	_build_side()


func _has_glaze() -> bool:
	return _pot.out != "" or _pot["in"] != "" or not _pot.bands.is_empty() or not _pot.marks.is_empty() or not _pot.strokes.is_empty() or _pot.drips != ""


func _glaze_input(event: InputEvent) -> void:
	if _tool == "pinceau":
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var hit := PotteryArt.surface_at(BASE, _pot, event.position)
				if hit.is_empty():
					return
				_snap()
				_stroke = [_glaze, _brush, hit.side, []]
				_pot.strokes.append(_stroke)
				_add_to_stroke(hit)
				_pressing = true
			else:
				_pressing = false
				_stroke = []
				_update_buttons()
		elif event is InputEventMouseMotion and _pressing and not _stroke.is_empty():
			var hit := PotteryArt.surface_at(BASE, _pot, event.position)
			if not hit.is_empty() and hit.side == _stroke[2]:
				_add_to_stroke(hit)
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var at := PotteryArt.surface_at(BASE, _pot, event.position)
	if at.is_empty():
		return
	_snap()
	match _tool:
		"tremper":
			_pot.out = _glaze
			_pot.dip = _dip
			Sfx.play("swoosh")
		"dedans":
			if not _pot.open:
				_undo.pop_back()
				return
			_pot["in"] = _glaze
			Sfx.play("swoosh")
		"bande":
			var t: float = at.t if at.side == "o" else 0.97
			_pot.bands.append([clampf(t - 0.035, 0.0, 1.0), clampf(t + 0.035, 0.0, 1.0), _glaze])
			Sfx.play("pop")
		"tampon":
			if at.side == "o":
				_pot.marks.append([_stamp, "o", at.a, at.t, _glaze, _stamp_size])
			else:
				_pot.marks.append([_stamp, "i", at.u, at.v, _glaze, _stamp_size])
			Sfx.play("pop")
		"coulures":
			_pot.drips = _glaze
			Sfx.play("swoosh")
	_update_buttons()


func _add_to_stroke(hit: Dictionary) -> void:
	var pts: Array = _stroke[3]
	if hit.side == "o":
		pts.append_array([hit.a, hit.t])
	else:
		pts.append_array([hit.u, hit.v])


# ── The kiln ────────────────────────────────────────────────────

func _fire() -> void:
	if _firing or _fired:
		return
	_firing = true
	_busy = true
	_build_side()
	_update_tip()
	Sfx.play("door")
	var tw := create_tween()
	tw.tween_property(self, "_door", 0.0, 0.6 / speed)
	tw.tween_property(self, "_heat", 1.0, 3.6 / speed).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.6 / speed)
	tw.tween_property(self, "_heat", 0.0, 1.6 / speed).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_fired = true
		Sfx.play("door"))
	tw.tween_property(self, "_door", 1.0, 0.7 / speed)
	tw.tween_interval(0.9 / speed)
	tw.tween_property(self, "_reveal", 1.0, 0.6 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_firing = false
		_busy = false
		Sfx.play("chime")
		for k in 14:
			_sparkles.append([Vector2(randf_range(-150, 150), randf_range(-240, 10)), randf_range(0.0, TAU), randf_range(10.0, 22.0)])
		_build_side()
		_update_tip()
		_update_buttons())


func _again() -> void:
	_fired = false
	_reveal = 0.0
	_sparkles.clear()
	_choose()


# ── Drawing the stage ───────────────────────────────────────────

func paint_stage(ci: Control) -> void:
	# The corner of the corridor: wall, wainscot, floorboards.
	ci.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color("#F3E7D6"))
	for k in 12:
		ci.draw_rect(Rect2(k * 64.0, 0, 32.0, 300.0), Color(1, 1, 1, 0.12))
	ci.draw_rect(Rect2(0, 300, STAGE_SIZE.x, 6), Color("#E2D3BE"))
	ci.draw_rect(Rect2(0, 306, STAGE_SIZE.x, STAGE_SIZE.y - 306), Color("#C9965F"))
	for k in 9:
		ci.draw_line(Vector2(0, 330 + k * 22.0), Vector2(STAGE_SIZE.x, 330 + k * 22.0), Color(0.45, 0.28, 0.12, 0.2), 1.5)
	# Maman's own pots on a shelf (not while the kiln stands in front of it).
	if _step == "cuire":
		_paint_kiln(ci)
		return
	ci.draw_rect(Rect2(470, 168, 200, 10), Color("#8A5A30"))
	var mine := [["vase", "turquoise"], ["bol", "miel"], ["tasse", "lavande"]]
	for i in mine.size():
		var p := PotteryArt.sample(mine[i][0])
		p.out = mine[i][1]
		p.marks = []
		p.bands = []
		var sc := 0.22 if mine[i][0] != "vase" else 0.24
		PotteryArt.draw_pot(ci, Vector2(505 + i * 64.0, 166), p, "fired", 0.0, sc)
	var stage := "wet"
	match _step:
		"finir":
			stage = "green"
		"emailler":
			stage = "raw"
	PotteryArt.draw_wheel(ci, BASE, _spin * 0.5)
	var at := BASE
	if _step == "centrer":
		at.x += _wobble * 16.0 * sin(_spin * 1.3)
	PotteryArt.draw_pot(ci, at, _pot, stage, _spin * 0.35)
	if _pressing and _step in ["centrer", "monter"]:
		var t := 0.5 if _step == "centrer" else _grab_t
		var wobble_x := at.x - BASE.x
		PotteryArt.draw_hand(ci, PotteryArt.point(BASE, _pot, -PI / 2.0, t) + Vector2(wobble_x - 4.0, 0), -1, _wet > 0.3)
		PotteryArt.draw_hand(ci, PotteryArt.point(BASE, _pot, PI / 2.0, t) + Vector2(wobble_x + 4.0, 0), 1, _wet > 0.3)
	for d: Array in _drops:
		ci.draw_circle(d[0], 3.5, Color(0.55, 0.78, 1.0, 0.85))
	if _step in ["centrer", "monter"]:
		_paint_gauges(ci)
	if _step == "emailler" and _mouse.x >= 0.0 and _tool == "tampon":
		PotteryArt.stamp(ci, _stamp, _mouse, _stamp_size, Color(PotteryArt.glaze(_glaze, "fired"), 0.45))


# How wet the clay is, and how far from centred.
func _paint_gauges(ci: Control) -> void:
	var font := ThemeDB.fallback_font
	if _step == "centrer":
		ci.draw_string(font, Vector2(20, 34), "Ça branle :", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BLUE)
		ci.draw_rect(Rect2(124, 18, 160, 18), Color.WHITE)
		ci.draw_rect(Rect2(124, 18, 160 * _wobble, 18), Color("#FF8A3D").lerp(Color("#5BD16E"), 1.0 - _wobble))
		ci.draw_rect(Rect2(124, 18, 160, 18), BLUE, false, 2.0)
		return
	ci.draw_string(font, Vector2(20, 34), "Humidité :", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BLUE)
	ci.draw_rect(Rect2(124, 18, 160, 18), Color.WHITE)
	ci.draw_rect(Rect2(124, 18, 160 * _wet, 18), Color("#4FA3E0") if _wet >= 0.2 else Color("#E04F5F"))
	ci.draw_rect(Rect2(124, 18, 160, 18), BLUE, false, 2.0)


func _paint_kiln(ci: Control) -> void:
	if _reveal > 0.0:
		_paint_reveal(ci)
		return
	var s := _kiln_scale()
	PotteryArt.draw_kiln(ci, KILN_BASE, _door, _heat, _time, 1.0, func() -> void:
		PotteryArt.draw_pot(ci, PotteryArt.kiln_shelf(KILN_BASE), _pot, "fired" if _fired else "raw", 0.0, s))
	if _fired:
		for sp: Array in _sparkles:
			var tw := 0.5 + 0.5 * sin(_time * 4.0 + float(sp[1]))
			PotteryArt.stamp(ci, "etoile", PotteryArt.kiln_shelf(KILN_BASE) + sp[0] * s, float(sp[2]) * tw, Color(1, 1, 0.8, 0.9 * tw))
	var font := ThemeDB.fallback_font
	var degrees := int(20.0 + _heat * 1220.0)
	ci.draw_string(font, Vector2(KILN_BASE.x + 175, 380), "%d °C" % degrees, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#E04F5F") if _heat > 0.3 else BLUE)


# Out of the kiln: the pot big on a wooden board, twinkling.
func _paint_reveal(ci: Control) -> void:
	var w := PotteryArt.max_radius(_pot) * 2.0 + (100.0 if _pot.handle != "" else 0.0)
	var h := float(_pot.h) + PotteryArt.max_radius(_pot) * PotteryArt.TILT * 2.0
	var s := minf(1.0, minf(420.0 / w, 330.0 / h)) * (0.4 + 0.6 * _reveal)
	var board := Rect2(BASE.x - 240, BASE.y + 10, 480, 26)
	ci.draw_rect(Rect2(board.position + Vector2(8, 10), board.size), Color(0, 0, 0, 0.18))
	ci.draw_rect(board, Color("#B07A48"))
	ci.draw_rect(Rect2(board.position, Vector2(board.size.x, 6)), Color("#D29A62"))
	var foot := Vector2(BASE.x, BASE.y + 6)
	PotteryArt.draw_pot(ci, foot, _pot, "fired", 0.0, s)
	for sp: Array in _sparkles:
		var tw := 0.5 + 0.5 * sin(_time * 4.0 + float(sp[1]))
		PotteryArt.stamp(ci, "etoile", foot + Vector2(sp[0].x * 1.6, sp[0].y * 1.3), float(sp[2]) * tw * 1.3, Color(1, 0.95, 0.6, 0.95 * tw))


# The pot fits the kiln's chamber.
func _kiln_scale() -> float:
	var w := PotteryArt.max_radius(_pot) * 2.0 + (90.0 if _pot.handle != "" else 0.0)
	var h := float(_pot.h) + PotteryArt.max_radius(_pot) * PotteryArt.TILT * 2.0
	return minf(1.0, minf(200.0 / w, 168.0 / h))


# ── The end ─────────────────────────────────────────────────────

func _finish() -> void:
	if _busy:
		return
	_busy = true
	var img := await render(_pot)
	Sfx.play("chime")
	closed.emit({"image": img, "kind": _kind})
	queue_free()


## The fired pot printed on a transparent sheet, cut to its edges.
func render(pot: Dictionary) -> Image:
	var size := Vector2i(520, 520)
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var w := PotteryArt.max_radius(pot) * 2.0 + (100.0 if pot.handle != "" else 0.0) + 40.0
	var h := float(pot.h) + PotteryArt.max_radius(pot) * PotteryArt.TILT * 2.0 + 40.0
	var s := minf(1.0, minf(500.0 / w, 500.0 / h))
	var base := Vector2(260, 260 + (float(pot.h) * s) / 2.0)
	var node := _Printer.new()
	node.painter = func(ci: CanvasItem) -> void: PotteryArt.draw_pot(ci, base, pot, "fired", 0.0, s)
	vp.add_child(node)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	var used := img.get_used_rect()
	if used.size.x > 0 and used.size.y > 0:
		img = img.get_region(used.grow(2).intersection(Rect2i(Vector2i.ZERO, size)))
	return img


func _leave() -> void:
	if _busy:
		return
	var box := Panel.new()
	box.size = Vector2(560, 230)
	box.position = Vector2(340, 230)
	box.add_theme_stylebox_override("panel", _box(Color.WHITE, BLUE, 5, 22))
	box.z_index = 20
	_panel.add_child(box)
	var q := _label("Tu veux arrêter ?\nTa poterie va retourner dans le sac de terre.", 26, BLUE)
	q.position = Vector2(0, 24)
	q.size = Vector2(560, 90)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(q)
	var keep := _button("Continuer", 22, func() -> void: box.queue_free(), Vector2(210, 54))
	keep.position = Vector2(50, 140)
	keep.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	box.add_child(keep)
	var stop := _button("Arrêter", 22, _quit, Vector2(210, 54))
	stop.position = Vector2(300, 140)
	box.add_child(stop)


func _quit() -> void:
	closed.emit({})
	queue_free()


# ── Kept on the shelf ───────────────────────────────────────────

static func folder() -> String:
	return GameState.slot_dir() + "/poteries"


static func keep(img: Image, kind: String) -> void:
	DirAccess.make_dir_recursive_absolute(folder())
	img.save_png("%s/%s_%s.png" % [folder(), str(int(Time.get_unix_time_from_system() * 1000.0)), kind])
	var names := _names()
	while names.size() > KEEP_MAX:
		DirAccess.remove_absolute(folder() + "/" + str(names.pop_front()))


static func _names() -> Array:
	var dir := DirAccess.open(folder())
	if dir == null:
		return []
	var names := Array(dir.get_files()).filter(func(n: String) -> bool: return n.ends_with(".png"))
	names.sort()
	return names


## Her pots, oldest first.
static func kept() -> Array[Image]:
	var out: Array[Image] = []
	for n: String in _names():
		var img := Image.load_from_file(folder() + "/" + n)
		if img:
			out.append(img)
	return out


static func forget_all() -> void:
	for n: String in _names():
		DirAccess.remove_absolute(folder() + "/" + n)


# ── Little builders ─────────────────────────────────────────────

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, size: int, on_press: Callable, min_size := Vector2(120, 46)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_color_override("font_disabled_color", Color(BLUE, 0.35))
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 14))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 14))
	b.add_theme_stylebox_override("disabled", _box(Color(1, 1, 1, 0.5), Color(BLUE, 0.3), 2, 14))
	b.pressed.connect(on_press)
	return b


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 12
	b.content_margin_right = 12
	return b


class _Stage:
	extends Control

	var studio: PotteryStudio

	func _draw() -> void:
		studio.paint_stage(self)

	func _gui_input(event: InputEvent) -> void:
		studio.stage_input(event)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			studio._mouse = Vector2(-1, -1)


class _PotCard:
	extends Control

	var pot := {}

	func _draw() -> void:
		var w := PotteryArt.max_radius(pot) * 2.0 + (90.0 if pot.handle != "" else 0.0)
		var h := float(pot.h) + PotteryArt.max_radius(pot) * PotteryArt.TILT * 2.0
		var s := minf(0.8, minf(170.0 / w, 190.0 / h))
		PotteryArt.draw_pot(self, Vector2(size.x / 2.0 - (12.0 * s if pot.handle != "" else 0.0), size.y / 2.0 + float(pot.h) * s / 2.0 + 6.0), pot, "fired", 0.0, s)


class _Printer:
	extends Node2D

	var painter: Callable

	func _draw() -> void:
		painter.call(self)
