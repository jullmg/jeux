class_name FilmMenu
extends CanvasLayer
## The movie night's choice of film: a card with one poster per film (a still from the film itself, moving when the mouse is
## over it), its title under it, in a scrolling grid so any number of films fits (it used to run off the top and the bottom).
##   FilmMenu.ask(self, ["film", "grinch", …])  →  `chose(id)`, `""` when she closes it.

signal chose(id: String)

const BLUE := Color("#1D4F91")
const CREAM := Color("#FBF6EA")
const SCALE := 1.3
const COLUMNS := 3

var films: Array = []
var _close_called := false


static func ask(parent: Node, ids: Array) -> FilmMenu:
	var menu := FilmMenu.new()
	menu.films = ids
	parent.add_child(menu)
	return menu


func _init() -> void:
	layer = 62


func _ready() -> void:
	add_to_group("modal")
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close(""))
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = CREAM
	box.border_color = BLUE
	box.set_border_width_all(5)
	box.set_corner_radius_all(24)
	box.set_content_margin_all(22)
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 12
	card.add_theme_stylebox_override("panel", box)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var title := Label.new()
	title.text = "Quel film on regarde ?"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BLUE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(COLUMNS * (TvShows.SIZE.x * SCALE + 22.0) + 20.0, minf(ceil(films.size() / float(COLUMNS)) * (TvShows.SIZE.y * SCALE + 38.0), 540.0))
	col.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for id: String in films:
		grid.add_child(_poster(id))
	var hint := Label.new()
	hint.text = "Molette pour voir les autres films  •  Échap pour laisser faire" if films.size() > COLUMNS * 3 else "Échap ou clique à côté pour laisser faire"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.23, 0.23, 0.28, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	Sfx.play("page")


func _poster(id: String) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 2)
	var still := _Still.new()
	still.id = id
	still.custom_minimum_size = TvShows.SIZE * SCALE + Vector2(8, 8)
	still.pressed.connect(func() -> void: _close(id))
	cell.add_child(still)
	var name_label := Label.new()
	name_label.text = str(TvShows.INFO[id].name)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", BLUE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(name_label)
	return cell


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close("")


func _close(id: String) -> void:
	if _close_called:
		return
	_close_called = true
	remove_from_group("modal")
	Sfx.play("click" if id != "" else "pop")
	chose.emit(id)
	queue_free()


# One poster: a still from the film in a frame; under the mouse it plays and the frame lights up. The picture is a child
# scaled up as a node (the films call `draw_set_transform` themselves, which would replace a transform set here).
class _Still:
	extends Control
	signal pressed
	var id := ""
	var _t := 0.0
	var _hover := false
	var _pic: _Pic

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_pic = _Pic.new()
		_pic.id = id
		_pic.position = Vector2(4, 4)
		_pic.size = TvShows.SIZE
		_pic.scale = Vector2.ONE * FilmMenu.SCALE
		_pic.clip_contents = true
		_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_pic)
		mouse_entered.connect(func() -> void:
			_hover = true
			Sfx.play("pop"))
		mouse_exited.connect(func() -> void: _hover = false)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()

	func _process(delta: float) -> void:
		if _hover:
			_t += delta
			_pic.t = _t
			_pic.queue_redraw()
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#FFD23F") if _hover else Color("#1D4F91"), true)


class _Pic:
	extends Control
	var id := ""
	var t := 0.0

	func _draw() -> void:
		# A still from the first scene, moving while the mouse is over it.
		TvShows.draw(id, self, t, 12.0 + t)
