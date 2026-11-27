class_name Stage
extends Node3D
## Les pièces en 3D : lumière, caméra, personnages, nourriture et zone cachée. Montre l'état d'une Sim.
## La cuisine est toujours chargée (elle sert au titre) ; les autres pièces sont préparées au démarrage.

const KITCHEN := "res://art/models/cuisine.glb"
const MODELS := "res://art/models/%s.glb"
const FOODS := "res://art/models/nourriture.glb"
const MASK_CELL := 0.06
## Les morceaux sont grossis pour se lire de haut.
const FOOD_SCALE := [1.7, 1.55, 1.3, 1.12]
const RING_SIZE := [0.095, 0.15, 0.2, 0.26]
const RING_COLORS := [Color(1, 1, 1, 0.85), Color(0.2, 0.75, 1.0, 0.95), Color(1.0, 0.5, 0.05, 1.0),
	Color(1.0, 0.82, 0.05, 1.0)]

## Pendant une chicane, les deux se tournent un peu vers nous pour qu'on voie leur visage.
const TOWARD_CAMERA := 0.75

## Le plan de la pièce montrée.
var map: RoomMap
## Les pièces déjà préparées : nom → {map, node}.
var _rooms: Dictionary = {}
var _room_node: Node3D
var sim: Sim
var camera: Camera3D
var ambiance: Ambiance
var effects: Effects
var _dust_wait := 0.0
var dog: DogView
## La personne qui surveille (Maman, ou Papa).
var mom: PersonView
var people: Dictionary = {}
## Tous les personnages déjà fabriqués, gardés pour éviter les à-coups : nom → PersonView.
var _persons: Dictionary = {}
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
var _mask_key := ""
var _mask_wait := 0.0
var _mask_center := Vector2.INF
var _mask_bytes := PackedByteArray()
var _mask_index := PackedInt32Array()
var _mask_points := PackedVector2Array()
var _steam: CPUParticles3D
var _fridge_light: OmniLight3D
## La lumière de la télé du salon, et si elle joue.
var _tv_light: OmniLight3D
var _tv_on := false
## Les matières des vues par la fenêtre, teintées selon le moment.
var _views: Dictionary = {}
## Les lumières déjà réglées pour cette pièce (modèle et sonde).
var _room_key := ""
## Le temps qui reste au glissement vers le siège (ou depuis le siège) de la personne qui surveille.
var _seat_blend := 0.0
var _mom_was_seated := false
## La conversation à table : qui parle, à qui, et encore combien de temps (les autres le regardent).
var _talker: PersonView
var _talk_to: PersonView
var _talk_left := 0.0
## Dans le noir : jusqu'où voit la personne qui surveille (un cercle au plancher, de la taille des règles).
var _sight: MeshInstance3D
var _dark := false
## Les dessous de table de la pièce, un peu agrandis (où Blanche rampe).
var _tables: Array[Rect2] = []
var _time := 0.0
var _shake := 0.0
var _wobble := 0.0
## La chaise qui vacille (trouvée une fois, au choc).
var _wobble_node: Node3D
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
## Les positions des deux derniers pas des règles : entre deux, l'écran montre un point intermédiaire.
var _before: Dictionary = {}
var _after: Dictionary = {}
var _screen_wait := 0.0
## Positions au dernier pas des règles : l'écran peut aller plus vite que les 60 pas par seconde.
var _last_time := -1.0
var _last_pos: Dictionary = {}
var _speeds: Dictionary = {}


func _ready() -> void:
	map = RoomMap.new("cuisine")
	_kitchen = (load(KITCHEN) as PackedScene).instantiate()
	add_child(_kitchen)
	_rooms["cuisine"] = {"map": map, "node": _kitchen}
	_room_node = _kitchen
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
	effects = Effects.new()
	add_child(effects)
	effects.warm_up()
	_ring_mesh = _make_ring(0.8, 1.0, 40)
	_build_sight_ring()
	_ring_shadow = _flat_mat(Color(0.1, 0.05, 0.0, 0.45))
	for c: Color in RING_COLORS:
		_ring_materials.append(_flat_mat(c))
	dog = DogView.new()
	add_child(dog)
	dog.add_child(_blob_shadow(0.27, 0.5))
	# Le shader de la silhouette se compile à l'écran titre, pas en pleine partie.
	dog.set_see_through(true)
	get_tree().create_timer(0.25).timeout.connect(dog.set_see_through.bind(false))
	# Tous les personnages sont fabriqués d'avance et gardés : pas d'à-coup quand ils entrent en scène.
	for who: String in Levels.PEOPLE:
		_person(who)
	mom = _person("maman")
	for piece: String in ["salle_a_manger", "salon", "fetes"]:
		if FileAccess.file_exists(RoomMap.FOLDER % piece):
			_prepare_room(piece)
	show_title()


## Montre la personne qui surveille (Maman ou Papa) ; l'autre attend hors champ.
func _use_watcher(who: String) -> void:
	if mom != null and mom.who != who:
		mom.visible = false
	mom = _person(who)
	mom.visible = true


## Un personnage, fabriqué une seule fois.
func _person(who: String) -> PersonView:
	if not _persons.has(who):
		var p := PersonView.new(who)
		add_child(p)
		p.add_child(_blob_shadow(0.32 if who == "maman" else 0.3, 0.4))
		p.visible = false
		_persons[who] = p
	return _persons[who]


## Le plan d'une pièce (et sa pièce en 3D, préparée une fois).
func map_for(piece: String) -> RoomMap:
	if not _rooms.has(piece):
		_prepare_room(piece)
	return _rooms[piece].map


func _prepare_room(piece: String) -> void:
	var m := RoomMap.new(piece)
	var model := str(m.data.get("model", piece))
	var node: Node3D = null
	# Les pièces d'un même modèle le partagent ; une maquette grise, elle, est propre à son plan.
	if ResourceLoader.exists(MODELS % model):
		for other: Dictionary in _rooms.values():
			if str(other.map.data.get("model", other.map.id)) == model:
				node = other.node
	if node == null:
		if ResourceLoader.exists(MODELS % model):
			node = (load(MODELS % model) as PackedScene).instantiate()
		else:
			node = Maquette.build(m)
		node.visible = false
		add_child(node)
	_rooms[piece] = {"map": m, "node": node}


## Montre une pièce : son modèle, ses objets cachés pour cette vue, sa zone cachée.
func _show_room(m: RoomMap) -> void:
	if not _rooms.has(m.id):
		_prepare_room(m.id)
	var node: Node3D = _rooms[m.id].node
	if node != _room_node:
		_room_node.visible = false
		_room_node = node
	node.visible = true
	for child in node.get_children():
		if child is Node3D:
			child.visible = not m.data.get("cache", []).has(String(child.name))
	if m != map:
		map = m
		_setup_mask()
		_fit_camera()
		_tables.clear()
		for hd in map.hides:
			if hd.kind == "dessous":
				_tables.append((hd.rect as Rect2).grow(0.08))
		if map.data.has("tele"):
			var tv: Dictionary = map.data.tele
			_tv_light.position = Vector3(tv.pos[0], tv.pos[1], tv.pos[2])
			_tv_light.omni_range = float(tv.portee)
	var probe: Array = []
	if m.data.has("probe"):
		var pr: Dictionary = m.data.probe
		probe = [Vector3(pr.pos[0], pr.pos[1], pr.pos[2]), Vector3(pr.size[0], pr.size[1], pr.size[2])]
	var key := "%s|%s" % [m.data.get("model", m.id), probe]
	if key != _room_key:
		_room_key = key
		ambiance.set_room(str(m.data.get("model", m.id)), probe)


## Le moment de la journée : la lumière, la vue par la fenêtre et les décorations.
func _set_moment(moment: String) -> void:
	ambiance.set_moment(moment)
	_tint(_outside)
	_christmas.visible = moment == "noel" and _room_node == _kitchen
	dog.set_festive(moment == "noel")
	# Ce que le plan montre ou cache selon le moment (Noël au party, l'écran de la télé, l'ampoule pendant le film).
	_tv_on = false
	var hidden: Array = map.data.get("cache", [])
	for part: String in map.data.get("montre", {}):
		var on: bool = map.data.montre[part].has(moment)
		_set_part(part, on and not hidden.has(part))
		_tv_on = _tv_on or (on and part.begins_with("Ecran"))
	for part: String in map.data.get("cache_au", {}):
		_set_part(part, not map.data.cache_au[part].has(moment) and not hidden.has(part))
	var view := _room_node.get_node_or_null(str(map.data.get("vue", ""))) as MeshInstance3D
	if view:
		if not _views.has(view):
			_views[view] = view.mesh.surface_get_material(0).duplicate()
			view.set_surface_override_material(0, _views[view])
		_tint(_views[view])


## Les couverts des places occupées (les gens assis, et la place de Maman si elle s'assoit à table), pas les autres.
func _set_places() -> void:
	var taken := {}
	for s in sim.seated:
		taken[s.seat] = true
	for id: String in sim.level.get("stations", []):
		var st: Dictionary = map.stations[id]
		if st.seated:
			for seat: String in map.seats:
				if (map.seats[seat].pos as Vector2).distance_to(st.pos) < 0.05:
					taken[seat] = true
	for seat: String in map.seats:
		_set_part("Couvert_" + seat, taken.has(seat))


## Quelqu'un parle à table : les autres se tournent vers lui, lui vers celui à qui il parle.
func talk(speaker: PersonView, listener: PersonView, seconds: float) -> void:
	_talker = speaker
	_talk_to = listener
	_talk_left = seconds


## Où regarde une personne assise qui ne surveille pas : vers qui parle (ou, si c'est elle, vers qui l'écoute).
func _talk_focus(p: PersonView) -> Node3D:
	if _talk_left <= 0.0 or _talker == null or not _talker.visible:
		return null
	if p == _talker:
		return _talk_to if _talk_to and _talk_to.visible else null
	return _talker


func _set_part(part: String, on: bool) -> void:
	var node := _room_node.get_node_or_null(part) as Node3D
	if node:
		node.visible = on


## La vue par une fenêtre prend la teinte du moment.
func _tint(mat: BaseMaterial3D) -> void:
	mat.emission = ambiance.sky_tint()
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY


func _build_lights() -> void:
	ambiance = Ambiance.new()
	add_child(ambiance)
	_fridge_light = OmniLight3D.new()
	_fridge_light.position = Vector3(-1.05, 1.35, -1.45)
	_fridge_light.light_color = Color(0.9, 0.97, 1.0)
	_fridge_light.light_energy = 0.0
	_fridge_light.omni_range = 1.4
	add_child(_fridge_light)
	_tv_light = OmniLight3D.new()
	_tv_light.light_color = Color(0.78, 0.88, 1.0)
	_tv_light.light_energy = 0.0
	_tv_light.visible = false
	add_child(_tv_light)


func _build_camera() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.near = 0.1
	camera.far = 40.0
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	Fluidity.apply(get_window())


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


# ------------------------------------------------------------------ le noir

func _build_sight_ring() -> void:
	_sight = MeshInstance3D.new()
	_sight.mesh = _make_ring(0.95, 1.0, 72)
	_sight.material_override = _flat_mat(Color(0.92, 0.97, 1.0, 0.9))
	_sight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sight.visible = false
	add_child(_sight)


## Le cercle de lumière autour de la personne qui surveille : dedans, on te voit.
func _show_sight() -> void:
	_sight.visible = _dark
	if _dark:
		var eye := sim.viewpoint()
		var r := minf(sim.sight_range(), 8.0)
		_sight.position = Vector3(eye.x, 0.012, eye.y)
		_sight.scale = Vector3(r, 1.0, r)


# ------------------------------------------------------------------ zone cachée

## La zone cachée de la pièce montrée : les cases qui peuvent un jour être cachées, libres et près d'une cachette.
func _setup_mask() -> void:
	_mask_rect = map.hides_area(1.15)
	var w := maxi(1, int(_mask_rect.size.x / MASK_CELL))
	var h := maxi(1, int(_mask_rect.size.y / MASK_CELL))
	_mask_image = Image.create(w, h, false, Image.FORMAT_R8)
	_mask_texture = ImageTexture.create_from_image(_mask_image)
	_mask_bytes = PackedByteArray()
	_mask_bytes.resize(w * h)
	_mask_index = PackedInt32Array()
	_mask_points = PackedVector2Array()
	for y in h:
		for x in w:
			var p := _mask_rect.position + Vector2(x + 0.5, y + 0.5) * MASK_CELL
			if map.is_free(p, 0.07) and _near_hide(p):
				_mask_index.append(y * w + x)
				_mask_points.append(p)
	(_mask_node.mesh as PlaneMesh).size = _mask_rect.size
	(_mask_node.material_override as ShaderMaterial).set_shader_parameter("mask", _mask_texture)
	var c := _mask_rect.get_center()
	_mask_node.position = Vector3(c.x, 0.006, c.y)
	_mask_viewer = Vector2.INF


func _near_hide(p: Vector2) -> bool:
	for hd in map.hides:
		var inner: Rect2 = hd.rect.grow(-0.02)
		if hd.kind == "dessous":
			if inner.has_point(p):
				return true
		elif p.distance_to(p.clamp(inner.position, inner.end)) <= float(hd.max):
			return true
	return false


func _build_mask() -> void:
	var plane := PlaneMesh.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D mask : filter_linear, repeat_disable;
uniform float strength = 1.0;
uniform float motion = 1.0;
varying vec3 at;
void vertex() { at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
// Une trace de patte dans chaque case, en quinconce : un coussinet et trois doigts.
float paw(vec2 p) {
	p.x += step(1.0, mod(p.y, 2.0)) * 0.5;
	vec2 q = fract(p) - 0.5;
	float d = length(q * vec2(1.0, 1.2) - vec2(0.0, 0.08)) - 0.17;
	d = min(d, length(q - vec2(-0.19, -0.12)) - 0.075);
	d = min(d, length(q - vec2(0.0, -0.22)) - 0.075);
	d = min(d, length(q - vec2(0.19, -0.12)) - 0.075);
	return 1.0 - smoothstep(-0.015, 0.015, d);
}
void fragment() {
	float m = texture(mask, UV).r;
	float inside = smoothstep(0.38, 0.62, m);
	float edge = smoothstep(0.30, 0.48, m) * (1.0 - smoothstep(0.52, 0.72, m));
	float halo = smoothstep(0.45, 0.62, m) * (1.0 - smoothstep(0.62, 0.98, m));
	float print = paw(at.xz * 6.2);
	float dash = 0.72 + 0.28 * smoothstep(-0.2, 0.2, sin((at.x + at.z) * 38.0 - TIME * 3.0 * motion));
	vec3 fill = mix(vec3(0.03, 0.12, 0.55), vec3(0.55, 0.80, 1.0), print);
	ALBEDO = mix(mix(fill, vec3(0.35, 0.65, 1.0), halo * 0.7), vec3(0.85, 0.96, 1.0), edge);
	ALPHA = max(inside * (0.40 + print * 0.22 + halo * 0.22), edge * 0.95 * dash) * strength;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_mask_node = MeshInstance3D.new()
	_mask_node.mesh = plane
	_mask_node.material_override = mat
	_mask_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mask_node.visible = false
	add_child(_mask_node)
	_setup_mask()


func _update_mask(delta: float) -> void:
	_mask_wait -= delta
	var close := sim.mom_close()
	var low := sim.mom_low()
	var view_key := "%s|%s" % [close, low]
	var eye := sim.viewpoint()
	if _mask_wait > 0.0 or (eye.distance_to(_mask_viewer) < 0.03 and view_key == _mask_key):
		return
	_mask_wait = 0.08
	_mask_viewer = eye
	_mask_key = view_key
	var sum := Vector2.ZERO
	var cells := 0
	for i in _mask_index.size():
		var on := map.hidden(eye, _mask_points[i], close, low)
		_mask_bytes[_mask_index[i]] = 255 if on else 0
		if on:
			sum += _mask_points[i]
			cells += 1
	_mask_center = Vector2.INF
	if cells > 12:
		# L'œil se pose sur une case cachée (au party, il y a deux cachettes : le milieu des deux serait à découvert).
		var mid := sum / cells
		var best := INF
		for i in _mask_index.size():
			if _mask_bytes[_mask_index[i]] > 0 and _mask_points[i].distance_squared_to(mid) < best:
				best = _mask_points[i].distance_squared_to(mid)
				_mask_center = _mask_points[i]
	_mask_image.set_data(_mask_image.get_width(), _mask_image.get_height(), false, Image.FORMAT_R8, _mask_bytes)
	_mask_texture.update(_mask_image)


# ------------------------------------------------------------------ nourriture

## Une matière sans ombrage, transparente, vue des deux côtés (anneaux et marques au plancher).
static func _flat_mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = c
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


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
		y = map.surface_height(item.spot)
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
	_show_room(_rooms.cuisine.map)
	_set_moment("matin")
	sim = null
	view = "titre"
	_clear_level()
	_use_watcher("maman")
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
	_show_room(sim.map)
	_use_watcher(sim.watcher)
	_dark = sim.level.has("dark")
	_set_moment(sim.level.get("moment", "midi"))
	_set_places()
	mom.dish = str(sim.level.get("plat", ""))
	mom.hold_dish(_food_meshes.get(PersonView.DISHES.get(mom.dish, ""), null))
	view = "jeu"
	_last_time = -1.0
	_before.clear()
	_after.clear()
	_last_pos.clear()
	_speeds.clear()
	_mask_node.visible = true
	(_mask_node.material_override as ShaderMaterial).set_shader_parameter("motion", 0.0 if reduced_motion else 1.0)
	_mask_viewer = Vector2.INF
	dog.position = Vector3(sim.dog_pos.x, 0, sim.dog_pos.y)
	_dog_yaw = atan2(sim.dog_dir.x, sim.dog_dir.y)
	_mom_yaw = atan2(sim.mom_dir.x, sim.mom_dir.y)
	_cam_pos = Vector3.ZERO
	var cast: Array = sim.level.helpers.duplicate()
	for s in sim.seated:
		cast.append(s.who)
	for w in sim.walkers:
		cast.append(w.who)
	for who: String in cast:
		if who != sim.watcher:
			people[who] = _person(who)
			people[who].visible = false


func _clear_level() -> void:
	for node: Node in _items.values():
		node.queue_free()
	_items.clear()
	for p: PersonView in people.values():
		p.visible = false
		p.talking = 0.0
	people.clear()
	_talker = null
	_talk_to = null
	_talk_left = 0.0
	if dog:
		dog.drop_held()
		dog.chewing = false
		dog.carrying = false
		dog.sad = false
		mom.talking = 0.0
		mom.head_yaw = 0.0
		mom.visible = true
	_held_id = -1
	_reach_spot = ""
	_laugh = 0.0
	_surprised = 0.0
	_shake = 0.0
	_wobble = 0.0
	if _mask_node:
		_mask_node.visible = false
	_dark = false
	if _sight:
		_sight.visible = false
	if effects:
		effects.clear()


## Les réactions visibles aux événements de la partie.
func on_event(e: Dictionary) -> void:
	effects.reduced_motion = reduced_motion
	match e.type:
		"ate":
			if e.item.size > Sim.Size.CRUMB:
				effects.crumbs(_muzzle())
			if e.item.size >= Sim.Size.BIG or e.mult > 1:
				effects.stars(dog.head_position() + Vector3(0, 0.2, 0))
		"grabbed":
			effects.crumbs(_muzzle())
		"meal_ready":
			if e.stars > 0:
				effects.hearts(dog.head_position() + Vector3(0, 0.15, 0))
		"caught":
			_shake = 1.0
			_surprised = 0.45
			mom.scold_style = (mom.scold_style + 1 + randi() % 2) % 3
			dog.tilt = -1.0 if randf() < 0.5 else 1.0
		"corner_arrive":
			if randf() < 0.6:
				_laugh = 1.6
		"noise":
			if e.what in ["tabouret", "chaise"]:
				_wobble = 1.0
				_wobble_chair(e.index)
			_shake = maxf(_shake, 0.25)


func _muzzle() -> Vector3:
	return dog.head_position() + Vector3(sin(_dog_yaw) * 0.18, 0.02, cos(_dog_yaw) * 0.18)


func _process(delta: float) -> void:
	_time += delta
	# La fenêtre peut changer de taille ou passer sur un autre écran.
	_screen_wait -= delta
	if _screen_wait <= 0.0:
		_screen_wait = 0.5
		Fluidity.apply(get_window())
	if sim != null:
		_measure_speeds()
		_show_dog(delta)
		_dust_wait -= delta
		if sim.dog_moving and _speeds.get("blanche", 0.0) > 1.2 and _dust_wait <= 0.0:
			_dust_wait = 0.22
			effects.dust(dog.position + Vector3(-sin(_dog_yaw) * 0.16, 0.04, -cos(_dog_yaw) * 0.16))
		_show_mom(delta)
		_show_people(delta)
		_sync_food(delta)
		_update_mask(delta)
		_show_sight()
		dog.set_see_through(_dog_covered())
		_steam.emitting = _room_node == _kitchen and (sim.activity == "brasser" or sim.activity == "surprise" \
			or sim.walk_activity == "surprise")
	_show_furniture(delta)
	_move_camera(delta)


static func _turn(from: float, to: float, delta: float, speed: float) -> float:
	return lerp_angle(from, to, 1.0 - exp(-delta * speed))


## Un meuble ou une personne passe-t-il entre la caméra et Blanche ?
func _dog_covered() -> bool:
	var eye := camera.global_position
	for height: float in [0.14, 0.42]:
		var point := Vector3(sim.dog_pos.x, height, sim.dog_pos.y)
		for hd in map.hides:
			var r: Rect2 = hd.rect
			var top: float = hd.height
			# Sous une table, c'est le plateau qui la cache.
			var bottom := top - 0.07 if hd.kind == "dessous" else 0.0
			if AABB(Vector3(r.position.x, bottom, r.position.y), Vector3(r.size.x, top - bottom, r.size.y)) \
					.intersects_segment(eye, point):
				return true
		var bodies: Array = [] if sim.mom_out else [sim.mom_pos]
		for h in sim.helpers:
			bodies.append(h.pos)
		for c: Vector2 in bodies:
			var body := AABB(Vector3(c.x - 0.2, 0.0, c.y - 0.2), Vector3(0.4, 1.5, 0.4))
			if body.intersects_segment(eye, point):
				return true
	return false


## Sous une table (où il faut ramper).
func _under_table(p: Vector2) -> bool:
	for r in _tables:
		if r.has_point(p):
			return true
	return false


## Le milieu de la zone cachée (Vector2.INF s'il n'y en a pas).
func hidden_center() -> Vector2:
	return _mask_center


## La vitesse de chacun, mesurée seulement quand les règles ont avancé.
## Appelé après chaque pas des règles.
func tick() -> void:
	_before = _after
	_after = {"blanche": sim.dog_pos, "maman": sim.mom_pos}
	for h in sim.helpers:
		_after[h.who] = h.pos


## Où montrer quelqu'un : entre ses deux dernières positions, selon le temps écoulé depuis le dernier pas. Sans cela,
## les mouvements saccadent dès que l'écran ne tourne pas exactement à 60 images par seconde.
func _smooth(who: String, now: Vector2) -> Vector2:
	if not _after.has(who) or not _before.has(who) or _after[who].distance_to(now) > 0.001:
		return now
	return (_before[who] as Vector2).lerp(now, Engine.get_physics_interpolation_fraction())


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
static func _follow_floor(node: Node3D, to: Vector2, delta: float, rate := 45.0) -> void:
	var f := 1.0 - exp(-delta * rate)
	node.position.x = lerpf(node.position.x, to.x, f)
	node.position.z = lerpf(node.position.z, to.y, f)


func _show_dog(delta: float) -> void:
	if sim.dog_state == Sim.Dog.REACHING:
		_reach_spot = sim.reach_item.spot
	# Dressée, elle se place bien en face du morceau, les pattes sur le bord (à l'écran seulement).
	var up: bool = sim.dog_state == Sim.Dog.REACHING \
		or (sim.dog_state == Sim.Dog.LOWERING and sim.lower_left > Sim.DESCEND_TIME * 0.5)
	var at := _smooth("blanche", sim.dog_pos)
	var heading := sim.dog_dir
	# Sur une table basse, elle ne se dresse pas : elle tend le nez.
	if not map.spots.has(_reach_spot):
		# Un endroit de la mission d'avant (on a changé de mission pendant qu'elle redescendait).
		_reach_spot = ""
	var low: bool = _reach_spot != "" and map.spots[_reach_spot].surface == "low"
	if up and _reach_spot != "":
		var spot: Dictionary = map.spots[_reach_spot]
		at = spot.stand
		heading = spot.food - spot.stand
		dog.surface_y = map.surface_height(_reach_spot)
		if low:
			at = spot.stand.lerp(spot.food, 0.18)
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
			dog.pose = "sniff" if low else "reach"
			dog.reach_progress = clampf(sim.reach_progress / sim.grab_time(sim.reach_item), 0.0, 1.0)
		Sim.Dog.LOWERING:
			dog.pose = ("sniff" if low else "reach") if sim.lower_left > Sim.DESCEND_TIME * 0.5 else "stand"
			dog.reach_progress = 0.3
		_:
			if sim.dog_moving:
				dog.pose = "crawl" if _under_table(sim.dog_pos) else "walk"
			elif not sim.mouth.is_empty():
				dog.chewing = true
				dog.pose = "crouch" if sim.dog_hidden() else "stand"
			elif sim.dog_still_time > 0.7:
				dog.pose = "crouch" if sim.dog_hidden() else "sit"
			else:
				dog.pose = "stand"


func _show_mom(delta: float) -> void:
	# Sortie à la cuisine, on ne la voit plus ; elle réapparaît d'un coup dans la porte.
	var was := mom.visible
	mom.visible = not sim.mom_out
	if not mom.visible:
		return
	# Assise à son poste (sauf pendant un but : Papa saute debout), on la montre sur son siège.
	var st: Dictionary = map.stations[sim.station]
	# Pendant le but (et seulement pendant), Papa saute debout ; le regard qui suit, il le fait assis.
	var seated := sim.mom_seated() and not (sim.mom_state == Sim.Mom.BUSY and sim.activity == "but")
	mom.seat_y = st.seat_y if seated else 0.0
	var shown_at: Vector2 = st.hips if seated else _smooth("maman", sim.mom_pos)
	if seated != _mom_was_seated:
		# Elle s'assoit (ou se lève) : on la glisse vers le siège au lieu de la faire sauter.
		_mom_was_seated = seated
		_seat_blend = 0.45
	_seat_blend -= delta
	if not was:
		mom.position = Vector3(shown_at.x, 0, shown_at.y)
	_follow_floor(mom, shown_at, delta, 9.0 if _seat_blend > 0.0 else 45.0)
	mom.speed = _speeds.get("maman", 0.0)
	var dir := sim.mom_dir
	if sim.mom_state == Sim.Mom.BUSY and sim.activity == "chicane":
		dir += toward_camera(sim.mom_pos)
	if seated:
		dir = st.face
	var yaw := atan2(dir.x, dir.y)
	_mom_yaw = _turn(_mom_yaw, yaw, delta, 16.0)
	mom.rotation.y = _mom_yaw
	var relative := _aim(shown_at, sim.dog_pos, _mom_yaw)
	mom.head_yaw = 0.0
	_talk_left -= delta
	var focus := _talk_focus(mom)
	if seated and focus and sim.mom_state == Sim.Mom.BUSY:
		mom.head_yaw = clampf(_aim(shown_at, Vector2(focus.position.x, focus.position.z), _mom_yaw), -40.0, 40.0)
	_laugh -= delta
	mom.twist = 0.0
	match sim.mom_state:
		Sim.Mom.BUSY:
			mom.pose = sim.activity
			if sim.activity == "chicane" and seated:
				mom.pose = "argue_seated"
			elif sim.activity == "but":
				mom.pose = "cheer"
		Sim.Mom.HINT:
			mom.pose = {"real": "hint", "feint": "feint", "round": "round", "retour": "idle"}[sim.hint_kind]
			if sim.remote_hint():
				mom.pose = "remote"
		Sim.Mom.TURN:
			mom.pose = "look"
		Sim.Mom.LOOK:
			mom.pose = "seated" if seated else "look"
			if not sim.dog_hidden():
				mom.head_yaw = clampf(relative, -28.0, 28.0)
				if seated:
					# Assis, il se retourne vers elle.
					mom.twist = clampf(relative, -70.0, 70.0)
		Sim.Mom.TURN_BACK:
			mom.pose = "idle"
		Sim.Mom.SCOLD:
			mom.pose = "point"
			var corner := map.corner - sim.mom_pos
			# Elle regarde Blanche et pointe le coin.
			_mom_yaw = _turn(_mom_yaw, atan2(corner.x, corner.y), delta, 20.0)
			mom.head_yaw = clampf(relative, -28.0, 28.0)
		Sim.Mom.WALK, Sim.Mom.ROUND:
			mom.pose = "carry_plate" if sim.serving() else "walk"
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
			_follow_floor(p, _smooth(h.who, h.pos), delta)
		else:
			p.position = Vector3(h.pos.x, 0, h.pos.y)
		p.speed = _speeds.get(h.who, 0.0)
		var moving: bool = h.state != "stay"
		var dir: Vector2 = h.dir if moving else sim.mom_pos - h.pos
		if h.state == "argue":
			dir = dir.normalized() + toward_camera(h.pos)
		if h.who == "charlotte" and h.snitch > 0.0:
			dir = sim.dog_pos - h.pos
			p.pose = "snitch"
		elif h.who == "papa":
			p.pose = "argue" if h.state == "argue" else "carry"
		else:
			p.pose = "walk" if moving else "wave"
		var yaw := atan2(dir.x, dir.y)
		p.rotation.y = yaw if not was_visible else _turn(p.rotation.y, yaw, delta, 10.0)
	for s in sim.seated:
		var p: PersonView = people.get(s.who)
		if p == null:
			continue
		present[s.who] = true
		p.visible = true
		var seat: Dictionary = map.seats[s.seat]
		p.seat_y = seat.seat_y
		p.position = Vector3(seat.hips.x, 0, seat.hips.y)
		p.rotation.y = _turn(p.rotation.y, atan2(seat.face.x, seat.face.y), delta, 10.0)
		var relative := _aim(seat.hips, sim.dog_pos if s.snitch > 0.0 else sim.viewpoint(), p.rotation.y)
		var focus := _talk_focus(p)
		if focus and s.snitch <= 0.0 and s.state != "regarde" and s.state != "slip":
			relative = _aim(seat.hips, Vector2(focus.position.x, focus.position.z), p.rotation.y)
		p.head_yaw = clampf(relative, -40.0, 40.0)
		p.twist = clampf(relative, -50.0, 50.0) if s.snitch > 0.0 or s.state in ["argue", "slip"] else 0.0
		match s.state:
			"slip":
				p.pose = "slip"
			"argue":
				p.pose = "argue_seated"
			"eat":
				p.pose = "manger"
			_:
				p.pose = "snitch_seated" if s.snitch > 0.0 else ("seated_chat" if s.state == "jase" else "seated")
		if s.role == "decor":
			p.pose = s.pose
	for w in sim.walkers:
		var p: PersonView = people.get(w.who)
		if p == null:
			continue
		var was_visible := p.visible
		present[w.who] = true
		p.visible = true
		if was_visible:
			_follow_floor(p, _smooth(w.who, w.pos), delta)
		else:
			p.position = Vector3(w.pos.x, 0, w.pos.y)
		p.speed = _speeds.get(w.who, 0.0)
		var dir: Vector2 = w.dir
		if w.snitch > 0.0:
			dir = sim.dog_pos - w.pos
		p.rotation.y = _turn(p.rotation.y, atan2(dir.x, dir.y), delta, 10.0)
		p.pose = "snitch" if w.snitch > 0.0 else ("walk" if w.state == "walk" else "chat")
	for who: String in people:
		if not present.has(who):
			people[who].visible = false


## La chaise bousculée vacille ; celle qui vacillait reprend sa place.
func _wobble_chair(index: int) -> void:
	if _wobble_node:
		_wobble_node.rotation.y = 0.0
	_wobble_node = null
	if _room_node != _kitchen and index >= 0 and index < map.stools.size():
		_wobble_node = _room_node.find_child("Chaise_" + str(map.stools[index].name), true, false) as Node3D


## L'angle (en degrés) dont il faut tourner la tête, depuis un corps tourné de `yaw`, pour regarder `toward`.
static func _aim(from: Vector2, toward: Vector2, yaw: float) -> float:
	var to := toward - from
	return rad_to_deg(wrapf(atan2(to.x, to.y) - yaw, -PI, PI))


## Vers la caméra, au sol, depuis `from` (pour se tourner un peu vers nous).
func toward_camera(from: Vector2) -> Vector2:
	var cam: Array = map.data.camera.pos
	return (Vector2(cam[0], cam[2]) - from).normalized() * TOWARD_CAMERA


func _show_furniture(delta: float) -> void:
	var open := sim != null and sim.mom_state == Sim.Mom.BUSY and sim.activity == "frigo"
	open = open or (sim != null and sim.station == "frigo" and sim.mom_state == Sim.Mom.HINT)
	_fridge_door.rotation.y = _turn(_fridge_door.rotation.y, deg_to_rad(-112.0) if open else 0.0, delta, 7.0)
	_fridge_light.light_energy = lerpf(_fridge_light.light_energy, 0.9 if open else 0.0, 1.0 - exp(-delta * 7.0))
	# La télé éclaire la pièce : par éclats pendant le film (la même lumière que celle des règles), plus doucement au hockey.
	var tv := 0.0
	if not _tv_on and _tv_light.light_energy < 0.01:
		_tv_light.visible = false
	elif _tv_on:
		tv = 0.35 + (0.0 if reduced_motion else 0.12 * sin(_time * 7.0) * sin(_time * 2.3))
		if sim != null and sim.level.has("dark"):
			tv = lerpf(0.25, 2.6, sim.tv_light)
	if _tv_on or _tv_light.visible:
		_tv_light.light_energy = lerpf(_tv_light.light_energy, tv, 1.0 - exp(-delta * 10.0))
		# Éteinte, elle ne coûte rien.
		_tv_light.visible = _tv_light.light_energy > 0.01
	_wobble = maxf(0.0, _wobble - delta * 1.4)
	if _stool and _room_node == _kitchen:
		_stool.rotation.z = sin(_time * 24.0) * 0.14 * _wobble
	elif _wobble_node:
		_wobble_node.rotation.y = sin(_time * 24.0) * 0.05 * _wobble
		if _wobble <= 0.0:
			_wobble_node.rotation.y = 0.0
			_wobble_node = null


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
		var title: Dictionary = map.data.camera_title
		pos = Vector3(title.pos[0] + drift, title.pos[1], title.pos[2])
		target = Vector3(title.target[0], title.target[1], title.target[2])
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
