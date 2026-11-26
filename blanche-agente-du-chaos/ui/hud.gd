class_name Hud
extends Control
## L'affichage en cours de partie : score, repas, soupçon, signes au-dessus de Maman, bulles et tutoriel.

signal pause_pressed
## Chaque appui sur le gros bouton, même très bref.
signal grab_pressed

## La tête de Maman, en mètres : la hauteur du visage au-dessus de l'os, et sa demi-largeur avec les cheveux.
const FACE_UP := 0.13
const HEAD_HALF := 0.17
const SIGNS_TOP := 205.0

var sim: Sim
var stage: Stage
var reduced_motion := false
## Vrai tant que le gros bouton à l'écran est enfoncé.
var grab_held := false
## "clavier", "manette" ou "pointeur" : ce que dit le gros bouton.
var input_kind := "clavier"

var _time := 0.0
var _shown_score := 0.0
var _score_pop := 0.0
var _banner := 0.0
## La méfiance qui vient de monter : le temps qu'il reste à dire pourquoi, la raison, et si le conseil a été donné.
var _wary_left := 0.0
var _wary_why := ""
var _wary_jump := 0.0
var _wary_tipped := false
var _flash := 0.0
var _bubbles: Dictionary = {}       # personnage → {panel, left}
var _floaters: Array[Dictionary] = []
var _toast: Label
var _toast_left := 0.0
var _tutorial: PanelContainer
var _tutorial_label: Label
var _tutorial_key := ""
var _has_eaten := false
var _grab: Button
var _pause: Button
var _world: Control
var _top: Control
var _font: Font
var _styles: Dictionary = {}
var _dishes: Array[Texture2D] = []
## Le mot de la bannière du dernier « AU COIN ! » (« DANS TA CAGE ! » dans la salle à manger, parfois).
var _banner_text := Texts.AU_COIN


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load("res://art/fonts/fredoka.tres")
	theme = UiStyle.theme()
	for id in range(1, Levels.COUNT + 1):
		_dishes.append(dish_texture(id))
	_world = _layer(_draw_world)
	_top = _layer(_draw_panels)
	_grab = Button.new()
	_grab.focus_mode = Control.FOCUS_NONE
	_corner(_grab, Control.PRESET_BOTTOM_RIGHT, Rect2(-262, -262, 230, 230))
	for state: String in ["normal", "hover", "pressed"]:
		var s := UiStyle.box(UiStyle.PINK if state != "pressed" else UiStyle.PINK_DARK, 115, UiStyle.CREAM, 7, 0)
		_grab.add_theme_stylebox_override(state, s)
	_grab.button_down.connect(func() -> void:
		grab_held = true
		grab_pressed.emit())
	_grab.button_up.connect(func() -> void: grab_held = false)
	var grab_face := Control.new()
	grab_face.name = "face"
	grab_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grab_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grab_face.draw.connect(_draw_grab.bind(grab_face))
	_grab.add_child(grab_face)
	add_child(_grab)
	_pause = Button.new()
	_pause.focus_mode = Control.FOCUS_NONE
	_corner(_pause, Control.PRESET_TOP_RIGHT, Rect2(-120, 28, 92, 92))
	_pause.pressed.connect(func() -> void: pause_pressed.emit())
	_pause.draw.connect(func() -> void: Icons.pause(_pause, _pause.size / 2.0, 34.0, Color.WHITE))
	add_child(_pause)
	_toast = UiStyle.label("", 34, Color.WHITE)
	_toast.add_theme_color_override("font_outline_color", UiStyle.INK)
	_toast.add_theme_constant_override("outline_size", 12)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 144
	_toast.offset_bottom = 190
	add_child(_toast)
	var foot := VBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.alignment = BoxContainer.ALIGNMENT_END
	_corner(foot, Control.PRESET_CENTER_BOTTOM, Rect2(-430, -320, 860, 296))
	add_child(foot)
	_tutorial = PanelContainer.new()
	_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tutorial_label = UiStyle.label("", 34)
	_tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_label.custom_minimum_size = Vector2(760, 0)
	_tutorial.add_child(_tutorial_label)
	foot.add_child(_tutorial)
	var banner := _layer(_draw_banner)
	banner.name = "banniere"
	clear()


## L'image du plat d'une mission (celle de la première, si elle manque).
static func dish_texture(id: int) -> Texture2D:
	var path := "res://art/ui/plat_%d.png" % id
	return load(path if ResourceLoader.exists(path) else "res://art/ui/plat_1.png")


## Place un contrôle à une distance fixe d'un coin de l'écran.
static func _corner(c: Control, preset: Control.LayoutPreset, at: Rect2) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = at.position.x
	c.offset_top = at.position.y
	c.offset_right = at.end.x
	c.offset_bottom = at.end.y


func _layer(drawer: Callable) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(drawer.bind(c))
	add_child(c)
	return c


func start(sim_: Sim, stage_: Stage) -> void:
	clear()
	sim = sim_
	stage = stage_
	visible = true
	_has_eaten = false


func clear() -> void:
	sim = null
	visible = false
	grab_held = false
	_shown_score = 0.0
	_banner = 0.0
	_flash = 0.0
	_score_pop = 0.0
	_toast_left = 0.0
	_wary_left = 0.0
	_wary_jump = 0.0
	_wary_tipped = false
	if _toast:
		_toast.text = ""
	for b: Dictionary in _bubbles.values():
		b.panel.queue_free()
	_bubbles.clear()
	for f in _floaters:
		f.label.queue_free()
	_floaters.clear()
	_tutorial_key = ""
	if _tutorial:
		_tutorial.visible = false


func toast(text: String, seconds := 2.2) -> void:
	_toast.text = text
	_toast_left = seconds


## Quelqu'un parle déjà.
func has_bubbles() -> bool:
	return not _bubbles.is_empty()


## Fait taire quelqu'un : sa bulle disparaît.
func hush(who: PersonView) -> void:
	if _bubbles.has(who):
		_bubbles[who].panel.queue_free()
		_bubbles.erase(who)


## Une bulle de paroles au-dessus d'un personnage ; elle le suit.
func bubble(who: PersonView, text: String, seconds := 2.0) -> void:
	if _bubbles.has(who):
		_bubbles[who].panel.queue_free()
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiStyle.box(Color.WHITE, 26, UiStyle.INK, 3, 14))
	panel.add_child(UiStyle.label(text, 32))
	add_child(panel)
	move_child(panel, _top.get_index())
	_bubbles[who] = {"panel": panel, "left": maxf(seconds, text.length() / 13.0)}
	who.say(minf(seconds, 1.4))
	_place_bubble(who)


func _floater(text: String, at: Vector3, color: Color, size: int) -> void:
	var l := UiStyle.label(text, size, color)
	l.add_theme_color_override("font_outline_color", UiStyle.INK)
	l.add_theme_constant_override("outline_size", 12)
	add_child(l)
	_floaters.append({"label": l, "at": at, "age": 0.0})


func on_event(e: Dictionary) -> void:
	match e.type:
		"ate":
			var at := stage.dog.head_position() + Vector3(0, 0.25, 0)
			var text := "+%d" % e.points + ("  " + Texts.COMBO % e.mult if e.mult > 1 else "")
			_floater(text, at, UiStyle.GOLD if e.item.size >= Sim.Size.BIG else Color.WHITE, 38 + e.item.size * 12)
			_score_pop = 1.0
			_has_eaten = true
		"caught":
			_banner = 1.35
			var cage := sim.map.corner_kind == "cage" and randf() < 0.5
			_banner_text = Texts.DANS_TA_CAGE if cage else Texts.AU_COIN
		"wary":
			_wary_jump = 0.4
			# Le conseil, une fois affiché, reste le temps d'être lu.
			if _wary_why != "tip" or _wary_left <= 0.0:
				_wary_why = e.why
				_wary_left = 2.0
		"treasure":
			toast(Texts.TREASURE_ALERT % sim.food_name(e.item), 3.0)
		"noise":
			toast(Texts.NOISE_ALERT, 1.6)
		"hint":
			if e.kind != "feint":
				_flash = 1.0
		"dropped":
			if e.combo_lost:
				_floater(Texts.COMBO_LOST, stage.dog.head_position() + Vector3(0, 0.2, 0), Color.WHITE, 36)


func _process(delta: float) -> void:
	if sim == null:
		return
	_time += delta
	_shown_score = move_toward(_shown_score, sim.score, maxf(60.0, absf(sim.score - _shown_score) * 6.0) * delta)
	_score_pop = maxf(0.0, _score_pop - delta * 3.0)
	_banner = maxf(0.0, _banner - delta)
	_flash = maxf(0.0, _flash - delta * 1.1)
	_toast_left -= delta
	_wary_left -= delta
	_wary_jump = maxf(0.0, _wary_jump - delta)
	if not _wary_tipped and sim.suspicion >= 0.4:
		_wary_tipped = true
		_wary_why = "tip"
		if sim.map.corner_kind == "cage" or sim.watcher == "papa":
			_wary_why = "tip_" + ("cage" if sim.map.corner_kind == "cage" else "papa")
		_wary_left = 4.5
	_toast.modulate.a = clampf(_toast_left * 3.0, 0.0, 1.0)
	for who: PersonView in _bubbles.keys():
		_bubbles[who].left -= delta
		if _bubbles[who].left <= 0.0 or not who.visible:
			_bubbles[who].panel.queue_free()
			_bubbles.erase(who)
		else:
			_place_bubble(who)
	for i in range(_floaters.size() - 1, -1, -1):
		var f := _floaters[i]
		f.age += delta
		var l: Label = f.label
		l.position = stage.on_screen(f.at) - Vector2(l.size.x / 2.0, 40.0 + f.age * 90.0)
		l.modulate.a = clampf((1.4 - f.age) * 3.0, 0.0, 1.0)
		if f.age > 1.4:
			l.queue_free()
			_floaters.remove_at(i)
	_update_tutorial()
	_world.queue_redraw()
	_top.queue_redraw()
	_grab.get_node("face").queue_redraw()
	get_node("banniere").queue_redraw()


func _place_bubble(who: PersonView) -> void:
	var panel: PanelContainer = _bubbles[who].panel
	var at := stage.on_screen(who.head_position() + Vector3(0, 0.27, 0))
	panel.reset_size()
	var pos := at - Vector2(panel.size.x / 2.0, panel.size.y + 20.0)
	var partner: PersonView = stage.people.get(sim.chicane_with)
	if sim.activity == "chicane" and partner and (who == stage.mom or who == partner):
		# Chacun sa bulle de son côté : on voit tout de suite qui parle.
		var other: PersonView = partner if who == stage.mom else stage.mom
		if stage.on_screen(who.head_position()).x < stage.on_screen(other.head_position()).x:
			pos = at + Vector2(-panel.size.x - 40.0, -panel.size.y)
		else:
			pos = at + Vector2(40.0, -panel.size.y)
	elif who == stage.mom:
		# À côté de sa tête, de l'autre côté de ses signes.
		pos = at + Vector2(96.0, -panel.size.y / 2.0)
	pos.x = clampf(pos.x, 12.0, size.x - panel.size.x - 12.0)
	pos.y = clampf(pos.y, 150.0, size.y - panel.size.y - 12.0)
	panel.position = pos


func _text(on: CanvasItem, pos: Vector2, text: String, font_size: int, color := UiStyle.INK,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0) -> void:
	if outline > 0:
		on.draw_string_outline(_font, pos, text, align, width, font_size, outline, UiStyle.INK)
	on.draw_string(_font, pos, text, align, width, font_size, color)


## Une boîte arrondie, fabriquée à la première demande puis réutilisée.
func _style(color: Color, radius: int, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
	var key := [color, radius, border, width]
	if not _styles.has(key):
		_styles[key] = UiStyle.box(color, radius, border, width, 0)
	return _styles[key]


## Une barre qui se remplit : les deux boîtes sont préparées à l'avance par couleur.
func _bar(on: CanvasItem, rect: Rect2, value: float, color: Color) -> void:
	on.draw_style_box(_bar_style(Color("dccab0")), rect)
	if value > 0.005:
		var filled := Rect2(rect.position, Vector2(maxf(rect.size.y, rect.size.x * clampf(value, 0.0, 1.0)), rect.size.y))
		on.draw_style_box(_bar_style(color), filled)


func _bar_style(color: Color) -> StyleBoxFlat:
	# Les couleurs qui glissent (le soupçon) sont arrondies pour ne pas fabriquer une boîte par nuance.
	var key := color.to_rgba32() & 0xf8f8f8ff
	if not _styles.has(key):
		_styles[key] = UiStyle._bar(Color.hex(key))
	return _styles[key]


func _card(on: CanvasItem, rect: Rect2) -> void:
	on.draw_style_box(_style(Color(UiStyle.CREAM, 0.95), 26, Color("d8bf9c"), 3), rect)


func _draw_panels(on: Control) -> void:
	if sim == null:
		return
	var w := on.size.x
	var h := on.size.y
	# score et étoiles
	_card(on, Rect2(28, 24, 430, 150))
	_text(on, Vector2(52, 62), Texts.SCORE, 28, UiStyle.INK_SOFT)
	var pop := 1.0 + _score_pop * 0.12
	_text(on, Vector2(52, 118), str(int(round(_shown_score))), int(58 * pop))
	var next := Texts.ALL_STARS
	for i in range(2, -1, -1):
		if sim.score < sim.level.stars[i]:
			next = Texts.NEXT_STAR % int(sim.level.stars[i])
	_text(on, Vector2(200, 112), next, 22, UiStyle.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT, 236.0)
	if sim.multiplier() > 1:
		on.draw_circle(Vector2(400, 66), 34, UiStyle.PINK, true, -1.0, true)
		_text(on, Vector2(366, 80), Texts.COMBO % sim.multiplier(), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 68.0)
	var stars: Array = sim.level.stars
	var track := Rect2(52, 140, 360, 16)
	_bar(on, track, sim.score / float(stars[2]), UiStyle.GOLD)
	for i in 3:
		var x: float = track.position.x + track.size.x * stars[i] / float(stars[2])
		Icons.star(on, Vector2(x, track.get_center().y), 19.0 + (4.0 if sim.score >= stars[i] else 0.0), sim.score >= stars[i])
	# le repas qui cuit
	var meal := Rect2(w / 2.0 - 330, 24, 660, 118)
	_card(on, meal)
	_text(on, Vector2(meal.position.x + 80, 66), str(sim.level.meal), 34, UiStyle.INK, HORIZONTAL_ALIGNMENT_CENTER,
		meal.size.x - 80)
	var left := int(ceil(sim.time_left))
	var urgent := sim.time_left < 20.0
	_bar(on, Rect2(meal.position.x + 130, 90, meal.size.x - 290, 22), 1.0 - sim.time_left / float(sim.level.duration),
		UiStyle.RED if urgent else UiStyle.GREEN)
	# Le plat de la mission, qui dépasse un peu de son carton et sautille quand le temps presse.
	var hop := absf(sin(_time * 7.0)) * 8.0 if urgent and not reduced_motion else 0.0
	on.draw_texture_rect(_dishes[int(sim.level.id) - 1], Rect2(meal.position + Vector2(-8, -12 - hop), Vector2(142, 142)), false)
	_text(on, Vector2(meal.end.x - 140, 113), "%d:%02d" % [left / 60, left % 60], 36,
		UiStyle.RED if urgent else UiStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, 110.0)
	_draw_wary(on, w)
	# visible ou cachée, et ce qu'on a dans la gueule
	var hidden := sim.dog_hidden()
	var badge := Rect2(28, h - 142, 300, 114)
	on.draw_style_box(_style(Color(UiStyle.BLUE if hidden else UiStyle.CREAM, 0.95), 26,
		Color.WHITE if hidden else Color("d8bf9c"), 4), badge)
	Icons.eye(on, badge.position + Vector2(66, 57), 40.0, not hidden)
	_text(on, badge.position + Vector2(124, 74), Texts.HIDDEN if hidden else Texts.VISIBLE, 44,
		Color.WHITE if hidden else UiStyle.INK)
	if not sim.mouth.is_empty():
		# Au-dessus de l'œil, pour laisser la place au tutoriel.
		var chew := Rect2(28, h - 272, 380, 114)
		_card(on, chew)
		_text(on, chew.position + Vector2(24, 46), sim.food_name(sim.mouth), 30, UiStyle.INK, HORIZONTAL_ALIGNMENT_LEFT, 340.0)
		var total: float = Sim.EAT_TIMES[sim.mouth.size]
		_bar(on, Rect2(chew.position + Vector2(24, 68), Vector2(332, 24)), 1.0 - sim.mouth.eat_left / total, UiStyle.PINK)


## La méfiance de Maman : la jauge, son état en un mot et, quand elle monte, pourquoi.
func _draw_wary(on: Control, w: float) -> void:
	var box := Rect2(w - 580, 24, 440, 100)
	_card(on, box)
	var value := sim.suspicion
	var state := 0 if value < 0.25 else (1 if value < 0.55 else 2)
	var color: Color = [UiStyle.GREEN, Color("e07b1c"), UiStyle.RED][state]
	_text(on, Vector2(box.position.x + 24, 60), Texts.SUSPICION_OF.get(sim.watcher, Texts.SUSPICION), 26, UiStyle.INK_SOFT)
	_text(on, Vector2(box.end.x - 184, 60), Texts.WARY_STATES[state], 26, color, HORIZONTAL_ALIGNMENT_RIGHT, 160.0)
	# La barre gonfle un instant quand la jauge saute.
	var swell := _wary_jump * 16.0 if not reduced_motion else 0.0
	var bar := Rect2(box.position.x + 24, 76, box.size.x - 48, 24).grow(swell)
	_bar(on, bar, value, color)
	if _wary_left > 0.0:
		var text: String = Texts.WARY_TIPS[_wary_why.trim_prefix("tip_")] if _wary_why.begins_with("tip_") \
			else Texts.WARY_WHY[_wary_why]
		var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 36
		var chip := Rect2(box.end.x - width, box.end.y + 10, width, 42)
		on.draw_style_box(_style(Color(UiStyle.INK, 0.85), 21), chip)
		_text(on, chip.position + Vector2(18, 30), text, 26, Color.WHITE)


func _grab_state() -> String:
	if sim == null:
		return Texts.GRAB
	if sim.dog_state == Sim.Dog.REACHING and _danger():
		return Texts.LET_GO
	if not sim.mouth.is_empty():
		return Texts.DROP_NOW if _danger() and not sim.dog_hidden() else Texts.DROP
	return Texts.GRAB


func _danger() -> bool:
	if sim.mom_state == Sim.Mom.HINT:
		return sim.warning()
	return sim.mom_state == Sim.Mom.TURN or sim.watching() or sim.snitching()


func _draw_grab(face: Control) -> void:
	if sim == null:
		return
	var c := face.size / 2.0
	var ready := not sim.punished() and (not sim.mouth.is_empty() or not sim.reachable_item().is_empty() or sim.paws_up())
	_grab.modulate = Color(1, 1, 1, 1.0 if ready else 0.5)
	Icons.paw(face, c + Vector2(0, -38), 46.0, Color.WHITE)
	_text(face, Vector2(0, c.y + 50), _grab_state(), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, face.size.x, 8)
	_text(face, Vector2(0, c.y + 86), Texts.KEY_HINTS[input_kind], 24, UiStyle.CREAM, HORIZONTAL_ALIGNMENT_CENTER, face.size.x)


func _draw_world(on: Control) -> void:
	if sim == null:
		return
	# endroits bruyants
	if bool(sim.level.noise):
		for id: String in sim.level.noisy_spots:
			var food: Vector2 = sim.map.spots[id].food
			var spot := Vector3(food.x, sim.map.surface_height(id) + 0.46, food.y)
			if stage.camera.is_position_behind(spot):
				continue
			var at := stage.on_screen(spot)
			Icons.bell(on, at + Vector2(0, sin(_time * 3.0 + food.x * 4.0) * 3.0), 17.0)
	# un œil fermé marque la cachette
	var hide := stage.hidden_center()
	if hide != Vector2.INF:
		var at := stage.on_screen(Vector3(hide.x, 0.02, hide.y))
		on.draw_circle(at, 30.0, Color(0.1, 0.2, 0.55, 0.8), true, -1.0, true)
		Icons.eye(on, at + Vector2(0, -4), 20.0, false, Color.WHITE)
	# l'anneau qui se remplit pendant qu'on tire
	if sim.dog_state == Sim.Dog.REACHING:
		var item := sim.reach_item
		var at := stage.on_screen(stage.item_position(item) + Vector3(0, 0.07, 0))
		var p := clampf(sim.reach_progress / sim.grab_time(item), 0.0, 1.0)
		var color := UiStyle.RED if _danger() else UiStyle.GOLD
		on.draw_arc(at, 58.0, 0, TAU, 48, Color(0.1, 0.06, 0.04, 0.65), 18.0, true)
		on.draw_arc(at, 58.0, -PI / 2.0, -PI / 2.0 + TAU * p, 48, color, 12.0, true)
		_text(on, at + Vector2(-200, 100), sim.food_name(item), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 400.0, 9)
	elif sim.dog_state == Sim.Dog.FREE and sim.mouth.is_empty():
		var near := sim.reachable_item()
		if not near.is_empty():
			var at := stage.on_screen(stage.item_position(near))
			_text(on, at + Vector2(-200, 62), "%s · %d" % [sim.food_name(near), near.points], 28, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER, 400.0, 9)
	# Maman : ce qu'elle fait, et surtout l'indice, toujours à côté de sa tête
	var beat := 1.0 + (0.0 if reduced_motion else sin(_time * 18.0) * 0.1)
	match sim.mom_state:
		Sim.Mom.BUSY when sim.activity != "chicane":
			var text: String = sim.level.get("activity_text", {}).get(sim.activity, Texts.ACTIVITY.get(sim.activity, ""))
			var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 30
			var at := _beside_mom(width / 2.0)
			on.draw_style_box(_style(Color(0.1, 0.06, 0.04, 0.6), 18),
				Rect2(at + Vector2(-width / 2.0, -20), Vector2(width, 38)))
			_text(on, at + Vector2(-width / 2.0 + 15, 7), text, 24, Color.WHITE)
			if sim.mom_out:
				# À la cuisine : une porte rappelle par où elle reviendra.
				on.draw_circle(at + Vector2(0, 58), 32.0, Color(0.1, 0.06, 0.04, 0.6), true, -1.0, true)
				Icons.door(on, at + Vector2(0, 58), 21.0, Color("8a5a35"))
		Sim.Mom.HINT when sim.hint_kind == "retour":
			# Elle revient : ses pas, « J'arrive ! », et le temps qu'il reste avant qu'elle soit dans la porte.
			var at := _door_sign()
			Icons.warning(on, at, 54.0 * beat, UiStyle.RED)
			var width := _font.get_string_size(Texts.COMING_BACK, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 34
			var chip := Rect2(at + Vector2(-width / 2.0, -118), Vector2(width, 48))
			on.draw_style_box(_style(Color(UiStyle.RED, 0.92), 24), chip)
			_text(on, chip.position + Vector2(17, 35), Texts.COMING_BACK, 30, Color.WHITE)
			var f := clampf(sim.mom_left / sim.mom_len, 0.0, 1.0)
			_bar(on, Rect2(at + Vector2(-70, 56), Vector2(140, 14)), f, UiStyle.RED)
		Sim.Mom.HINT:
			if sim.hint_kind == "feint":
				Icons.question(on, _beside_mom(34.0), 34.0)
			else:
				var head := _beside_mom(96.0 if sim.hint_kind == "round" else 72.0)
				Icons.warning(on, head, 54.0 * beat, UiStyle.RED if sim.hint_kind == "real" else Color("e07b1c"))
				if sim.hint_kind == "round":
					Icons.around(on, head + Vector2(0, 4), 84.0, Color("e07b1c"))
				# le temps qui reste avant qu'elle regarde
				var f := clampf(sim.mom_left / sim.mom_len, 0.0, 1.0)
				_bar(on, Rect2(head + Vector2(-70, 56), Vector2(140, 14)), f, UiStyle.RED)
		Sim.Mom.TURN, Sim.Mom.LOOK, Sim.Mom.ROUND:
			var head := _beside_mom(40.0)
			on.draw_circle(head, 40.0, UiStyle.RED, true, -1.0, true)
			on.draw_arc(head, 40.0, 0, TAU, 40, Color.WHITE, 4.0, true)
			Icons.eye(on, head, 29.0, true)
	_draw_people_signs(on, beat)


## Au-dessus des autres : qui va dénoncer (« ! » orange), la visite qui regarde (un œil) ou qui jase (une bulle),
## Charlotte qui glisse un morceau (un cœur).
func _draw_people_signs(on: Control, beat: float) -> void:
	for list: Array in [sim.helpers, sim.seated, sim.walkers]:
		for h: Dictionary in list:
			var view: PersonView = stage.people.get(h.who)
			var signed: bool = h.snitch > 0.0 or h.get("role", "") == "temoin" or h.state == "slip"
			if view == null or not view.visible or not signed:
				continue
			var at := stage.on_screen(view.head_position() + Vector3(0, 0.35, 0))
			if h.snitch > 0.0:
				Icons.warning(on, at, 34.0 * beat, Color("e07b1c"))
			elif h.get("role", "") == "temoin":
				var looking: bool = h.state == "regarde"
				on.draw_circle(at, 24.0, Color(UiStyle.CREAM if looking else UiStyle.INK, 0.88), true, -1.0, true)
				if looking:
					Icons.eye(on, at, 17.0, true)
				else:
					for i in 3:
						on.draw_circle(at + Vector2(-9 + i * 9, 0), 3.4, Color.WHITE, true, -1.0, true)
			elif h.state == "slip":
				Icons.heart(on, at, 20.0 * beat, UiStyle.PINK)


## La porte par où Maman reviendra de la cuisine, à l'écran, gardée dans l'écran.
func _door_sign() -> Vector2:
	var door := sim.map.mom_door
	var at := stage.on_screen(Vector3(door.x, 1.7, door.y))
	return at.clamp(Vector2(90, SIGNS_TOP), size - Vector2(90, 200))


## Où poser un signe de Maman sans cacher son visage : à gauche de sa tête (sa bulle est à droite), à droite si la
## place manque. `half` est la demi-largeur du signe.
func _beside_mom(half: float) -> Vector2:
	if sim.mom_out:
		# Elle est à la cuisine : ses signes sont à la porte par où elle reviendra.
		return _door_sign()
	var face := stage.mom.head_position() + Vector3(0, FACE_UP, 0)
	var at := stage.on_screen(face)
	var gap := stage.on_screen(face + stage.camera.global_basis.x * HEAD_HALF).x - at.x + half + 12.0
	var x := at.x - gap if at.x - gap - half >= 12.0 else at.x + gap
	# Plus bas que les panneaux du haut ; de côté, elle reste visible.
	return Vector2(x, maxf(at.y, SIGNS_TOP))


func _draw_banner(on: Control) -> void:
	if sim == null:
		return
	var size_ := on.size
	# le bord de l'écran rougit quand Maman va se retourner ou regarde
	var alarm := _flash
	if sim.warning():
		alarm = 1.0
	elif sim.watching():
		alarm = maxf(alarm, 0.45)
	if alarm > 0.0:
		var color := Color(UiStyle.RED, 0.55 * alarm)
		on.draw_rect(Rect2(Vector2(6, 6), size_ - Vector2(12, 12)), color, false, 14.0)
	if _banner <= 0.0:
		return
	var grow := minf(1.0, (1.35 - _banner) * 7.0)
	var fade := minf(1.0, _banner * 3.0)
	var shake := Vector2.ZERO
	if not reduced_motion and _banner > 0.8:
		shake = Vector2(sin(_time * 70.0), cos(_time * 53.0)) * 14.0 * (_banner - 0.8)
	# Haut et à droite du centre : on doit voir Maman pointer et Blanche partir.
	var centre := size_ * Vector2(0.69, 0.3) + shake
	on.draw_set_transform(centre, -0.07, Vector2.ONE * (0.4 + 0.6 * grow + sin(grow * PI) * 0.18))
	var burst := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var r := 1.0 if i % 2 == 0 else 0.76
		burst.append(Vector2(cos(a) * 390.0 * r, sin(a) * 160.0 * r))
	on.draw_colored_polygon(burst, Color(UiStyle.GOLD, 0.94 * fade))
	var text := _banner_text
	var font_size := 112 if text == Texts.AU_COIN else 92
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	on.draw_string_outline(_font, Vector2(-width / 2.0, 38), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 24,
		Color(UiStyle.INK, fade))
	on.draw_string(_font, Vector2(-width / 2.0, 38), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UiStyle.RED, fade))
	on.draw_set_transform(Vector2.ZERO)


## La première mission montre quoi faire, selon ce qui se passe.
func _update_tutorial() -> void:
	if not sim.level.get("tutorial", false):
		_tutorial.visible = false
		return
	var key := ""
	if sim.over:
		key = ""
	elif sim.punished():
		key = "corner"
	elif (sim.mom_state == Sim.Mom.HINT or sim.mom_state == Sim.Mom.TURN or sim.watching()) and sim.time > 2.0:
		key = "warning"
		if not sim.mouth.is_empty():
			key = "safe" if sim.dog_hidden() else "drop"
	elif sim.dog_state == Sim.Dog.REACHING:
		key = "keep"
	elif not sim.mouth.is_empty():
		key = "eat"
	elif _has_eaten:
		key = "good" if sim.time < 75.0 else ""
	elif not sim.reachable_item().is_empty():
		key = "hold"
	elif sim.at_corner():
		key = "leave"
	else:
		key = "approach"
	_tutorial.visible = key != ""
	if key != "" and key != _tutorial_key:
		_tutorial_label.text = Texts.TUTORIAL[key]
	_tutorial_key = key
