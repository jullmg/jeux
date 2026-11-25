class_name Stage
extends Node3D
## La cuisine en 3D : lumière, caméra, personnages, nourriture et zone cachée. Montre l'état d'une Sim.

const KITCHEN := "res://art/models/cuisine.glb"
const FOODS := "res://art/models/nourriture.glb"
const MASK_CELL := 0.06
## Les morceaux sont grossis pour se lire de haut.
const FOOD_SCALE := [1.7, 1.55, 1.3, 1.12]
const RING_SIZE := [0.095, 0.15, 0.2, 0.26]
const RING_COLORS := [Color(1, 1, 1, 0.85), Color(0.2, 0.75, 1.0, 0.95), Color(1.0, 0.5, 0.05, 1.0),
	Color(1.0, 0.82, 0.05, 1.0)]

## Pendant une chicane, les deux se tournent un peu vers nous pour qu'on voie leur visage.
const TOWARD_CAMERA := Vector2(0.0, 0.75)

var map: KitchenMap
var sim: Sim
var camera: Camera3D
var ambiance: Ambiance
var dog: DogView
var mom: PersonView
var people: Dictionary = {}
var reduced_motion := false
## "titre" : gros plan sur le coin de Blanche. "jeu" : vue de la cuisine. "photo" : vue libre pour les planches d'essai.
var view := "titre"
var photo: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]

var _kitchen: Node3D
var _fridge_door: Node3D
var _christmas: Node3D
## La matière de la vue par la fenêtre, teintée selon le moment.
var _outside: StandardMaterial3D
var _stool: Node3D
var _food_meshes: Dictionary = {}
var _items: Dictionary = {}
var _mask_image: Image
var _mask_texture: ImageTexture
var _mask_rect: Rect2
var _mask_node: MeshInstance3D
var _mask_viewer := Vector2.INF
var _mask_island := false
var _mask_wait := 0.0
var _mask_center := Vector2.INF
var _mask_bytes := PackedByteArray()
var _mask_index := PackedInt32Array()
var _mask_points := PackedVector2Array()
var _steam: CPUParticles3D
var _fridge_light: OmniLight3D
var _time := 0.0
var _shake := 0.0
var _wobble := 0.0
var _held_id := -1
var _laugh := 0.0
var _surprised := 0.0
var _follow := Vector3.ZERO
var _cam_pos := Vector3.ZERO
var _cam_target := Vector3.ZERO
var _mom_yaw := 0.0
var _dog_yaw := 0.0
## L'endroit à nourriture contre lequel Blanche se dresse ou vient de se dresser.
var _reach_spot := ""
var _ring_mesh: ArrayMesh
var _ring_materials: Array[StandardMaterial3D] = []
var _ring_shadow: StandardMaterial3D
var _kept: Array[Resource] = []
## Positions au dernier pas des règles : l'écran peut aller plus vite que les 60 pas par seconde.
var _last_time := -1.0
var _last_pos: Dictionary = {}
var _speeds: Dictionary = {}


func _ready() -> void:
	map = KitchenMap.new()
	_kitchen = (load(KITCHEN) as PackedScene).instantiate()
	add_child(_kitchen)
	_fridge_door = _kitchen.find_child("PorteFrigo", true, false)
	_stool = _kitchen.find_child("Tabouret", true, false)
	_christmas = _kitchen.find_child("Noel", true, false)
	var view_mesh: MeshInstance3D = _kitchen.find_child("Vue", true, false)
	_outside = view_mesh.mesh.surface_get_material(0).duplicate()
	view_mesh.set_surface_override_material(0, _outside)
	view_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var foods: Node = (load(FOODS) as PackedScene).instantiate()
	for m: MeshInstance3D in foods.find_children("*", "MeshInstance3D", true, false):
		_food_meshes[String(m.name)] = m.mesh
	foods.free()
	_build_lights()
	_build_camera()
	_build_effects()
	_build_mask()
	_ring_mesh = _make_ring(0.8, 1.0, 40)
	_ring_shadow = StandardMaterial3D.new()
	_ring_shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_shadow.albedo_color = Color(0.1, 0.05, 0.0, 0.45)
	_ring_shadow.cull_mode = BaseMaterial3D.CULL_DISABLED
	for c: Color in RING_COLORS:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = c
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_ring_materials.append(mat)
	dog = DogView.new()
	add_child(dog)
	dog.add_child(_blob_shadow(0.27, 0.5))
	# Le shader de la silhouette se compile à l'écran titre, pas en pleine partie.
	dog.set_see_through(true)
	get_tree().create_timer(0.25).timeout.connect(dog.set_see_through.bind(false))
	mom = PersonView.new("maman")
	add_child(mom)
	mom.add_child(_blob_shadow(0.32, 0.4))
	# Les modèles qui vont et viennent restent chargés, pour éviter les à-coups.
	for who: String in ["papa", "charlotte"]:
		_kept.append(load("res://art/models/%s.glb" % who))
	show_title()


## Le moment de la journée : la lumière, la vue par la fenêtre et les décorations.
func _set_moment(moment: String) -> void:
	ambiance.set_moment(moment)
	_outside.emission = ambiance.sky_tint()
	_outside.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	_christmas.visible = moment == "noel"


func _build_lights() -> void:
	ambiance = Ambiance.new()
	add_child(ambiance)
	_fridge_light = OmniLight3D.new()
	_fridge_light.position = Vector3(-1.05, 1.35, -1.45)
	_fridge_light.light_color = Color(0.9, 0.97, 1.0)
	_fridge_light.light_energy = 0.0
	_fridge_light.omni_range = 1.4
	add_child(_fridge_light)


func _build_camera() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.near = 0.1
	camera.far = 40.0
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()


## Sur un écran étroit, on garde la largeur de la cuisine plutôt que sa hauteur.
func _fit_camera() -> void:
	var size := get_viewport().get_visible_rect().size
	var fov: float = map.data.camera.fov
	if size.x / maxf(1.0, size.y) < 16.0 / 9.0 - 0.01:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(fov) / 2.0) * 16.0 / 9.0))
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = fov


func _blob_shadow(radius: float, strength: float) -> MeshInstance3D:
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE * radius * 2.0
	var m := MeshInstance3D.new()
	m.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = _soft_dot()
	mat.albedo_color = Color(0.05, 0.02, 0.0, strength)
	m.material_override = mat
	m.position.y = 0.003
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	return t


func _build_effects() -> void:
	_steam = CPUParticles3D.new()
	_steam.position = Vector3(0.06, 1.08, -1.76)
	_steam.amount = 18
	_steam.lifetime = 1.6
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_steam.emission_sphere_radius = 0.07
	_steam.direction = Vector3.UP
	_steam.spread = 12.0
	_steam.gravity = Vector3(0, 0.12, 0)
	_steam.initial_velocity_min = 0.12
	_steam.initial_velocity_max = 0.24
	_steam.scale_amount_min = 0.5
	_steam.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.25, Color(1, 1, 1, 0.34))
	_steam.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.16)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_dot()
	quad.material = mat
	_steam.mesh = quad
	_steam.emitting = false
	add_child(_steam)


# ------------------------------------------------------------------ zone cachée

func _build_mask() -> void:
	_mask_rect = map.island.grow(1.15).intersection(map.room)
	var w := int(_mask_rect.size.x / MASK_CELL)
	var h := int(_mask_rect.size.y / MASK_CELL)
	_mask_image = Image.create(w, h, false, Image.FORMAT_R8)
	_mask_texture = ImageTexture.create_from_image(_mask_image)
	_mask_bytes.resize(w * h)
	# Les seules cases qui peuvent un jour être cachées : libres et assez près de l'îlot.
	var inner := map.island.grow(-0.02)
	for y in h:
		for x in w:
			var p := _mask_rect.position + Vector2(x + 0.5, y + 0.5) * MASK_CELL
			if map.is_free(p, 0.07) and p.distance_to(p.clamp(inner.position, inner.end)) <= KitchenMap.SHADOW_MAX:
				_mask_index.append(y * w + x)
				_mask_points.append(p)
	var plane := PlaneMesh.new()
	plane.size = _mask_rect.size
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D mask : filter_linear, repeat_disable;
uniform float strength = 1.0;
varying vec3 at;
void vertex() { at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float m = texture(mask, UV).r;
	float inside = smoothstep(0.38, 0.62, m);
	float edge = smoothstep(0.28, 0.5, m) * (1.0 - smoothstep(0.5, 0.74, m));
	float stripe = smoothstep(0.45, 0.55, abs(fract((at.x + at.z) * 5.5) - 0.5) * 2.0);
	ALBEDO = mix(mix(vec3(0.02, 0.05, 0.3), vec3(0.1, 0.28, 0.85), stripe), vec3(0.75, 0.9, 1.0), edge);
	ALPHA = (inside * 0.5 + edge * 0.95) * strength;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("mask", _mask_texture)
	_mask_node = MeshInstance3D.new()
	_mask_node.mesh = plane
	_mask_node.material_override = mat
	var c := _mask_rect.get_center()
	_mask_node.position = Vector3(c.x, 0.006, c.y)
	_mask_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mask_node.visible = false
	add_child(_mask_node)


func _update_mask(delta: float) -> void:
	_mask_wait -= delta
	var at_island := sim.mom_at_island()
	if _mask_wait > 0.0 or (sim.mom_pos.distance_to(_mask_viewer) < 0.03 and at_island == _mask_island):
		return
	_mask_wait = 0.08
	_mask_viewer = sim.mom_pos
	_mask_island = at_island
	var sum := Vector2.ZERO
	var cells := 0
	for i in _mask_index.size():
		var on := map.hidden_by_island(sim.mom_pos, _mask_points[i], at_island)
		_mask_bytes[_mask_index[i]] = 255 if on else 0
		if on:
			sum += _mask_points[i]
			cells += 1
	_mask_center = sum / cells if cells > 12 else Vector2.INF
	_mask_image.set_data(_mask_image.get_width(), _mask_image.get_height(), false, Image.FORMAT_R8, _mask_bytes)
	_mask_texture.update(_mask_image)


# ------------------------------------------------------------------ nourriture

static func _make_ring(inner: float, outer: float, seg: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in seg:
		var a := TAU * i / seg
		verts.append(Vector3(cos(a) * inner, 0, sin(a) * inner))
		verts.append(Vector3(cos(a) * outer, 0, sin(a) * outer))
	for i in seg:
		var a := i * 2
		var b := (i + 1) % seg * 2
		indices.append_array([a, a + 1, b + 1, a, b + 1, b])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func food_model(size: int) -> MeshInstance3D:
	var model: String = sim.level.foods[Sim.SIZE_KEYS[size]][0]
	var m := MeshInstance3D.new()
	m.mesh = _food_meshes[model]
	return m


## La position d'un morceau, à la hauteur du meuble où il est.
func item_position(item: Dictionary) -> Vector3:
	var y := 0.0
	if item.spot != "":
		y = _surface_height(item.spot)
	return Vector3(item.pos.x, y, item.pos.y)


func _sync_food(delta: float) -> void:
	var alive := {}
	for item in sim.food:
		var id: int = item.id
		alive[id] = true
		var node: Node3D = _items.get(id)
		if node != null and node.get_meta("spot") != item.spot:
			node.queue_free()
			node = null
		if node == null:
			node = Node3D.new()
			node.set_meta("spot", item.spot)
			node.set_meta("age", 0.0)
			node.position = item_position(item)
			var mesh := food_model(item.size)
			mesh.name = "morceau"
			mesh.scale = Vector3.ONE * FOOD_SCALE[item.size]
			node.add_child(mesh)
			var under := MeshInstance3D.new()
			under.name = "ombre"
			under.mesh = _ring_mesh
			under.material_override = _ring_shadow
			under.scale = Vector3.ONE * RING_SIZE[item.size] * 1.14
			under.position.y = 0.004
			under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(under)
			var ring := MeshInstance3D.new()
			ring.name = "anneau"
			ring.mesh = _ring_mesh
			ring.material_override = _ring_materials[item.size]
			ring.scale = Vector3.ONE * RING_SIZE[item.size]
			ring.position.y = 0.008
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(ring)
			add_child(node)
			_items[id] = node
		var age: float = node.get_meta("age") + delta
		node.set_meta("age", age)
		var pop := minf(1.0, age * 5.0)
		node.scale = Vector3.ONE * (pop + sin(pop * PI) * 0.35)
		var mesh: Node3D = node.get_node("morceau")
		var ring: Node3D = node.get_node("anneau")
		var beat := 1.0 + sin(_time * 4.0 + id) * 0.06
		ring.scale = Vector3.ONE * RING_SIZE[item.size] * beat
		if item.size == Sim.Size.TREASURE:
			mesh.rotation.y += delta * 0.8
			mesh.position.y = 0.015 + absf(sin(_time * 2.4)) * 0.035
		# Un morceau qu'on est en train de tirer tremble.
		var pulled: bool = sim.dog_state == Sim.Dog.REACHING and sim.reach_item.get("id", -1) == id
		mesh.position.x = sin(_time * 40.0) * 0.008 if pulled else 0.0
	for id: int in _items.keys():
		if not alive.has(id):
			_items[id].queue_free()
			_items.erase(id)
	var held: int = sim.mouth.get("id", -1)
	if held != _held_id:
		_held_id = held
		if held < 0:
			dog.drop_held()
		else:
			var m := food_model(sim.mouth.size)
			if sim.mouth.size >= Sim.Size.BIG:
				m.scale = Vector3.ONE * 0.75
			dog.hold(m)


# ------------------------------------------------------------------ vie

func show_title() -> void:
	_set_moment("matin")
	sim = null
	view = "titre"
	_clear_level()
	dog.position = Vector3(map.corner.x - 0.06, 0, map.corner.y - 0.04)
	_dog_yaw = atan2(-0.93, 0.36)
	dog.rotation.y = _dog_yaw
	dog.pose = "sit"
	var st: Dictionary = map.stations.cuisiniere
	mom.position = Vector3(st.pos.x, 0, st.pos.y)
	mom.rotation.y = atan2(st.face.x, st.face.y)
	mom.pose = "brasser"
	_steam.emitting = true
	_cam_pos = Vector3.ZERO


func start_level(sim_: Sim) -> void:
	_clear_level()
	sim = sim_
	_set_moment(sim.level.get("moment", "midi"))
	view = "jeu"
	_last_time = -1.0
	_last_pos.clear()
	_speeds.clear()
	_mask_node.visible = true
	_mask_viewer = Vector2.INF
	dog.position = Vector3(sim.dog_pos.x, 0, sim.dog_pos.y)
	_dog_yaw = atan2(sim.dog_dir.x, sim.dog_dir.y)
	_mom_yaw = atan2(sim.mom_dir.x, sim.mom_dir.y)
	_cam_pos = Vector3.ZERO
	for who: String in sim.level.helpers:
		var p := PersonView.new(who)
		add_child(p)
		p.add_child(_blob_shadow(0.3, 0.35))
		p.visible = false
		people[who] = p


func _clear_level() -> void:
	for node: Node in _items.values():
		node.queue_free()
	_items.clear()
	for p: Node in people.values():
		p.queue_free()
	people.clear()
	if dog:
		dog.drop_held()
		dog.chewing = false
		dog.carrying = false
		dog.sad = false
		mom.talking = 0.0
		mom.head_yaw = 0.0
	_held_id = -1
	_laugh = 0.0
	_surprised = 0.0
	_shake = 0.0
	_wobble = 0.0
	if _mask_node:
		_mask_node.visible = false


## Les réactions visibles aux événements de la partie.
func on_event(e: Dictionary) -> void:
	match e.type:
		"caught":
			_shake = 1.0
			_surprised = 0.45
			mom.scold_style = (mom.scold_style + 1 + randi() % 2) % 3
			dog.tilt = -1.0 if randf() < 0.5 else 1.0
		"corner_arrive":
			if randf() < 0.6:
				_laugh = 1.6
		"noise":
			if e.what == "tabouret":
				_wobble = 1.0
			_shake = maxf(_shake, 0.25)


func _process(delta: float) -> void:
	_time += delta
	if sim != null:
		_measure_speeds()
		_show_dog(delta)
		_show_mom(delta)
		_show_people(delta)
		_sync_food(delta)
		_update_mask(delta)
		dog.set_see_through(_dog_covered())
		_steam.emitting = sim.activity == "brasser" or sim.activity == "surprise" or sim.walk_activity == "surprise"
	_show_furniture(delta)
	_move_camera(delta)


static func _turn(from: float, to: float, delta: float, speed: float) -> float:
	return lerp_angle(from, to, 1.0 - exp(-delta * speed))


func _surface_height(spot: String) -> float:
	return 0.9 if map.spots[spot].surface == "buffet" else float(map.data.counter_height)


## Un meuble ou une personne passe-t-il entre la caméra et Blanche ?
func _dog_covered() -> bool:
	var eye := camera.global_position
	for height: float in [0.14, 0.42]:
		var point := Vector3(sim.dog_pos.x, height, sim.dog_pos.y)
		var box := AABB(Vector3(map.island.position.x, 0.0, map.island.position.y),
			Vector3(map.island.size.x, 0.93, map.island.size.y))
		if box.intersects_segment(eye, point):
			return true
		var bodies: Array = [sim.mom_pos]
		for h in sim.helpers:
			bodies.append(h.pos)
		for c: Vector2 in bodies:
			var body := AABB(Vector3(c.x - 0.2, 0.0, c.y - 0.2), Vector3(0.4, 1.5, 0.4))
			if body.intersects_segment(eye, point):
				return true
	return false


## Le milieu de la zone cachée (Vector2.INF s'il n'y en a pas).
func hidden_center() -> Vector2:
	return _mask_center


## La vitesse de chacun, mesurée seulement quand les règles ont avancé.
func _measure_speeds() -> void:
	if sim.time == _last_time:
		return
	var now := {"blanche": sim.dog_pos, "maman": sim.mom_pos}
	for h in sim.helpers:
		now[h.who] = h.pos
	for who: String in now:
		var moved: float = now[who].distance_to(_last_pos.get(who, now[who]))
		_speeds[who] = moved / maxf(sim.time - _last_time, 0.001) if _last_time >= 0.0 else 0.0
	_last_pos = now
	_last_time = sim.time


## Rejoint la position des règles en douceur (sans traîner).
static func _follow_floor(node: Node3D, to: Vector2, delta: float) -> void:
	var f := 1.0 - exp(-delta * 45.0)
	node.position.x = lerpf(node.position.x, to.x, f)
	node.position.z = lerpf(node.position.z, to.y, f)


func _show_dog(delta: float) -> void:
	if sim.dog_state == Sim.Dog.REACHING:
		_reach_spot = sim.reach_item.spot
	# Dressée, elle se place bien en face du morceau, les pattes sur le bord (à l'écran seulement).
	var up: bool = sim.dog_state == Sim.Dog.REACHING \
		or (sim.dog_state == Sim.Dog.LOWERING and sim.lower_left > Sim.DESCEND_TIME * 0.5)
	var at := sim.dog_pos
	var heading := sim.dog_dir
	if up and _reach_spot != "":
		var spot: Dictionary = map.spots[_reach_spot]
		at = spot.stand
		heading = spot.food - spot.stand
		dog.surface_y = _surface_height(_reach_spot)
	_follow_floor(dog, at, delta)
	dog.speed = _speeds.get("blanche", 0.0)
	_dog_yaw = _turn(_dog_yaw, atan2(heading.x, heading.y), delta, 14.0)
	dog.rotation.y = _dog_yaw
	_surprised -= delta
	dog.carrying = not sim.mouth.is_empty()
	dog.chewing = false
	dog.sad = sim.punished()
	dog.look_up = 1.0 if sim.watching() else 0.0
	if sim.over:
		dog.pose = "happy" if sim.stars() > 0 else "sit"
		return
	match sim.dog_state:
		Sim.Dog.TO_CORNER:
			dog.pose = "surprised" if _surprised > 0.0 else "sulk"
		Sim.Dog.IN_CORNER:
			dog.pose = "sit"
		Sim.Dog.REACHING:
			dog.pose = "reach"
			dog.reach_progress = clampf(sim.reach_progress / Sim.GRAB_TIMES[sim.reach_item.size], 0.0, 1.0)
		Sim.Dog.LOWERING:
			dog.pose = "reach" if sim.lower_left > Sim.DESCEND_TIME * 0.5 else "stand"
			dog.reach_progress = 0.3
		_:
			if sim.dog_moving:
				dog.pose = "walk"
			elif not sim.mouth.is_empty():
				dog.chewing = true
				dog.pose = "crouch" if sim.dog_hidden() else "stand"
			elif sim.dog_still_time > 0.7:
				dog.pose = "crouch" if sim.dog_hidden() else "sit"
			else:
				dog.pose = "stand"


func _show_mom(delta: float) -> void:
	_follow_floor(mom, sim.mom_pos, delta)
	mom.speed = _speeds.get("maman", 0.0)
	var dir := sim.mom_dir
	if sim.mom_state == Sim.Mom.BUSY and sim.activity == "chicane":
		dir += TOWARD_CAMERA
	var yaw := atan2(dir.x, dir.y)
	_mom_yaw = _turn(_mom_yaw, yaw, delta, 16.0)
	mom.rotation.y = _mom_yaw
	var to_dog := sim.dog_pos - sim.mom_pos
	var relative := rad_to_deg(wrapf(atan2(to_dog.x, to_dog.y) - _mom_yaw, -PI, PI))
	mom.head_yaw = 0.0
	_laugh -= delta
	match sim.mom_state:
		Sim.Mom.BUSY:
			mom.pose = sim.activity
		Sim.Mom.HINT:
			mom.pose = {"real": "hint", "feint": "feint", "round": "round"}[sim.hint_kind]
		Sim.Mom.TURN:
			mom.pose = "look"
		Sim.Mom.LOOK:
			mom.pose = "look"
			if not sim.dog_hidden():
				mom.head_yaw = clampf(relative, -28.0, 28.0)
		Sim.Mom.TURN_BACK:
			mom.pose = "idle"
		Sim.Mom.SCOLD:
			mom.pose = "point"
			var corner := map.corner - sim.mom_pos
			# Elle regarde Blanche et pointe le coin.
			_mom_yaw = _turn(_mom_yaw, atan2(corner.x, corner.y), delta, 20.0)
			mom.head_yaw = clampf(relative, -28.0, 28.0)
		Sim.Mom.WALK, Sim.Mom.ROUND:
			mom.pose = "walk"
	# Elle ne peut pas s'empêcher de rire une fois Blanche rendue au coin.
	if _laugh > 0.0 and (sim.mom_state == Sim.Mom.BUSY or sim.mom_state == Sim.Mom.TURN_BACK):
		mom.pose = "laugh"
	if sim.over:
		mom.pose = "cheer" if sim.stars() > 0 else "laugh"


func _show_people(delta: float) -> void:
	var present := {}
	for h in sim.helpers:
		var p: PersonView = people[h.who]
		present[h.who] = true
		var was_visible := p.visible
		p.visible = true
		if was_visible:
			_follow_floor(p, h.pos, delta)
		else:
			p.position = Vector3(h.pos.x, 0, h.pos.y)
		p.speed = _speeds.get(h.who, 0.0)
		var moving: bool = h.state != "stay"
		var dir: Vector2 = h.dir if moving else sim.mom_pos - h.pos
		if h.state == "argue":
			dir = dir.normalized() + TOWARD_CAMERA
		if h.who == "charlotte" and h.snitch > 0.0:
			dir = sim.dog_pos - h.pos
			p.pose = "snitch"
		elif h.who == "papa":
			p.pose = "argue" if h.state == "argue" else "carry"
		else:
			p.pose = "walk" if moving else "wave"
		var yaw := atan2(dir.x, dir.y)
		p.rotation.y = yaw if not was_visible else _turn(p.rotation.y, yaw, delta, 10.0)
	for who: String in people:
		if not present.has(who):
			people[who].visible = false


func _show_furniture(delta: float) -> void:
	var open := sim != null and sim.mom_state == Sim.Mom.BUSY and sim.activity == "frigo"
	open = open or (sim != null and sim.station == "frigo" and sim.mom_state == Sim.Mom.HINT)
	_fridge_door.rotation.y = _turn(_fridge_door.rotation.y, deg_to_rad(-112.0) if open else 0.0, delta, 7.0)
	_fridge_light.light_energy = lerpf(_fridge_light.light_energy, 0.9 if open else 0.0, 1.0 - exp(-delta * 7.0))
	_wobble = maxf(0.0, _wobble - delta * 1.4)
	if _stool:
		_stool.rotation.z = sin(_time * 24.0) * 0.14 * _wobble


func _move_camera(delta: float) -> void:
	var cam: Dictionary = map.data.camera
	var pos := Vector3(cam.pos[0], cam.pos[1], cam.pos[2])
	var target := Vector3(cam.target[0], cam.target[1], cam.target[2])
	if view == "photo":
		camera.look_at_from_position(photo[0], photo[1])
		_cam_pos = Vector3.ZERO
		return
	if view == "titre":
		var drift := 0.0 if reduced_motion else sin(_time * 0.23) * 0.09
		pos = Vector3(0.1 + drift, 1.22, 2.92)
		target = Vector3(0.86, 0.5, 0.66)
	elif not reduced_motion and dog:
		var want := Vector3(dog.position.x * 0.09, 0, dog.position.z * 0.05)
		_follow = _follow.lerp(want, 1.0 - exp(-delta * 2.5))
		pos += _follow
		target += _follow * 1.4
	else:
		_follow = Vector3.ZERO
	if _cam_pos == Vector3.ZERO:
		_cam_pos = pos
		_cam_target = target
	_cam_pos = _cam_pos.lerp(pos, 1.0 - exp(-delta * 4.0))
	_cam_target = _cam_target.lerp(target, 1.0 - exp(-delta * 4.0))
	_shake = maxf(0.0, _shake - delta * 2.4)
	var jitter := Vector3.ZERO
	if _shake > 0.0 and not reduced_motion:
		jitter = Vector3(sin(_time * 61.0), sin(_time * 47.0), 0) * 0.035 * _shake
	camera.look_at_from_position(_cam_pos + jitter, _cam_target + jitter * 0.4)


# ------------------------------------------------------------------ écran ↔ plancher

## Une direction à l'écran (x à droite, y vers le haut) devient une direction sur le plancher.
func floor_direction(input: Vector2) -> Vector2:
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var f := Vector2(forward.x, forward.z).normalized()
	var r := Vector2(right.x, right.z).normalized()
	return (r * input.x + f * input.y).limit_length(1.0)


## Le point du plancher sous un point de l'écran (Vector2.INF s'il n'y en a pas).
func floor_point(screen: Vector2) -> Vector2:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if dir.y >= -0.01:
		return Vector2.INF
	var p := from + dir * (-from.y / dir.y)
	return Vector2(p.x, p.z)


func on_screen(p: Vector3) -> Vector2:
	return camera.unproject_position(p)
