class_name Maquette
extends RefCounted
## Une pièce grise tirée de son plan, quand son modèle 3D n'existe pas encore (prototype) : plancher, murs, meubles en
## boîtes, la table qu'on voit par en dessous, les chaises, la cage.

static var _mats: Dictionary = {}


static func _mat(color: Color) -> StandardMaterial3D:
	if not _mats.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.8
		_mats[color] = m
	return _mats[color]


static func _box(parent: Node3D, name_: String, rect: Rect2, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(rect.size.x, y1 - y0, rect.size.y)
	var m := MeshInstance3D.new()
	m.name = name_
	m.mesh = mesh
	m.material_override = _mat(color)
	m.position = Vector3(rect.get_center().x, (y0 + y1) / 2.0, rect.get_center().y)
	parent.add_child(m)
	return m


static func build(map: RoomMap) -> Node3D:
	var root := Node3D.new()
	root.name = "Maquette_" + map.id
	var r := map.room
	_box(root, "Plancher", r.grow(0.1), -0.05, 0.0, Color("c8a272"))
	var cam: Array = map.data.camera.pos
	var eye := Vector2(cam[0], cam[2])
	var c := r.get_center()
	# Trois murs : celui du côté de la caméra reste ouvert.
	var walls := {
		"MurNord": Rect2(r.position.x - 0.1, r.position.y - 0.1, r.size.x + 0.2, 0.1),
		"MurSud": Rect2(r.position.x - 0.1, r.end.y, r.size.x + 0.2, 0.1),
		"MurOuest": Rect2(r.position.x - 0.1, r.position.y, 0.1, r.size.y),
		"MurEst": Rect2(r.end.x, r.position.y, 0.1, r.size.y),
	}
	var open := "MurSud"
	var d := eye - c
	if absf(d.x) > absf(d.y):
		open = "MurEst" if d.x > 0.0 else "MurOuest"
	else:
		open = "MurSud" if d.y > 0.0 else "MurNord"
	for name_: String in walls:
		if name_ != open:
			_box(root, name_, walls[name_], 0.0, 2.6, Color("e9e2d6"))
	for key: String in map.named:
		var high := 0.45 if key.contains("basse") else 0.8
		_box(root, key, map.named[key], 0.0, high, Color("8d6e57"))
	for hd in map.hides:
		if hd.kind == "dessous":
			var top: float = hd.height
			var rect: Rect2 = hd.rect
			_box(root, "Table", rect, top - 0.04, top, Color("5a3b28"))
			for corner_: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
					Vector2(rect.position.x, rect.end.y)]:
				var leg := Rect2(corner_.lerp(rect.get_center(), 0.08) - Vector2(0.025, 0.025), Vector2(0.05, 0.05))
				_box(root, "Patte", leg, 0.0, top - 0.04, Color("5a3b28"))
	for s in map.stools:
		var cyl := CylinderMesh.new()
		cyl.top_radius = s.r
		cyl.bottom_radius = s.r
		cyl.height = 0.46
		var m := MeshInstance3D.new()
		m.name = "Chaise_" + str(s.name)
		m.mesh = cyl
		m.material_override = _mat(Color("2b2b30"))
		m.position = Vector3(s.pos.x, 0.23, s.pos.y)
		root.add_child(m)
	if map.corner_kind == "cage":
		var cage := Rect2(map.corner - Vector2(0.36, 0.27), Vector2(0.72, 0.54))
		for side: Rect2 in [Rect2(cage.position, Vector2(cage.size.x, 0.02)), Rect2(cage.position, Vector2(0.02, cage.size.y)),
				Rect2(Vector2(cage.end.x - 0.02, cage.position.y), Vector2(0.02, cage.size.y))]:
			_box(root, "Cage", side, 0.0, 0.6, Color("1d1d22"))
		_box(root, "CageToit", cage, 0.58, 0.6, Color("1d1d22"))
	_box(root, "Coussin", Rect2(map.corner - Vector2(0.3, 0.25), Vector2(0.6, 0.5)), 0.0, 0.05, Color("8a6fb0"))
	return root
