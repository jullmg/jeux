class_name BuyDialog
extends CanvasLayer
## The little window that opens before she buys something in a shop: the item's picture and name, its price in big
## numbers, what she has in her pocket and what would be left, and "Acheter" / "Non merci" (Enter or a click to buy, Escape,
## a click outside or "Non merci" to leave it). If she is short of money it says how much is missing and only offers
## "D'accord". `answered(bought)` fires when it closes. It belongs to the "modal" group: the map and the notebook stay shut
## while it is open.

signal answered(bought: bool)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const RED := Color("#C0262C")

var _picture: Texture2D
var _what := ""
var _price := 0.0
var _closed := false


## Opens it over `parent` (a scene) for something called `what` ("Une sloche !", the shop's words) at `price`.
static func ask(parent: Node, picture: Texture2D, what: String, price: float) -> BuyDialog:
	var dialog := BuyDialog.new()
	dialog._picture = picture
	dialog._what = what.trim_suffix("!").strip_edges()
	dialog._price = price
	parent.add_child(dialog)
	return dialog


func _ready() -> void:
	layer = 62
	add_to_group("modal")
	var pocket := GameState.money
	var short := pocket < _price - 0.001
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.45)
	dim.size = Vector2(1280, 720)
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_close(false))
	add_child(dim)
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = BLUE
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(22)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(_label("Acheter ?", 26, BLUE))
	var pic := TextureRect.new()
	pic.texture = _picture
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(112, 112)
	box.add_child(pic)
	box.add_child(_label(_what, 22, INK))
	box.add_child(_label(Quests.money_text(_price), 40, RED if short else BLUE))
	box.add_child(_label("Dans ta poche : %s" % Quests.money_text(pocket), 17, Color(INK, 0.8)))
	if short:
		box.add_child(_label("Il te manque %s !" % Quests.money_text(_price - pocket), 19, RED))
	else:
		box.add_child(_label("Il t'en restera : %s" % Quests.money_text(pocket - _price), 17, Color("#2E7D32")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var yes: Button = null
	if not short:
		yes = _button("Acheter", true)
		yes.pressed.connect(func(): _close(true))
		row.add_child(yes)
	var no := _button("D'accord" if short else "Non merci", short)
	no.pressed.connect(func(): _close(false))
	row.add_child(no)
	for b: Button in [yes, no]:
		if b:
			b.gui_input.connect(func(event: InputEvent):
				if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
					get_viewport().set_input_as_handled()
					_close(false))
	card.reset_size()
	card.position = (Vector2(1280, 720) - card.size) / 2.0
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2.ONE * 0.85
	card.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.12)
	(yes if yes else no).grab_focus.call_deferred()
	Sfx.play("pop")


func _close(bought: bool) -> void:
	if _closed:
		return
	_closed = true
	Sfx.play("click")
	remove_from_group("modal")
	answered.emit(bought)
	queue_free()


func _label(text: String, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 48)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", BLUE)
	button.add_theme_color_override("font_hover_color", BLUE)
	button.add_theme_color_override("font_focus_color", BLUE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = YELLOW if primary else Color.WHITE
		if state == "hover" or state == "focus":
			box.bg_color = box.bg_color.lightened(0.18)
		box.border_color = BLUE
		box.set_border_width_all(3)
		box.set_corner_radius_all(14)
		button.add_theme_stylebox_override(state, box)
	return button
