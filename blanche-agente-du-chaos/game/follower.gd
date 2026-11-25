class_name Follower
extends RefCounted
## Transforme une destination en commandes de déplacement (toucher/clic et robots joueurs).

var nav: Nav
var goal := Vector2.INF
var path := PackedVector2Array()
var _age := 0.0


func _init(nav_: Nav) -> void:
	nav = nav_


func clear() -> void:
	goal = Vector2.INF
	path = PackedVector2Array()


## La direction à suivre depuis `from` pour aller à `to` (zéro une fois arrivée).
func steer(dt: float, from: Vector2, to: Vector2, blockers: Array = [], arrive := 0.07) -> Vector2:
	_age += dt
	if from.distance_to(to) <= arrive:
		# Arrivée : inutile de chercher un chemin.
		goal = to
		path = PackedVector2Array()
		return Vector2.ZERO
	if goal == Vector2.INF or goal.distance_to(to) > 0.12 or _age > 0.6 or path.is_empty():
		goal = to
		path = nav.path(from, to, blockers)
		_age = 0.0
	while not path.is_empty() and from.distance_to(path[0]) <= maxf(arrive, 0.09):
		path.remove_at(0)
	if path.is_empty():
		var d := to - from
		return d.normalized() if d.length() > arrive else Vector2.ZERO
	return (path[0] - from).normalized()
