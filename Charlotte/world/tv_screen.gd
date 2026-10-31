class_name TvScreen
extends Control
## A TV's picture, for any house. Click it: it turns on; click again: next channel; after the last one, off.
## The shows come from TvShows (`channels`: which ones this TV gets), with a burst of static between them,
## and the screen's glow lights the room. Interactable like StrayCat (see PlayerControl).

const SWITCH_TIME := 0.3

## This TV's channels (TvShows ids), in order.
var channels: Array[String] = TvShows.ALL.duplicate()
## Index into `channels`; -1 = off.
var channel := -1
## Where Charlotte stands to use it, and the room glow it drives (both set by the house).
var stand_x := 0.0
var glow: Sprite2D

var _t := 0.0
var _switching := 0.0
var _osd := 0.0
var _on_for := 0.0


func _ready() -> void:
	size = TvShows.SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("interactable")
	_update_glow()


func _process(delta: float) -> void:
	_t += delta
	_switching = maxf(_switching - delta, 0.0)
	_osd = maxf(_osd - delta, 0.0)
	_on_for += delta
	if glow and channel >= 0:
		glow.modulate.a = 0.75 + 0.15 * sin(_t * 7.0) + 0.1 * sin(_t * 17.0) if _switching == 0.0 else 0.4 + randf() * 0.4
	if channel >= 0:
		queue_redraw()


# ── Interactable ────────────────────────────────────────────────

func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	return get_global_rect().grow(6.0).has_point(p)


func approach_x(_from_x: float) -> float:
	return stand_x


func focus_x() -> float:
	return get_global_rect().get_center().x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	channel += 1
	if channel >= channels.size():
		channel = -1
	_switching = SWITCH_TIME if channel >= 0 else 0.0
	_osd = 2.0
	_on_for = -SWITCH_TIME
	_update_glow()
	queue_redraw()


func _update_glow() -> void:
	if glow:
		glow.visible = channel >= 0
		if channel >= 0:
			glow.self_modulate = TvShows.INFO[channels[channel]].glow


# ── Drawing ─────────────────────────────────────────────────────

func _draw() -> void:
	if channel < 0:
		return
	if _switching > 0.0:
		_static()
		return
	TvShows.draw(channels[channel], self, _t, _on_for)
	# Scanlines and a soft vignette, like an old-fashioned picture.
	for y in range(0, int(TvShows.SIZE.y), 3):
		draw_rect(Rect2(0, y, TvShows.SIZE.x, 1), Color(0, 0, 0, 0.06))
	if _osd > 0.0:
		var a := clampf(_osd, 0.0, 1.0)
		TvShows._text(self, "%d" % (channel + 1), Vector2(TvShows.SIZE.x - 22, 18), 16, Color(0.4, 1.0, 0.5, a), 20, HORIZONTAL_ALIGNMENT_RIGHT)


func _static() -> void:
	draw_rect(Rect2(Vector2.ZERO, TvShows.SIZE), Color(0.3, 0.3, 0.32))
	for i in 160:
		var g := randf()
		draw_rect(Rect2(randf() * TvShows.SIZE.x, randf() * TvShows.SIZE.y, randf_range(2, 9), 2), Color(g, g, g))
