extends Node2D
# Animal design sheet: Godot --path . res://tools/animals.tscn -- --screenshot=/tmp/animals.png [--seed=1] [--focus=x,y --zoom=3]
# Row 1-2: every cat coat walking / sitting / loafing / being petted. Middle: squirrels. Bottom: every dog breed with a walker.

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#F4F1EA"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_arg("--seed=", "1"))
	var states := ["walk", "sit", "loaf", "pet"]
	for i in StrayCat.COATS.size():
		for j in 2:
			var cat := StrayCat.random(rng)
			cat.coat = StrayCat.COATS[i]
			cat.wander = false
			cat.size = 1.0
			cat.facing = 1
			cat._state = states[(i + j * 2) % 4]
			cat.position = Vector2(70 + i * 150 + j * 70, 120 + j * 0)
			if j == 1:
				cat.position = Vector2(70 + i * 150, 250)
			add_child(cat)
	# Charlotte petting a cat, enlarged; the cat is drawn in front of her as in the game.
	var zoom := Node2D.new()
	zoom.scale = Vector2.ONE * 2.0
	zoom.position = Vector2(1130, 420)
	add_child(zoom)
	var charlotte := Character.new()
	charlotte.look = CharacterLook.usual()
	charlotte.scale = Vector2.ONE * 0.38
	charlotte.position = Vector2(0, 0)
	charlotte.facing = -1
	zoom.add_child(charlotte)
	var pet := StrayCat.random(rng)
	pet.position = Vector2(-26, 8)
	pet.size = 0.7
	pet.wander = false
	pet.facing = 1
	zoom.add_child(pet)
	pet.call_deferred("interact", charlotte)
	# Squirrels, enlarged: sitting and running, grey and black.
	for i in 4:
		var squirrel := Squirrel.new()
		squirrel.position = Vector2(120 + i * 200, 400)
		squirrel.scale = Vector2.ONE * 2.2
		add_child(squirrel)
		squirrel.fur = Color("#2B2826") if i % 2 == 1 else Color("#7D7670")
		squirrel.set_process(false)
		squirrel._state = "run" if i >= 2 else "idle"
		squirrel._hop = 0.3
	var keys: Array = Dog.BREEDS.keys()
	for i in keys.size():
		var walker := Passerby.new()
		walker.look = CharacterLook.random(rng, "adult")
		walker.scale = Vector2.ONE * 0.38
		walker.position = Vector2(60 + i * 135, 640)
		walker.facing = 1
		walker.walk_speed = 0.0
		add_child(walker)
		var dog := Dog.random(rng, walker)
		dog.breed = keys[i]
		dog._b = Dog.BREEDS[keys[i]]
		var coat: Array = dog._b.coats[0]
		dog._base = Color(coat[0])
		dog._saddle = Color(coat[1]) if coat.size() > 1 and coat[1] != "" else Color.TRANSPARENT
		dog._white = Color(coat[2]) if coat.size() > 2 and coat[2] != "" else Color.TRANSPARENT
		dog._mask = Color(coat[3]) if coat.size() > 3 else Color.TRANSPARENT
		dog._spots.clear()
		if dog._b.get("spots", false):
			for k in 9:
				var sp := Vector2(rng.randf_range(-0.65, 0.65), rng.randf_range(-0.55, 0.45)).limit_length(0.68)
				dog._spots.append(Vector3(sp.x, sp.y, rng.randf_range(1.5, 2.5)))
		dog._lead = 55.0
		add_child(dog)
		if i == 0 or i == 2:
			# Charlotte petting the labrador and the corgi, at game depths (dogs walk 22 px further back).
			var petter := Character.new()
			petter.look = CharacterLook.usual()
			petter.scale = Vector2.ONE * 0.38
			petter.facing = -1
			add_child(petter)
			dog.position = Vector2(walker.position.x + 55.0, 644)
			dog.reserve()
			petter.position = Vector2(dog.approach_x(dog.position.x + 100.0), 640 + 4 + 32 - 10)
			dog.call_deferred("interact", petter)
		var label := Label.new()
		label.text = keys[i]
		label.position = Vector2(30 + i * 135, 660)
		label.add_theme_color_override("font_color", Color("#333333"))
		add_child(label)
	var focus := _arg("--focus=", "")
	if focus != "":
		var cam := Camera2D.new()
		cam.position = Vector2(focus.get_slice(",", 0).to_float(), focus.get_slice(",", 1).to_float())
		cam.zoom = Vector2.ONE * _arg("--zoom=", "3").to_float()
		add_child(cam)
	var shot := _arg("--screenshot=", "")
	if shot != "":
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
