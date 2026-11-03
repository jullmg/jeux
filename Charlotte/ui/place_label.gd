extends CanvasLayer
## Autoload "PlaceLabel": where Charlotte is, on a little plate at the top middle of the screen ("6e Avenue", "Dépanneur
## Xin-Xin, rue Dandurand"), to help find one's way. A new place = one line in NAMES (key: the scene file's name); a scene that
## isn't there shows no plate (the title screen, tools/). A scene with rooms answers `room_name()` instead (the house).
## Layer 52: above the colour grade, under the bedtime night and every window.

const BLUE := Color("#1D4F91")
const NAMES := {
	"main": "6e Avenue",
	"holt": "Rue Holt",
	"cinquieme": "5e Avenue",
	"dandurand": "Rue Dandurand",
	"ruelle": "Ruelle entre la 5e et la 6e Avenue",
	"ruelle_dandurand": "Ruelle verte, entre la 5e et la 6e Avenue",
	"ruelle_holt": "Ruelle près de Holt, entre la 5e et la 6e Avenue",
	"depanneur": "Dépanneur Xin-Xin, rue Dandurand",
	"ohbon": "Dépanneur Oh Bon!, rue Holt",
}

var _plate: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 52
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.85)
	box.border_color = BLUE
	box.set_border_width_all(2)
	box.set_corner_radius_all(20)
	box.set_content_margin_all(7)
	box.content_margin_left = 22
	box.content_margin_right = 22
	_plate.add_theme_stylebox_override("panel", box)
	_plate.anchor_left = 0.5
	_plate.anchor_right = 0.5
	_plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_plate.offset_top = 20
	_plate.visible = false
	add_child(_plate)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 21)
	_label.add_theme_color_override("font_color", BLUE)
	_plate.add_child(_label)


func _process(_delta: float) -> void:
	var text := _place()
	_plate.visible = text != ""
	if text == _label.text:
		return
	_label.text = text
	# Shrinks to the new name, and the name comes in softly.
	_plate.offset_left = 0.0
	_plate.offset_right = 0.0
	_plate.modulate.a = 0.0
	create_tween().tween_property(_plate, "modulate:a", 1.0, 0.3)


func _place() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	if scene.has_method("room_name"):
		return scene.room_name()
	return NAMES.get(scene.scene_file_path.get_file().get_basename(), "")
