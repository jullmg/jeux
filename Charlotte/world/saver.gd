class_name Saver
extends Node
## Saves the game while Charlotte is in a scene: shortly after it opens, every few seconds, when she leaves it, and
## when the window closes. Add one to each playable scene with `who` = Charlotte.

const EVERY := 10.0

var who: Node2D
var _scene := ""


func _ready() -> void:
	_scene = get_parent().scene_file_path
	var timer := Timer.new()
	timer.wait_time = EVERY
	timer.autostart = true
	timer.timeout.connect(save)
	add_child(timer)
	get_tree().create_timer(1.0).timeout.connect(save)


func save() -> void:
	if is_instance_valid(who):
		GameState.save_game(_scene, who.position.x)


func _exit_tree() -> void:
	save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
