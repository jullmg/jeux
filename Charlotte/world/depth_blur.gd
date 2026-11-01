class_name DepthBlur
extends Node2D
## Softens what lies far away (shaders/depth_blur.gdshader). Two uses:
##  - DepthBlur.far(): over the whole view, right after the sky and the skyline are drawn (before the houses), so the
##    distant roofs and steeples are out of focus;
##  - DepthBlur.vista(cs): over a cross street's gap, after its VISTA, blurring only round its vanishing point (far
##    buildings, Mount Royal), the near walls staying sharp. A BackBufferCopy before it refreshes the screen copy.

var vista_of: CrossStreet
var _rect := Rect2()
var _mat: ShaderMaterial


static func far(parent: Node, lod := 1.2) -> DepthBlur:
	var blur := DepthBlur.new()
	blur._setup(lod)
	parent.add_child(blur)
	return blur


static func vista(parent: Node, cs: CrossStreet) -> DepthBlur:
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_RECT
	copy.rect = Rect2(cs.x0 - 20.0, 0.0, cs.x1 - cs.x0 + 40.0, CrossStreet.FACADE_Y + 10.0)
	parent.add_child(copy)
	var blur := DepthBlur.new()
	blur.vista_of = cs
	blur._rect = Rect2(cs.x0, 0.0, cs.x1 - cs.x0, CrossStreet.FACADE_Y)
	blur._setup(1.8)
	parent.add_child(blur)
	return blur


func _setup(lod: float) -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/depth_blur.gdshader")
	_mat.set_shader_parameter("lod", lod)
	material = _mat


func _process(_delta: float) -> void:
	var view := get_viewport().get_visible_rect().size
	var to_screen := get_viewport().get_canvas_transform()
	if vista_of == null:
		# Follow the camera: always exactly the view.
		var inv := to_screen.affine_inverse()
		_rect = Rect2(inv * Vector2.ZERO, inv.basis_xform(view))
		queue_redraw()
	else:
		var vp_screen := to_screen * Vector2((vista_of.x0 + vista_of.x1) / 2.0, CrossStreet.HORIZON_Y)
		_mat.set_shader_parameter("vp", vp_screen / view)
		_mat.set_shader_parameter("aspect", view.x / view.y)


func _draw() -> void:
	draw_rect(_rect, Color.WHITE)
