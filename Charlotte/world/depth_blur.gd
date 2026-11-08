class_name DepthBlur
extends Node2D
## Softens what lies far away (shaders/depth_blur.gdshader). Two uses:
##  - DepthBlur.far(): over the whole view, right after the sky and the skyline are drawn (before the houses), so the
##    distant roofs and steeples are out of focus;
##  - DepthBlur.vista(cs): over a cross street's gap, after its VISTA, blurring only round its vanishing point (far
##    buildings, Mount Royal), the near walls staying sharp. A BackBufferCopy before it refreshes the screen copy.
##
## Neither of them runs on Halloween night. The blur reads the screen back through its mipmaps, and when everything
## far away is almost black the higher mips mix the brighter surroundings into it: the gap came out as a flat, paler
## rectangle with a hard edge down the street (Julien saw it at the corner of Holt). Nothing is lost by leaving it
## out — at that hour the distance is a silhouette already.

var vista_of: CrossStreet
var _rect := Rect2()
var _mat: ShaderMaterial


static func far(parent: Node, lod := 1.2) -> DepthBlur:
	if Halloween.night():
		return null
	var blur := DepthBlur.new()
	blur._setup(lod)
	parent.add_child(blur)
	return blur


static func vista(parent: Node, cs: CrossStreet) -> DepthBlur:
	if Halloween.night():
		return null
	# The whole screen, not just the gap: the blur's mipmaps reach outside the gap, and a partial copy left them grey.
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	parent.add_child(copy)
	var blur := DepthBlur.new()
	blur.vista_of = cs
	blur._rect = Rect2(cs.x0, 0.0, cs.x1 - cs.x0, CrossStreet.FACADE_Y)
	blur._setup(1.2)
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
