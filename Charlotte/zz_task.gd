extends Node

func _ready() -> void:
	var house: Node = load("res://scenes/house.tscn").instantiate()
	get_tree().root.add_child.call_deferred(house)
	_later.call_deferred(house)

func _later(house: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var who := "mom"
	var idx := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--who="): who = a.substr(6)
		if a.begins_with("--task="): idx = int(a.substr(7))
	var r: FamilyRoutine = house._mom_routine if who == "mom" else house._dad_routine
	var t: Dictionary = r.tasks[idx]
	r.tasks = [t]
	r.who.position.x = t.x
	r._pick()
	print("TASK ", who, " ", idx, " ", t.task, " x=", t.x)
