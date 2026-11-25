extends Node
## Calls `interact` on every interactable of a scene, one after the other, to flush out script errors in the handlers.
## Usage: Godot --path . res://tools/fuzz_interact.tscn -- --no-save --scene=res://scenes/x.tscn [--from=N] [--season=winter]
## Prints "FUZZ n/total" lines, and "NEXT=i" when an interaction changed the scene (run again with --from=i), "END" when done.
func _arg(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


func _ready() -> void:
	var path := _arg("--scene=")
	var from := int(_arg("--from=")) if _arg("--from=") != "" else 0
	var scene: Node = load(path).instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().create_timer(1.5).timeout
	get_tree().current_scene = scene
	var items: Array = get_tree().get_nodes_in_group("interactable")
	var who: Node = scene.get("_charlotte")
	print("FUZZ total ", items.size())
	for i in range(from, items.size()):
		var it = items[i]
		if not is_instance_valid(it) or not it.has_method("interact"):
			continue
		var ok := true
		if it.has_method("can_interact"):
			ok = it.can_interact()
		if not ok:
			continue
		print("FUZZ ", i, " ", it.name, " ", it.get_script().resource_path if it.get_script() else "")
		it.interact(who)
		await get_tree().create_timer(0.6).timeout
		if get_tree().current_scene != scene or not is_instance_valid(scene) or not scene.is_inside_tree():
			print("NEXT=", i + 1)
			get_tree().quit()
			return
	print("END")
	get_tree().quit()
