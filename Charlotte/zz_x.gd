extends Node

func _ready() -> void:
	var sc: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(sc)
	_go.call_deferred(sc)

func _go(sc: Node) -> void:
	await get_tree().process_frame
	for name in ["ruelle_verte", "ruelle"]:
		var i: int = sc.layout.find(name)
		print("LANE ", name, " start=", sc._starts[i], " w=", sc._tex(name).get_width() * sc.HOUSE_SCALE)
	get_tree().quit()
