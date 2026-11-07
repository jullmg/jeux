class_name ChoiceCard
extends CanvasLayer
## A little card that asks what Charlotte wants to do somewhere there is more than one thing to do — her desk:
## draw, or her homework. One big sticker button per choice:
##   ChoiceCard.ask(self, "Qu'est-ce que tu veux faire ?", [{"text": "Dessiner", "note": "…"}, …])
## then `chose(i)` (-1 when she closes it without choosing). It is in the "modal" group, so the notebook, the
## map and the menu keep their keys to themselves while it is open.

signal chose(index: int)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const COLORS := [Color("#8FCBF2"), Color("#FFD866"), Color("#B8E986"), Color("#F7A9C4")]

var question := ""
var choices: Array[Dictionary] = []
var _card: PanelContainer


## Puts the card up under `parent` and gives it back, so its `chose` can be connected.
static func ask(parent: Node, question_text: String, which: Array) -> ChoiceCard:
	var card := ChoiceCard.new()
	card.question = question_text
	for one in which:
		card.choices.append(one as Dictionary)
	parent.add_child(card)
	return card


func _init() -> void:
	layer = 62


func _ready() -> void:
	add_to_group("modal")
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close(-1))
	add_child(dim)
	_card = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = CREAM
	box.border_color = BLUE
	box.set_border_width_all(5)
	box.set_corner_radius_all(24)
	box.set_content_margin_all(26)
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 8
	_card.add_theme_stylebox_override("panel", box)
	add_child(_card)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 14)
	_card.add_child(words)
	var title := Label.new()
	title.text = question
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", BLUE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(title)
	for i in choices.size():
		words.add_child(_button(i))
	var cancel := Label.new()
	cancel.text = "Échap ou clique à côté pour laisser faire"
	cancel.add_theme_font_size_override("font_size", 14)
	cancel.add_theme_color_override("font_color", Color(INK, 0.5))
	cancel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(cancel)
	_card.reset_size()
	_card.position = (Vector2(1280, 720) - _card.size) / 2.0
	_card.pivot_offset = _card.size / 2.0
	_card.scale = Vector2(0.86, 0.86)
	_card.create_tween().tween_property(_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("page")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(-1)


# A sticker button: a fat coloured rectangle with its words, and a second little line written under it.
func _button(i: int) -> Control:
	var one := choices[i]
	var button := Button.new()
	button.custom_minimum_size = Vector2(430, 72)
	button.focus_mode = Control.FOCUS_NONE
	button.text = str(one.get("text", ""))
	button.add_theme_font_size_override("font_size", 26)
	var color: Color = one.get("color", COLORS[i % COLORS.size()])
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color if state == "normal" else color.lightened(0.14)
		box.border_color = BLUE
		box.set_border_width_all(3)
		box.set_corner_radius_all(20)
		box.shadow_color = Color(0, 0, 0, 0.18)
		box.shadow_size = 4
		button.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, BLUE)
	button.pressed.connect(func() -> void: _close(i))
	var note := str(one.get("note", ""))
	if note.is_empty():
		return button
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	stack.add_child(button)
	var small := Label.new()
	small.text = note
	small.add_theme_font_size_override("font_size", 16)
	small.add_theme_color_override("font_color", Color(INK, 0.6))
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(small)
	return stack


func _close(index: int) -> void:
	remove_from_group("modal")
	Sfx.play("click" if index >= 0 else "pop")
	chose.emit(index)
	queue_free()
