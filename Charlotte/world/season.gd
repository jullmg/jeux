class_name Season
extends RefCounted
## The current season and everything that changes with it: tree and ground colours, what falls from the
## trees, the sky, the colour grade, gardens, and how passersby dress. Autumn is the game's original look.
## Elements read it when they are built, so a change takes effect when the scene reloads (see DebugMenu).

const ALL: Array[String] = ["spring", "summer", "autumn", "winter"]
const NAMES := {"spring": "Printemps", "summer": "Été", "autumn": "Automne", "winter": "Hiver"}

static var current := "autumn"
## Days gone by (Charlotte sleeping in her bed starts a new one); one day the seasons will follow them.
static var day := 1


static func is_winter() -> bool:
	return current == "winter"


## Facade SVG for a house: autumn keeps the original files, the other seasons have their own folder.
static func decor(art: String) -> String:
	if current == "autumn":
		return "res://art/decor/%s.svg" % art
	return "res://art/decor/%s/%s.svg" % [current, art]


## Canopy palettes for street trees (empty in winter: bare branches).
static func tree_palettes() -> Array:
	match current:
		"spring":
			return [["#9BCB6A", "#B5D97A", "#7FB85A", "#C8E39A", "#A6D07A"],
				["#F7C6D9", "#F2A7C9", "#FBE0EA", "#E890B4", "#FFFFFF"],
				["#8CC46A", "#A8D67E", "#F7C6D9", "#C8E39A", "#7FB85A"]]
		"summer":
			return [["#3E8E3A", "#4FA34A", "#2F7A30", "#5DB55A", "#367F33"],
				["#4A9A3E", "#64B04F", "#3A8636", "#7CC261", "#2E6E2C"],
				["#3F8A46", "#55A055", "#2C6E36", "#6DB86A", "#478F3E"]]
		"winter":
			return []
	return [["#C0392B", "#D9542E", "#A93226", "#E67E22", "#B03A2E"],
		["#E67E22", "#D35400", "#F39C12", "#E59866", "#CA6F1E"],
		["#F1C40F", "#E5B33A", "#D4AC0D", "#F7DC6F", "#E8A33D"],
		["#E67E22", "#C0392B", "#F1C40F", "#9BAE4A", "#D35400"]]


## A handful of canopy colours, for distant or simplified trees.
static func foliage() -> Array[Color]:
	match current:
		"spring":
			return [Color("#9BCB6A"), Color("#F7C6D9"), Color("#B5D97A"), Color("#7FB85A"), Color("#F2A7C9")]
		"summer":
			return [Color("#3E8E3A"), Color("#4FA34A"), Color("#2F7A30"), Color("#5DB55A"), Color("#367F33")]
		"winter":
			return [Color("#EEF2F5"), Color("#DDE4EA"), Color("#F7F9FA"), Color("#CBD5DD"), Color("#E6ECF0")]
	return [Color("#D9682B"), Color("#B5442E"), Color("#E3A33A"), Color("#C9562E"), Color("#8E3A24")]


## What lies on sidewalks and gutters, and how much of it (1 = autumn's carpet of leaves).
static func litter() -> Array[Color]:
	match current:
		"spring":
			return [Color("#F7C6D9"), Color("#FBE0EA"), Color("#FFFFFF"), Color("#E890B4")]
		"summer":
			return [Color("#6DB86A"), Color("#4FA34A"), Color("#C9B98A")]
		"winter":
			return [Color("#F4F6F8")]
	return [Color("#D9682B"), Color("#B5442E"), Color("#E3A33A"), Color("#C9562E"), Color("#8E3A24"), Color("#E8C04A")]


static func litter_amount() -> float:
	return {"spring": 0.25, "summer": 0.08, "autumn": 1.0, "winter": 0.0}[current]


## Colours of what drifts down from the trees and blows in the wind (leaves, petals, snow).
static func falling_colors() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	match current:
		"spring":
			g.colors = PackedColorArray([Color("#F7C6D9"), Color("#FFFFFF"), Color("#F2A7C9"), Color("#FBE0EA"), Color("#E890B4")])
		"summer":
			g.colors = PackedColorArray([Color("#4FA34A"), Color("#6DB86A"), Color("#3E8E3A"), Color("#7CC261"), Color("#5DB55A")])
		"winter":
			g.colors = PackedColorArray([Color.WHITE, Color("#F4F8FB"), Color.WHITE, Color("#EAF1F6"), Color.WHITE])
		_:
			g.colors = PackedColorArray([Color("#C0392B"), Color("#E67E22"), Color("#F1C40F"), Color("#D35400"), Color("#B5442E")])
	return g


## How much drifts down from each tree (autumn 1).
static func falling_amount() -> float:
	return {"spring": 0.6, "summer": 0.0, "autumn": 1.0, "winter": 0.0}[current]


static func falling_texture() -> Texture2D:
	return PropArt.flake() if current == "winter" else PropArt.leaf()


## Sky gradient, top to horizon.
static func sky() -> PackedColorArray:
	match current:
		"spring":
			return PackedColorArray([Color("#5A9BD8"), Color("#93C6EC"), Color("#D3E8F3"), Color("#F4E9D6"), Color("#F3D9C4")])
		"summer":
			return PackedColorArray([Color("#3A82D4"), Color("#6CB2EA"), Color("#B6DCF2"), Color("#E8F1EE"), Color("#F5E4C4")])
		"winter":
			return PackedColorArray([Color("#8EA6C0"), Color("#B2C4D5"), Color("#D6DFE7"), Color("#E7E3DE"), Color("#E0D3CA")])
	return PackedColorArray([Color("#4F86C6"), Color("#86B5E0"), Color("#C9DDEB"), Color("#F6D9B4"), Color("#F4B98C")])


## How strong the low sun is (autumn 1).
static func sun() -> float:
	return {"spring": 0.85, "summer": 1.0, "autumn": 1.0, "winter": 0.55}[current]


## Colour grade tint (the grade shader's `tint`).
static func tint() -> Vector3:
	match current:
		"spring":
			return Vector3(1.02, 1.0, 0.95)
		"summer":
			return Vector3(1.04, 1.01, 0.9)
		"winter":
			return Vector3(0.96, 0.99, 1.05)
	return Vector3(1.05, 0.99, 0.9)


## Snow falling over an outdoor scene in winter (screen space, under the colour grade).
static func add_weather(parent: Node) -> void:
	if current != "winter":
		return
	var layer := CanvasLayer.new()
	layer.layer = 5
	parent.add_child(layer)
	for depth in [[90, 0.5, 40.0], [60, 0.9, 70.0]]:
		var snow := CPUParticles2D.new()
		snow.texture = PropArt.flake()
		snow.amount = depth[0]
		snow.lifetime = 12.0
		snow.preprocess = 12.0
		snow.position = Vector2(640, -20)
		snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		snow.emission_rect_extents = Vector2(760, 10)
		snow.direction = Vector2(0.25, 1)
		snow.spread = 20.0
		snow.gravity = Vector2(4, 8)
		snow.initial_velocity_min = depth[2] * 0.6
		snow.initial_velocity_max = depth[2]
		snow.scale_amount_min = depth[1] * 0.6
		snow.scale_amount_max = depth[1]
		snow.color = Color(1, 1, 1, 0.85)
		layer.add_child(snow)


## Adjusts a passerby's random look to the weather, without touching any random generator (so the street
## keeps the same people in every season).
static func dress_for_weather(look: CharacterLook) -> void:
	match current:
		"winter":
			look.outfit = "coat"
			look.sleeve = "long"
			look.pattern = "none"
			if look.legwear == "socks":
				look.legwear = "pants"
				look.legwear_color = Color("#2F3E5C")
			look.shoes = "boot"
			if look.hat == "" or look.hat in ["cap", "witch", "cat_ears"]:
				look.hat = "tuque"
			if look.scarf == "":
				look.scarf = "#E04F5F" if look.outfit_color.v > 0.5 else "#FFD23F"
		"summer":
			if look.outfit in ["coat", "sweater"]:
				look.outfit = "tshirt"
				look.pattern = "none"
			look.sleeve = "short" if look.outfit != "dress" else look.sleeve
			look.scarf = ""
			if look.hat in ["tuque", "witch", "cat_ears"]:
				look.hat = "cap"
			if look.shoes == "boot":
				look.shoes = "sneaker"
		"spring":
			if look.hat in ["witch", "cat_ears"]:
				look.hat = ""
		"autumn":
			pass
