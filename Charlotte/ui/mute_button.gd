extends CanvasLayer
## Autoload "MuteButton": a little speaker button in the top-right corner, on every screen, that cuts all sound
## (music and effects) and brings it back; the M key does the same. Remembered between runs.

const SETTINGS := "user://settings.cfg"

var _button: Button
var _muted := false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		_muted = cfg.get_value("audio", "muted", false)
	_button = Button.new()
	_button.custom_minimum_size = Vector2(52, 52)
	_button.position = Vector2(1280 - 52 - 14, 14)
	_button.focus_mode = Control.FOCUS_NONE
	_button.tooltip_text = "Son (M)"
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.85 if state == "normal" else 1.0)
		box.border_color = Color("#1D4F91")
		box.set_border_width_all(3 if state != "normal" else 2)
		box.set_corner_radius_all(26)
		_button.add_theme_stylebox_override(state, box)
	_button.pressed.connect(toggle)
	_button.draw.connect(_draw_icon)
	add_child(_button)
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_muted = not _muted
	_apply()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "muted", _muted)
	cfg.save(SETTINGS)


func _apply() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), _muted)
	_button.queue_redraw()


# A speaker with sound waves, or crossed out when muted.
func _draw_icon() -> void:
	var c := Vector2(26, 26)
	var blue := Color("#1D4F91")
	_button.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -5), c + Vector2(-7, -5), c + Vector2(1, -12),
		c + Vector2(1, 12), c + Vector2(-7, 5), c + Vector2(-13, 5)]), blue)
	if _muted:
		_button.draw_line(c + Vector2(5, -6), c + Vector2(15, 6), Color("#E04F5F"), 3.5, true)
		_button.draw_line(c + Vector2(15, -6), c + Vector2(5, 6), Color("#E04F5F"), 3.5, true)
	else:
		_button.draw_arc(c + Vector2(2, 0), 7, -0.9, 0.9, 10, blue, 2.5, true)
		_button.draw_arc(c + Vector2(2, 0), 12, -0.9, 0.9, 12, blue, 2.5, true)
