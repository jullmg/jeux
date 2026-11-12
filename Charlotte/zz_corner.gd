extends Node2D
const S := "/private/tmp/claude-501/-Users-mercieju-Documents-git-github-com-jeux/4981f11c-f620-40c9-b039-70572133b7b5/scratchpad/"

func _ready() -> void:
	Transition.arrive = "6e_from_holt"
	var street: Node = load("res://scenes/main.tscn").instantiate()
	add_child(street)
	await get_tree().create_timer(1.6).timeout
	print("ZZ charlotte x=", street._charlotte.position.x, " width=", street._street_width)
	for cs in street._cross_streets:
		print("ZZ gap x0=", cs.x0, " x1=", cs.x1, " road=", cs.road_x(638.0))
	print("ZZ segments=", street._segments)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(S + "corner.png")
	get_tree().quit()
