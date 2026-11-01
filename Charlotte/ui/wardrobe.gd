class_name Wardrobe
extends CanvasLayer
## Charlotte's wardrobe, opened from the drawers in her bedroom: she shows in a mirror on the left and
## every choice on the right dresses her right away. "C'est parfait !" keeps the outfit, "Annuler"
## (or Échap) leaves her as she was.

signal closed(look: CharacterLook)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#F6EFE4")

const OUTFITS := [["dress", "Robe"], ["tshirt", "T-shirt"], ["sweater", "Chandail"], ["hoodie", "Coton ouaté"],
	["overalls", "Salopette"], ["coat", "Manteau"]]
const DRESS_PATTERNS := [["none", "Uni"], ["dots", "Pois"], ["flowers", "Fleurs"], ["hearts", "Cœurs"], ["stars", "Étoiles"], ["stripes", "Rayures"]]
const TOP_PATTERNS := [["none", "Uni"], ["stripes", "Rayures"], ["heart", "Gros cœur"], ["star", "Grande étoile"], ["zigzag", "Zigzag"],
	["dots", "Pois"], ["flowers", "Fleurs"], ["hearts", "Cœurs"], ["stars", "Étoiles"], ["bike", "Vélo"]]
const SLEEVES := [["puff", "Bouffantes"], ["short", "Courtes"], ["long", "Longues"]]
const LEGWEAR := [["socks", "Chaussettes"], ["tights", "Collants"], ["pants", "Pantalon"]]
const SHOES := [["mary_jane", "Souliers"], ["sneaker", "Espadrilles"], ["boot", "Bottes"], ["rain_boot", "Bottes de pluie"]]
const HATS := [["", "Rien"], ["bow", "Boucle"], ["headband", "Serre-tête"], ["tuque", "Tuque"], ["cap", "Casquette"],
	["beret", "Béret"], ["crown", "Couronne"], ["witch", "Sorcière"], ["cat_ears", "Oreilles de chat"]]
const COLORS := ["#FFD23F", "#FF8A3D", "#E04F5F", "#FF5D8F", "#FFB3C7", "#C2185B", "#7E57C2", "#5C6BC0",
	"#4A6FA5", "#1FB5C4", "#A5D6A7", "#3E8E5A", "#8D6E63", "#F4F1EA", "#FFFFFF", "#2E3440"]
const LEG_COLORS := ["#FFFFFF", "#FFB3C7", "#FF5D8F", "#E04F5F", "#FFD23F", "#7E57C2", "#4A6FA5", "#2F3E5C",
	"#3A3A3A", "#8D6E63", "#5E6B3A", "#2B2B2B"]
const HAIR_STYLES := [["long_wavy", "Longs ondulés"], ["long_straight", "Longs raides"], ["bob", "Carré"], ["ponytail", "Queue de cheval"],
	["pigtails", "Couettes"], ["braids", "Tresses"], ["bun", "Chignon"], ["space_buns", "Deux chignons"], ["curly", "Bouclés"], ["short", "Courts"]]
# Natural shades first (hers is the first), then a few fun ones.
const HAIR_COLORS := ["#B0623A", "#8A3B1E", "#5A3A22", "#3A2618", "#1E1612", "#C9A060", "#E3C78A",
	"#FF7BA3", "#B388FF", "#4FA3E0", "#3FBFA0"]
const GLASSES := ["#2B2B2B", "#8A4B2A", "#C0392B", "#4A6FA5", "#FF5D8F", "#7E57C2"]
# Charlotte's exact-colour overrides that a new clothing colour must drop (skin, hair and eyes stay).
const CLOTHING_OVERRIDES := ["cloth_", "accent_", "shoe_"]

var _look: CharacterLook
var _preview: Character
var _mirror: Control
var _tabs: TabContainer
var _root: Control


func _init(start: CharacterLook) -> void:
	layer = 60
	_look = start.duplicate(true)


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = _theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(50, 30)
	panel.size = Vector2(1180, 660)
	panel.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 6, 26))
	_root.add_child(panel)
	var title := _text("La garde-robe de Charlotte", 34)
	title.position = Vector2(40, 18)
	title.size = Vector2(1100, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_build_mirror(panel)
	_tabs = TabContainer.new()
	_tabs.position = Vector2(400, 78)
	_tabs.size = Vector2(750, 482)
	panel.add_child(_tabs)
	for tab_name in ["Vêtement", "Jambes et pieds", "Coiffure", "Chapeaux", "Accessoires"]:
		var scroll := ScrollContainer.new()
		scroll.name = tab_name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_tabs.add_child(scroll)
	_build_buttons(panel)
	_refresh()
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(null)


# ── Layout ──────────────────────────────────────────────────────

func _build_mirror(panel: Control) -> void:
	_mirror = Panel.new()
	_mirror.position = Vector2(30, 78)
	_mirror.size = Vector2(340, 482)
	_mirror.clip_contents = true
	_mirror.add_theme_stylebox_override("panel", _box(Color("#E3F0F4"), Color("#C8A27A"), 12, 160))
	panel.add_child(_mirror)
	var glare := Polygon2D.new()
	glare.polygon = PackedVector2Array([Vector2(40, 40), Vector2(110, 40), Vector2(30, 260), Vector2(-40, 260)])
	glare.color = Color(1, 1, 1, 0.35)
	_mirror.add_child(glare)
	var rug := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 32:
		pts.append(Vector2(170, 448) + Vector2.from_angle(TAU * i / 32.0) * Vector2(120, 22))
	rug.polygon = pts
	rug.color = Color("#FFB3C7")
	_mirror.add_child(rug)


func _build_buttons(panel: Control) -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(30, 580)
	bar.size = Vector2(1120, 56)
	bar.add_theme_constant_override("separation", 14)
	panel.add_child(bar)
	_action(bar, "Au hasard", _randomize)
	_action(bar, "Comme d'habitude", func():
		_look = CharacterLook.usual()
		_refresh())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_action(bar, "Annuler", func(): _close(null))
	var ok := _action(bar, "C'est parfait !", func(): _close(_look))
	ok.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	ok.add_theme_stylebox_override("hover", _box(YELLOW.lightened(0.3), BLUE, 3, 16))


func _action(bar: HBoxContainer, label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(170, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(on_press)
	bar.add_child(b)
	return b


# Rebuilds the preview and every tab, so the selected choices are highlighted.
func _refresh() -> void:
	if _preview:
		_preview.queue_free()
	_preview = Character.new()
	_preview.look = _look.duplicate(true)
	_preview.position = Vector2(170, 448)
	_preview.scale = Vector2.ONE * 0.8
	_mirror.add_child(_preview)
	var pages := []
	for i in _tabs.get_tab_count():
		var scroll := _tabs.get_tab_control(i) as ScrollContainer
		for child in scroll.get_children():
			scroll.remove_child(child)
			child.queue_free()
		var page := VBoxContainer.new()
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", 6)
		scroll.add_child(page)
		pages.append(page)
	_clothes_page(pages[0])
	_legs_page(pages[1])
	_hair_page(pages[2])
	_hats_page(pages[3])
	_extras_page(pages[4])


func _clothes_page(page: VBoxContainer) -> void:
	_choices(page, "Quoi porter", OUTFITS, _look.outfit, func(v):
		_look.outfit = v
		var allowed := DRESS_PATTERNS if v == "dress" else TOP_PATTERNS
		if v in ["coat", "overalls"] or not allowed.any(func(o): return o[0] == _look.pattern):
			_look.pattern = "none"
		if v == "overalls":
			_look.legwear = "pants"
			_look.legwear_color = _look.outfit_color
			_look.sleeve = "short"
		elif v == "dress" and _look.sleeve == "long":
			_look.sleeve = "puff")
	_swatches(page, "Couleur", COLORS, _look.outfit_color, func(c):
		_look.outfit_color = c
		if _look.outfit == "overalls":
			_look.legwear_color = c)
	if _look.outfit == "dress":
		_choices(page, "Motif", DRESS_PATTERNS, _look.pattern, func(v): _look.pattern = v)
	elif _look.outfit in ["tshirt", "sweater", "hoodie"]:
		_choices(page, "Motif", TOP_PATTERNS, _look.pattern, func(v): _look.pattern = v)
	var detail := "Chandail en dessous" if _look.outfit == "overalls" else "Couleur des détails"
	_swatches(page, detail, COLORS, _look.accent_color, func(c): _look.accent_color = c)
	_choices(page, "Manches", SLEEVES, _look.sleeve, func(v): _look.sleeve = v)


func _legs_page(page: VBoxContainer) -> void:
	_choices(page, "Jambes", LEGWEAR, _look.legwear, func(v): _look.legwear = v)
	_swatches(page, "Couleur", LEG_COLORS, _look.legwear_color, func(c): _look.legwear_color = c)
	_choices(page, "Chaussures", SHOES, _look.shoes, func(v): _look.shoes = v)
	_swatches(page, "Couleur des chaussures", COLORS, _look.shoe_color, func(c): _look.shoe_color = c)


# A new style keeps her exact hair colours; only a new colour drops them.
func _hair_page(page: VBoxContainer) -> void:
	_choices(page, "Coiffure", HAIR_STYLES, _look.hair_style, func(v): _look.hair_style = v, [])
	_swatches(page, "Couleur des cheveux", HAIR_COLORS, _look.hair_color, func(c): _look.hair_color = c, ["hair_"])
	_swatches(page, "Élastiques et rubans", COLORS, _look.accent_color, func(c): _look.accent_color = c)


func _hats_page(page: VBoxContainer) -> void:
	_choices(page, "Sur la tête", HATS, _look.hat, func(v): _look.hat = v)
	if _look.hat != "":
		_swatches(page, "Couleur", COLORS, _look.hat_color, func(c): _look.hat_color = c)


func _extras_page(page: VBoxContainer) -> void:
	_optional_swatches(page, "Foulard", COLORS, _look.scarf, func(v): _look.scarf = v)
	_optional_swatches(page, "Sac à dos", COLORS, _look.backpack, func(v): _look.backpack = v)
	_optional_swatches(page, "Lunettes", GLASSES, _look.glasses, func(v): _look.glasses = v)


# ── Rows ────────────────────────────────────────────────────────

func _row(page: VBoxContainer, title: String) -> HFlowContainer:
	var label := _text(title, 22)
	page.add_child(label)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	page.add_child(flow)
	return flow


func _choices(page: VBoxContainer, title: String, options: Array, current: String, on_pick: Callable, drop := CLOTHING_OVERRIDES) -> void:
	var flow := _row(page, title)
	for o in options:
		var b := Button.new()
		b.text = o[1]
		b.custom_minimum_size = Vector2(0, 42)
		if o[0] == current:
			b.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
		b.pressed.connect(_change.bind(on_pick, o[0], drop))
		flow.add_child(b)


func _swatches(page: VBoxContainer, title: String, colors: Array, current: Color, on_pick: Callable, drop := CLOTHING_OVERRIDES) -> void:
	var flow := _row(page, title)
	for hex in colors:
		var c := Color(hex)
		flow.add_child(_swatch(c, c.is_equal_approx(current), _change.bind(on_pick, c, drop)))


# A colour row with a "Rien" choice first; the value is a hex string, "" for none.
func _optional_swatches(page: VBoxContainer, title: String, colors: Array, current: String, on_pick: Callable) -> void:
	var flow := _row(page, title)
	var none := Button.new()
	none.text = "Rien"
	none.custom_minimum_size = Vector2(0, 42)
	if current == "":
		none.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
	none.pressed.connect(_change.bind(on_pick, ""))
	flow.add_child(none)
	for hex in colors:
		flow.add_child(_swatch(Color(hex), current != "" and Color(current).is_equal_approx(Color(hex)), _change.bind(on_pick, hex)))


func _swatch(c: Color, selected: bool, on_press: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(42, 42)
	b.tooltip_text = ""
	var ring := YELLOW if selected else c.darkened(0.35)
	b.add_theme_stylebox_override("normal", _box(c, ring, 5 if selected else 2, 21))
	b.add_theme_stylebox_override("hover", _box(c.lightened(0.15), BLUE, 3, 21))
	b.add_theme_stylebox_override("pressed", _box(c, YELLOW, 5, 21))
	b.pressed.connect(on_press)
	return b


## Applies a choice. `drop`: prefixes of Charlotte's exact-colour overrides that no longer fit it.
func _change(on_pick: Callable, value: Variant, drop := CLOTHING_OVERRIDES) -> void:
	on_pick.call(value)
	Sfx.play("swoosh", Vector2.INF, -6.0)
	# Her usual exact colours only fit her usual clothes and hair: a new colour uses the derived palette.
	for key in _look.overrides.keys():
		for prefix in drop:
			if String(key).begins_with(prefix):
				_look.overrides.erase(key)
	_refresh()


func _randomize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pick := func(list: Array) -> Variant: return list[rng.randi_range(0, list.size() - 1)]
	_look.outfit = pick.call(OUTFITS)[0]
	_look.outfit_color = Color(pick.call(COLORS))
	_look.accent_color = Color(pick.call(COLORS))
	_look.pattern = pick.call(DRESS_PATTERNS if _look.outfit == "dress" else TOP_PATTERNS)[0] if not _look.outfit in ["coat", "overalls"] else "none"
	_look.sleeve = pick.call(SLEEVES)[0]
	_look.legwear = pick.call(LEGWEAR)[0]
	_look.legwear_color = Color(pick.call(LEG_COLORS))
	if _look.outfit == "overalls":
		_look.legwear = "pants"
		_look.legwear_color = _look.outfit_color
	_look.shoes = pick.call(SHOES)[0]
	_look.shoe_color = Color(pick.call(COLORS))
	_look.hat = pick.call(HATS)[0] if rng.randf() < 0.6 else ""
	_look.hat_color = Color(pick.call(COLORS))
	_look.scarf = pick.call(COLORS) if rng.randf() < 0.3 else ""
	_look.backpack = pick.call(COLORS) if rng.randf() < 0.3 else ""
	_look.glasses = pick.call(GLASSES) if rng.randf() < 0.2 else ""
	_look.hair_style = pick.call(HAIR_STYLES)[0]
	_change(func(_v): pass, null)


func _close(result: CharacterLook) -> void:
	Sfx.play("chime" if result else "pop")
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		closed.emit(result)
		queue_free())


# ── Style ───────────────────────────────────────────────────────

func _theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 19
	t.set_color("font_color", "Button", BLUE)
	t.set_color("font_hover_color", "Button", BLUE)
	t.set_color("font_pressed_color", "Button", BLUE)
	t.set_color("font_focus_color", "Button", BLUE)
	t.set_stylebox("normal", "Button", _box(Color.WHITE, BLUE.lightened(0.3), 2, 14))
	t.set_stylebox("hover", "Button", _box(Color("#FFF4C2"), BLUE, 2, 14))
	t.set_stylebox("pressed", "Button", _box(YELLOW, BLUE, 3, 14))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_selected_color", "TabContainer", BLUE)
	t.set_color("font_unselected_color", "TabContainer", BLUE.lightened(0.35))
	t.set_color("font_hovered_color", "TabContainer", BLUE)
	t.set_font_size("font_size", "TabContainer", 21)
	t.set_stylebox("panel", "TabContainer", _box(Color.WHITE, BLUE.lightened(0.3), 2, 16))
	t.set_stylebox("tab_selected", "TabContainer", _box(YELLOW, BLUE, 2, 12))
	t.set_stylebox("tab_unselected", "TabContainer", _box(Color("#EFE6D6"), BLUE.lightened(0.4), 2, 12))
	t.set_stylebox("tab_hovered", "TabContainer", _box(Color("#FFF4C2"), BLUE, 2, 12))
	return t


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 14
	b.content_margin_right = 14
	b.content_margin_top = 6
	b.content_margin_bottom = 6
	return b


func _text(s: String, size: int) -> Label:
	var label := Label.new()
	label.text = s
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", BLUE)
	return label
