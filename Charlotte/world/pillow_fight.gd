class_name PillowFight
extends Node2D
## The sleepover's pillow fight (Julien, 2026-11-25: "much cooler: we stand up, take a pillow and fight; clicking on someone
## hits them"). Everyone gets up off the sleeping bags holding a pillow by its end in both hands (`pillow_node`, a tool for
## `Character`: `grips`, `rest_rot`, `swing`; the swing is `Character.pet`). Click a friend: Charlotte runs over and whacks
## them; click the floor to run there (dodging); ← → run, space swings at whoever is closest. The friends run about whacking
## each other and her (`_think`); a blow that lands bursts feathers and a "POF !", the one hit is knocked back, hops and
## laughs; a blow whose target got away is "Raté !". A score (hers / taken) and a time bar stay at the top; after `LENGTH`
## seconds (or "J'arrête") the feathers snow down over everyone, the result is said and `finished` is emitted.
## Built by house.gd `_sleepover_pillows`, which puts everyone back on their bags afterwards.

signal finished(hits: int, taken: int)

const LENGTH := 45.0
## How close (world px) a pillow reaches.
const REACH := 96.0
const RUN := 340.0
const FRIEND_RUN := 230.0
const SWING_LANDS := 0.2
const POF := ["POF !", "PAF !", "BONG !", "FLOUF !", "VLAN !", "POUF !", "BADABOUM !"]
const POF_COLORS := ["#FF5D8F", "#FFB020", "#2FB0AA", "#8E6BF2", "#4FA3E0", "#5DBB4A"]
const PILLOW_COLORS := ["#FFFFFF", "#F7B6D2", "#9DC8F0", "#B6E3B0", "#FFD98A", "#C8B6F2", "#FFB98A", "#8EDDD6"]
## What is said when hit: by Charlotte, Charlotte herself, a friend by a friend.
const OUCH_FRIEND := ["Hé ! Tu vas voir !", "Ha ha ! Pas juste !", "Revanche !", "T'es trop forte, Chachoue !", "Ayoye… non, ça fait pas mal !", "Attends que je t'attrape !"]
const OUCH_HER := ["Ouf !", "Hi hi hi !", "Pas dans la face !", "Je vais me venger !", "Ah ben là !"]
const OUCH_EACH_OTHER := ["Prends ça !", "Bataille !", "Hi hi hi !", "Ha ! Touché !"]
const HINT := "Clique sur un ami pour lui donner un coup d'oreiller !   ← → pour courir, espace pour frapper"

var charlotte: Character
var friends: Array[Character] = []
var left := 0.0
var right := 0.0
var floor_y := 0.0
## Speech bubbles: (who, text).
var say: Callable

var _on := false
var _time := LENGTH
var _hits := 0
var _taken := 0
var _goal_x := NAN
var _target: Character = null
var _cooldown := 0.0
var _swinging := {}
var _stagger := {}
var _brain := {}
var _said := 0.0
## After a blow lands on her, a moment when nobody goes for her.
var _safe := 0.0
var _hud: CanvasLayer
var _score: Label
var _clock: _Clock
var _banner: Label


func _ready() -> void:
	add_to_group("modal")


## Everyone gets up with a pillow, then 3, 2, 1, bataille !
func start() -> void:
	var everyone := _everyone()
	for k in everyone.size():
		var who := everyone[k]
		who.sitting = false
		who.sit_on_ground = false
		who.seat_h = 0.0
		who.fidgets = false
		who.is_walking = false
		who.running = true
		who.position.y = floor_y
		who.carry(null)
		who.carry(pillow_node(Color(PILLOW_COLORS[k % PILLOW_COLORS.size()])))
		_behind(who.held(), true)
	for f in friends:
		_brain[f] = {"target": null, "cd": randf_range(0.6, 1.8), "pace": randf_range(0.8, 1.1), "wait": randf_range(0.0, 0.8), "back_to": NAN, "reach": REACH * 0.75}
	_build_hud()
	var go := create_tween()
	for word: String in ["3", "2", "1", "BATAILLE !"]:
		go.tween_callback(func() -> void:
			_banner.text = word
			_banner.pivot_offset = _banner.size / 2.0
			_banner.scale = Vector2.ONE * 1.6
			_banner.modulate.a = 1.0
			create_tween().tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Sfx.play("pop" if word.length() == 1 else "chime", charlotte.position, -4.0, 1.0 if word.length() > 1 else 0.8))
		go.tween_interval(0.75)
	go.tween_callback(func() -> void:
		_on = true
		create_tween().tween_property(_banner, "modulate:a", 0.0, 0.4))


func _everyone() -> Array[Character]:
	var all: Array[Character] = [charlotte]
	all.append_array(friends)
	return all


# ── Her moves ────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _on:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_W):
		var near := _nearest_to(charlotte, REACH * 1.2)
		if near:
			_swing(charlotte, near)
		get_viewport().set_input_as_handled()


## A click in the world: on a friend, she runs at them and swings; elsewhere, she runs there.
func click_at(p: Vector2) -> void:
	var hit: Character = null
	var best := INF
	for f in friends:
		var box := Rect2(f.position.x - 52.0, f.position.y - 240.0, 104.0, 250.0)
		if box.has_point(p) and absf(f.position.x - p.x) < best:
			best = absf(f.position.x - p.x)
			hit = f
	if hit:
		_target = hit
		_goal_x = NAN
	else:
		_target = null
		_goal_x = clampf(p.x, left, right)


func _nearest_to(who: Character, within: float) -> Character:
	var best: Character = null
	var d := within
	for other in _everyone():
		if other != who and absf(other.position.x - who.position.x) <= d:
			d = absf(other.position.x - who.position.x)
			best = other
	return best


func _process(delta: float) -> void:
	if not _on:
		return
	_time -= delta
	_said -= delta
	_cooldown -= delta
	_safe -= delta
	for who in _stagger.keys():
		_stagger[who] = float(_stagger[who]) - delta
	if _clock:
		_clock.left = clampf(_time / LENGTH, 0.0, 1.0)
		_clock.queue_redraw()
	if _time <= 0.0:
		end()
		return
	_drive_her(delta)
	for f in friends:
		_think(f, delta)


func _busy(who: Character) -> bool:
	return bool(_swinging.get(who, false)) or float(_stagger.get(who, 0.0)) > 0.0


func _drive_her(delta: float) -> void:
	if _busy(charlotte):
		charlotte.is_walking = false
		return
	var axis := Input.get_axis("ui_left", "ui_right")
	if axis != 0.0:
		_target = null
		_goal_x = NAN
		_step(charlotte, signf(axis), RUN, delta)
		return
	if _target and is_instance_valid(_target):
		var dx := _target.position.x - charlotte.position.x
		if absf(dx) > REACH * 0.8:
			_step(charlotte, signf(dx), RUN, delta)
		else:
			charlotte.is_walking = false
			charlotte.facing = 1 if dx >= 0.0 else -1
			if _cooldown <= 0.0:
				_swing(charlotte, _target)
				_target = null
		return
	if not is_nan(_goal_x):
		var dx := _goal_x - charlotte.position.x
		if absf(dx) > 6.0:
			_step(charlotte, signf(dx), RUN, delta, absf(dx))
			return
		_goal_x = NAN
	charlotte.is_walking = false


func _step(who: Character, dir: float, speed: float, delta: float, at_most := INF) -> void:
	who.facing = 1 if dir > 0.0 else -1
	who.is_walking = true
	who.running = true
	who.position.x = clampf(who.position.x + dir * minf(speed * delta, at_most), left, right)


# ── The friends ──────────────────────────────────────────────

# Hit and run: each friend picks someone (Charlotte now and then, less often the more friends there are, and never while she
# is still catching her breath), runs up and swings, then backs off a few steps, waits a moment, and picks again. Backing
# off is what keeps them spread over the room instead of in one heap.
func _think(f: Character, delta: float) -> void:
	var b: Dictionary = _brain[f]
	b.cd = float(b.cd) - delta
	b.wait = float(b.get("wait", 0.0)) - delta
	if _busy(f):
		f.is_walking = false
		return
	if not is_nan(float(b.get("back_to", NAN))):
		var bx: float = b.back_to
		if absf(bx - f.position.x) > 6.0:
			_step(f, signf(bx - f.position.x), FRIEND_RUN * float(b.pace), delta, absf(bx - f.position.x))
			return
		b.back_to = NAN
		b.wait = randf_range(0.3, 1.1)
		b.target = null
		f.is_walking = false
		f.express("grin", 0.8)
	if float(b.wait) > 0.0:
		f.is_walking = false
		return
	var t: Character = b.target
	if t == null or not is_instance_valid(t):
		var her := _safe <= 0.0 and randf() < clampf(1.0 / float(friends.size()), 0.15, 0.45)
		t = charlotte if her else friends.pick_random()
		if t == f:
			t = charlotte if _safe <= 0.0 else null
		if t == null:
			b.wait = 0.4
			return
		b.target = t
		b.reach = REACH * randf_range(0.6, 0.85)
	if t == charlotte and _safe > 0.0:
		b.target = null
		return
	var dx := t.position.x - f.position.x
	# Going at Charlotte they come a little slower, so she can see them coming and run off.
	var speed := FRIEND_RUN * float(b.pace) * (0.75 if t == charlotte else 1.0)
	if absf(dx) > float(b.reach):
		_step(f, signf(dx), speed, delta)
	else:
		f.is_walking = false
		f.facing = 1 if dx >= 0.0 else -1
		if float(b.cd) <= 0.0:
			_swing(f, t)
			b.cd = randf_range(0.9, 1.8)
			# Then off they go, a few steps back the way they came.
			b.back_to = clampf(f.position.x - signf(dx if dx != 0.0 else 1.0) * randf_range(140.0, 330.0), left, right)


# ── Blows ────────────────────────────────────────────────────

func _swing(who: Character, at: Character) -> void:
	if _busy(who):
		return
	if who == charlotte:
		_cooldown = 0.45
	_swinging[who] = true
	var dx := at.position.x - who.position.x
	if dx != 0.0:
		who.facing = 1 if dx > 0.0 else -1
	who.pet(0.4, 0.0)
	var pillow := who.held()
	if pillow:
		_behind(pillow, false)
	who.express("effort", 0.6)
	Sfx.play("swoosh", who.position, -5.0, randf_range(0.9, 1.25))
	var land := create_tween()
	land.tween_interval(SWING_LANDS)
	land.tween_callback(func() -> void:
		if not _on or not is_instance_valid(at):
			return
		# Her own blows are forgiving (a child is clicking): a longer reach, and a friend still reeling can be hit again.
		var ok := absf(at.position.x - who.position.x) <= REACH * 1.6 if who == charlotte \
			else absf(at.position.x - who.position.x) <= REACH * 1.15 and float(_stagger.get(at, 0.0)) <= 0.0 and not (at == charlotte and _safe > 0.0)
		if ok:
			_hit(who, at)
		elif who == charlotte or at == charlotte:
			_pop("Raté !", at.position + Vector2(0, -150.0), Color("#8A94A6"), 30))
	land.tween_interval(0.3)
	land.tween_callback(func() -> void:
		_swinging[who] = false
		if pillow and is_instance_valid(pillow):
			_behind(pillow, true))


func _hit(by: Character, target: Character) -> void:
	var dir := signf(target.position.x - by.position.x)
	if dir == 0.0:
		dir = float(by.facing)
	_stagger[target] = 0.55
	target.is_walking = false
	target.facing = -1 if dir > 0.0 else 1
	target.express("surprised", 0.45)
	var back := create_tween()
	back.tween_property(target, "position:x", clampf(target.position.x + dir * 54.0, left, right), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.parallel().tween_property(target, "position:y", floor_y - 18.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.parallel().tween_property(target, "rotation", -dir * 0.12, 0.13)
	back.tween_property(target, "position:y", floor_y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	back.parallel().tween_property(target, "rotation", 0.0, 0.2)
	back.tween_callback(func() -> void: target.express("laugh", 1.2))
	# The pillow squashes on the blow.
	var pillow := by.held()
	if pillow:
		var sq := create_tween()
		var base := pillow.scale
		sq.tween_property(pillow, "scale", base * Vector2(1.25, 0.8), 0.07)
		sq.tween_property(pillow, "scale", base, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var at := target.position + Vector2(-dir * 10.0, -175.0)
	for k in randi_range(6, 9):
		_feather(at, Vector2(dir * randf_range(40.0, 220.0) + randf_range(-60.0, 60.0), randf_range(-260.0, -60.0)))
	_pop(POF.pick_random(), target.position + Vector2(randf_range(-50.0, 50.0), randf_range(-250.0, -200.0)), Color(POF_COLORS.pick_random()), 44)
	Sfx.play("pop", target.position, -2.0, randf_range(0.75, 1.05))
	if by == charlotte:
		_hits += 1
		# Revenge: the one she hit often comes after her.
		if _brain.has(target) and randf() < 0.6:
			_brain[target].target = charlotte
			_brain[target].back_to = NAN
			_brain[target].wait = 0.5
	if target == charlotte:
		_taken += 1
		_safe = 1.4
	_update_score()
	if _said <= 0.0 and randf() < 0.5:
		_said = 1.6
		var line: String = (OUCH_FRIEND if by == charlotte else OUCH_HER if target == charlotte else OUCH_EACH_OTHER).pick_random()
		if say.is_valid():
			say.call(target, line)


# At rest the pillow peeks over the shoulder from behind her (first in the puppet's drawing order); for the blow it comes in
# front of her, where `Character.carry` put it (just under the near arm).
static func _behind(pillow: Node2D, back: bool) -> void:
	if pillow == null or pillow.get_parent() == null:
		return
	if not pillow.has_meta("front_index"):
		pillow.set_meta("front_index", pillow.get_index())
	pillow.get_parent().move_child(pillow, 0 if back else int(pillow.get_meta("front_index")))


# A word that pops up and floats off.
func _pop(text: String, at: Vector2, color: Color, size: int) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 10)
	l.z_index = 20
	add_child(l)
	l.position = at - l.get_minimum_size() / 2.0
	l.pivot_offset = l.get_minimum_size() / 2.0
	l.rotation = randf_range(-0.2, 0.2)
	l.scale = Vector2.ONE * 0.3
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(l, "position:y", l.position.y - 40.0, 0.5)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


func _feather(at: Vector2, velocity: Vector2, life := 6.0) -> void:
	var f := _Feather.new()
	f.position = at
	f.velocity = velocity
	f.floor_y = floor_y + randf_range(-4.0, 22.0)
	f.life = life
	f.rotation = randf() * TAU
	f.tint = Color("#FFFFFF") if randf() < 0.75 else Color("#F4EEE2")
	f.scale = Vector2.ONE * randf_range(0.8, 1.25)
	f.z_index = 15
	add_child(f)


func _update_score() -> void:
	if _score:
		_score.text = "Tes coups d'oreiller : %d      On t'a eue : %d" % [_hits, _taken]


# ── The end ──────────────────────────────────────────────────

## Time's up (or she stops): pillows down, feathers snow over the whole room, the result, then `finished`.
func end() -> void:
	if not _on:
		return
	_on = false
	for who in _everyone():
		who.is_walking = false
		who.running = false
		who.rotation = 0.0
		who.position.y = floor_y
		who.express("laugh", 3.0)
	var cam := get_viewport().get_camera_2d()
	var mid := cam.get_screen_center_position() if cam else charlotte.position
	for k in 70:
		_feather(Vector2(mid.x + randf_range(-660.0, 660.0), mid.y - randf_range(380.0, 700.0)), Vector2(randf_range(-30.0, 30.0), randf_range(10.0, 60.0)), 9.0)
	_banner.text = "Fin de la bataille !"
	_banner.pivot_offset = _banner.size / 2.0
	_banner.modulate.a = 1.0
	_banner.scale = Vector2.ONE * 1.4
	create_tween().tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("chime", charlotte.position)
	var steps := create_tween()
	steps.tween_interval(1.0)
	steps.tween_callback(func() -> void:
		for who in _everyone():
			who.carry(null))
	steps.tween_interval(1.4)
	steps.tween_callback(func() -> void:
		if say.is_valid():
			say.call(charlotte, verdict()))
	steps.tween_interval(3.2)
	steps.tween_callback(func() -> void: finished.emit(_hits, _taken))


func verdict() -> String:
	if _hits == 0:
		return "Haha ! J'ai rien touché, mais j'ai ri en masse !"
	if _hits > _taken:
		return "%d coups d'oreiller ! J'ai gagné la bataille !" % _hits
	if _hits == _taken:
		return "%d à %d ! Égalité de fous rires !" % [_hits, _taken]
	return "Ouf ! %d coups pour moi… vous êtes trop forts !" % _hits


# ── Pictures ─────────────────────────────────────────────────

## A pillow to swing: held by its top end in both hands (`grips`), raised up and back over the shoulder (`rest_rot`), and on
## `Character.pet` brought over the head and down in front (`swing`).
static func pillow_node(color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = pillow_texture(color)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.offset = Vector2(0, 62)
	s.scale = Vector2.ONE * 1.15
	s.rotation = -2.5
	s.set_meta("rest_rot", -2.5)
	s.set_meta("swing", -2.5)
	s.set_meta("grips", [Vector2(-14, 6), Vector2(14, 6)])
	return s


## Canvas 100x140: a plump pillow, its gathered end at the top, piping round it, little corner ears, a few dots.
static func pillow_texture(color: Color) -> ImageTexture:
	var light := color.lightened(0.35).to_html(false)
	var dark := color.darkened(0.18).to_html(false)
	var line := color.darkened(0.42).to_html(false)
	var s := '<defs><linearGradient id="pl" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#%s"/><stop offset="0.55" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs>' % [light, color.to_html(false), dark]
	var shape := "M20 12 Q50 4 80 12 Q98 70 84 128 Q50 138 16 128 Q2 70 20 12 Z"
	for c in [[20, 12, -1, -1], [80, 12, 1, -1], [84, 128, 1, 1], [16, 128, -1, 1]]:
		s += '<path d="M%d %d l%d %d l%d %d Z" fill="#%s" stroke="#%s" stroke-width="2" stroke-linejoin="round"/>' % [c[0] - c[2] * 4, c[1], c[2] * 10, c[3] * 8, -c[2] * 2, -c[3] * 12, dark, line]
	s += '<path d="%s" fill="url(#pl)" stroke="#%s" stroke-width="3" stroke-linejoin="round"/>' % [shape, line]
	s += '<path d="M24 20 Q50 13 76 20 Q90 70 78 120 Q50 128 22 120 Q10 70 24 20 Z" fill="none" stroke="#FFFFFF" stroke-width="1.8" stroke-dasharray="4 4" opacity="0.7"/>'
	for d in [[38, 44], [62, 58], [42, 84], [64, 100], [50, 70], [34, 110]]:
		s += '<circle cx="%d" cy="%d" r="3.2" fill="#FFFFFF" opacity="0.65"/>' % d
	s += '<path d="M14 40 Q10 70 18 110" stroke="#FFFFFF" stroke-width="6" fill="none" opacity="0.4" stroke-linecap="round"/>'
	s += '<path d="M40 12 Q50 22 60 12" stroke="#%s" stroke-width="2" fill="none" opacity="0.6"/>' % line
	return InteriorArt.tex(100, 140, s)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 55
	add_child(_hud)
	var top := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#FBF6EA")
	box.border_color = Color("#1D4F91")
	box.set_border_width_all(4)
	box.set_corner_radius_all(18)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 8
	box.content_margin_bottom = 10
	top.add_theme_stylebox_override("panel", box)
	top.position = Vector2(300, 64)
	top.custom_minimum_size = Vector2(680, 0)
	_hud.add_child(top)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	top.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	_score = Label.new()
	_score.add_theme_font_size_override("font_size", 24)
	_score.add_theme_color_override("font_color", Color("#1D4F91"))
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_score)
	var stop := Button.new()
	stop.text = "J'arrête"
	stop.focus_mode = Control.FOCUS_NONE
	stop.add_theme_font_size_override("font_size", 18)
	stop.pressed.connect(end)
	row.add_child(stop)
	_clock = _Clock.new()
	_clock.custom_minimum_size = Vector2(0, 14)
	col.add_child(_clock)
	var hint := Label.new()
	hint.text = HINT
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("#6A6A78"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 96)
	_banner.add_theme_color_override("font_color", Color("#FFD23F"))
	_banner.add_theme_color_override("font_outline_color", Color("#1D4F91"))
	_banner.add_theme_constant_override("outline_size", 22)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.position = Vector2(0, 220)
	_banner.size = Vector2(1280, 160)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_banner)
	_update_score()


# The time left, a bar that empties from yellow to pink.
class _Clock:
	extends Control
	var left := 1.0

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("#E3DCCB"))
		draw_rect(Rect2(r.position, Vector2(r.size.x * left, r.size.y)), Color("#FFD23F").lerp(Color("#FF5D8F"), 1.0 - left))
		draw_rect(r, Color("#1D4F91"), false, 2.0)


# A feather: bursts out, then drifts down rocking from side to side, lies on the floor a while and fades.
class _Feather:
	extends Node2D
	var velocity := Vector2.ZERO
	var floor_y := 0.0
	var life := 6.0
	var tint := Color.WHITE
	var _t := randf() * TAU
	var _landed := false

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if life < 1.0:
			modulate.a = life
		if _landed:
			return
		_t += delta
		velocity *= pow(0.12, delta)
		velocity.y += 26.0 * delta
		position += velocity * delta + Vector2(sin(_t * 3.2) * 38.0 * delta, 30.0 * delta)
		rotation = sin(_t * 3.2) * 0.9
		if position.y >= floor_y:
			position.y = floor_y
			rotation = randf_range(-1.6, -1.4) if randf() < 0.5 else randf_range(1.4, 1.6)
			_landed = true

	func _draw() -> void:
		var vane := PackedVector2Array()
		for k in 13:
			var a := float(k) / 12.0
			vane.append(Vector2(sin(a * PI) * 4.5 * (1.0 - a * 0.3), -10.0 + a * 20.0))
		for k in range(12, -1, -1):
			var a := float(k) / 12.0
			vane.append(Vector2(-sin(a * PI) * 3.8 * (1.0 - a * 0.3), -10.0 + a * 20.0))
		draw_colored_polygon(vane, tint)
		draw_polyline(vane + PackedVector2Array([vane[0]]), Color(0.7, 0.68, 0.64, 0.6), 0.8, true)
		draw_line(Vector2(0, -10), Vector2(0, 13), Color(0.75, 0.7, 0.62), 1.0, true)
		for k in 4:
			var y := -6.0 + k * 4.0
			draw_line(Vector2(0, y), Vector2(3.0, y + 2.0), Color(0.82, 0.8, 0.76, 0.7), 0.7, true)
