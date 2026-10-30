class_name SkyBackdrop
extends CanvasLayer
## Screen-space autumn afternoon sky: gradient and a low sun on the upper left.

const SUN_POS := Vector2(150, 120)


func _ready() -> void:
	layer = -10
	var size := get_viewport().get_visible_rect().size
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 0.82, 1.0])
	grad.colors = PackedColorArray([Color("#4F86C6"), Color("#86B5E0"), Color("#C9DDEB"), Color("#F6D9B4"), Color("#F4B98C")])
	var sky := GradientTexture2D.new()
	sky.gradient = grad
	sky.fill_to = Vector2(0, 1)
	sky.width = 8
	sky.height = 256
	var rect := TextureRect.new()
	rect.texture = sky
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	_disc(SUN_POS, 460.0, [Color(1.0, 0.88, 0.6, 0.35), Color(1.0, 0.86, 0.6, 0.14), Color(1.0, 0.82, 0.55, 0.04), Color(1.0, 0.8, 0.55, 0.0)], [0.0, 0.3, 0.65, 1.0])
	_disc(SUN_POS, 150.0, [Color(1.0, 0.95, 0.8, 0.8), Color(1.0, 0.92, 0.75, 0.25), Color(1.0, 0.9, 0.7, 0.0)], [0.0, 0.45, 1.0])
	_disc(SUN_POS, 56.0, [Color(1.0, 0.98, 0.9, 1.0), Color(1.0, 0.96, 0.85, 1.0), Color(1.0, 0.95, 0.8, 0.0)], [0.0, 0.8, 1.0])


func _disc(center: Vector2, diameter: float, colors: Array, offsets: Array = []) -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray(colors)
	if offsets.is_empty():
		offsets = [0.0, 1.0]
	grad.offsets = PackedFloat32Array(offsets)
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	var rect := TextureRect.new()
	rect.texture = t
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = Vector2.ONE * diameter
	rect.position = center - rect.size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
