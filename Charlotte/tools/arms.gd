extends Node2D
# Design sheet for the arms and hands: characters of every age in the poses of the game, big. Pick a row with --set=N.
# Godot --path . --screen 1 res://tools/arms.tscn -- --screenshot=/tmp/arms.png [--set=0] [--zoom=1.0] [--only=N (one pose, centred)]
#   set 0: standing, walking (two phases), running      set 1: gestures (wave, stretch), petting, holding things
#   set 2: tasks (stir, read, phone, type, wash, drink, fridge, exercise)       set 3: ages and long sleeves

const SETS := [
	[["rest", {}], ["walk 0", {"walk": 0.0}], ["walk .25", {"walk": 0.25}], ["walk .5", {"walk": 0.5}], ["walk .75", {"walk": 0.75}], ["run 0", {"walk": 0.1, "run": true}], ["run .5", {"walk": 0.6, "run": true}]],
	[["wave", {"gesture": "wave"}], ["stretch", {"gesture": "stretch"}], ["pet low", {"pet": 1.0}], ["pet high", {"pet": 0.0}], ["milk", {"carry": "milk"}], ["can", {"carry": "can"}], ["pour", {"carry": "can", "lift": 1.0}], ["cat", {"carry": "cat:cat"}]],
	[["stir", {"task": "stir"}], ["read", {"task": "read"}], ["phone", {"task": "phone"}], ["type", {"task": "type"}], ["wash", {"task": "wash"}], ["drink", {"task": "drink"}], ["fridge", {"task": "fridge"}], ["exercise", {"task": "exercise"}]],
	[["child", {"age": "child"}], ["teen", {"age": "teen"}], ["adult", {"age": "adult"}], ["senior", {"age": "senior"}], ["long sleeve", {"age": "child", "sleeve": "long"}], ["short", {"age": "child", "sleeve": "short"}], ["adult long", {"age": "adult", "sleeve": "long"}]],
]


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color("#EDE6D8")
	back.size = Vector2(1280, 720)
	add_child(back)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var row: Array = SETS[int(_arg("--set=", "0"))]
	var zoom := float(_arg("--zoom=", "1.0"))
	var per_row := 4
	var only := int(_arg("--only=", "-1"))
	for i in row.size():
		if only >= 0 and i != only:
			continue
		var spec: Dictionary = row[i][1]
		var look := CharacterLook.usual() if not spec.has("age") else CharacterLook.random(rng, spec.age)
		if spec.has("sleeve"):
			look.sleeve = spec.sleeve
		var c := Character.new()
		c.look = look
		c.scale = Vector2.ONE * 0.62 * zoom
		c.position = Vector2(170 + (i % per_row) * 300, 330 + (i / per_row) * 350)
		if only >= 0:
			c.position = Vector2(640, 660)
		c.animate = false
		c.fidgets = false
		add_child(c)
		c.facing = 1
		if spec.has("walk"):
			c.is_walking = true
			c.walk_phase = spec.walk
			c.running = spec.get("run", false)
			c._run = 1.0 if spec.get("run", false) else 0.0
		if spec.has("pet"):
			c._pet = 1.0
			c._pet_low = spec.pet
		if spec.has("task"):
			c.task = spec.task
			c._time = 0.35
		if spec.has("gesture"):
			c._gesture = spec.gesture
			c._gesture_len = 1.0
			c._gesture_t = 0.5
		if spec.has("carry"):
			Carry.clear()
			var kind: String = spec.carry.get_slice(":", 0)
			Carry.take(c, kind, spec.carry.get_slice(":", 1) if spec.carry.contains(":") else "")
			c._hold = 1.0
			c.carry_lift = spec.get("lift", 0.0)
		c._apply_pose()
		var label := Label.new()
		label.text = row[i][0]
		label.position = c.position + Vector2(-60, 40)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color("#3A3A48"))
		add_child(label)
	Carry.clear()
	var shot := _arg("--screenshot=", "")
	if shot != "":
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
