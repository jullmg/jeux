class_name UiStyle
extends RefCounted
## Couleurs, thème et petits constructeurs d'interface.

const CREAM := Color("fff3df")
const INK := Color("3a2418")
const INK_SOFT := Color("7a5a45")
const PINK := Color("d9719a")
const PINK_DARK := Color("a94b72")
const GOLD := Color("ffc83d")
const RED := Color("e0453a")
const BLUE := Color("3f6fd8")
const GREEN := Color("5da845")
const SHADE := Color(0.08, 0.05, 0.04, 0.62)


static func box(color: Color, radius := 22, border := Color.TRANSPARENT, width := 0, pad := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(width)
	s.border_color = border
	s.content_margin_left = pad * 1.4
	s.content_margin_right = pad * 1.4
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 4)
	return s


## Un bouton « bonbon » : un épais bord du bas qui s'écrase quand on appuie.
static func candy(color: Color, pressed := false, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var s := box(color, 30, color.darkened(0.32) if border == Color.TRANSPARENT else border, 3)
	s.border_width_bottom = 3 if pressed else 10
	s.content_margin_top += 7 if pressed else 0
	s.content_margin_bottom += 0 if pressed else 7
	s.shadow_size = 3 if pressed else 8
	s.shadow_offset = Vector2(0, 2 if pressed else 7)
	s.anti_aliasing_size = 1.2
	return s


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = load("res://art/fonts/fredoka.tres")
	t.default_font_size = 32
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("normal", "Button", candy(PINK))
	t.set_stylebox("hover", "Button", candy(PINK.lightened(0.12)))
	t.set_stylebox("pressed", "Button", candy(PINK_DARK.lightened(0.08), true))
	t.set_stylebox("disabled", "Button", candy(Color("b9aa9c")))
	var focus := box(Color.TRANSPARENT, 32, GOLD, 7)
	focus.shadow_size = 0
	focus.set_expand_margin_all(5)
	t.set_stylebox("focus", "Button", focus)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("f2ebe2"))
	t.set_color("font_outline_color", "Button", Color(0.25, 0.08, 0.12, 0.45))
	t.set_constant("outline_size", "Button", 5)
	t.set_font_size("font_size", "Button", 40)
	t.set_stylebox("panel", "PanelContainer", box(CREAM, 34, Color("d8bf9c"), 4, 30))
	t.set_stylebox("slider", "HSlider", _bar(Color("e3d2bb")))
	t.set_stylebox("grabber_area", "HSlider", _bar(PINK))
	t.set_stylebox("grabber_area_highlight", "HSlider", _bar(PINK_DARK))
	var slider_focus := box(Color.TRANSPARENT, 14, GOLD, 5, 0)
	slider_focus.shadow_size = 0
	t.set_stylebox("focus", "HSlider", slider_focus)
	return t


static func _bar(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(10)
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func label(text: String, size := 32, color := INK, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, action: Callable, size := 40, width := 420.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, size * 1.9)
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func() -> void:
		Engine.get_main_loop().root.get_node("Sound").play("clic")
		action.call())
	b.focus_entered.connect(func() -> void: Engine.get_main_loop().root.get_node("Sound").play("choix", -6.0))
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	_lively(b)
	return b


## Le bouton choisi grossit un peu, et un reflet court sur sa moitié du haut.
static func _lively(b: Button) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	var grow := func(to: float) -> void:
		if b.is_inside_tree():
			b.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true) \
				.tween_property(b, "scale", Vector2.ONE * to, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b.focus_entered.connect(grow.bind(1.045))
	b.focus_exited.connect(grow.bind(1.0))
	var shine := box(Color(1, 1, 1, 0.15), 22, Color.TRANSPARENT, 0, 0)
	shine.shadow_size = 0
	b.draw.connect(func() -> void:
		if not b.disabled:
			b.draw_style_box(shine, Rect2(14, 8, b.size.x - 28, b.size.y * 0.32)))


static func column(spacing := 18) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", spacing)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	return v


static func row(spacing := 18) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", spacing)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	return h
