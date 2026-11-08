class_name Stash
extends RefCounted
## Charlotte's hiding place for junk food: a shoebox pushed under her bed, in her room. Everything sweet or salty
## ends up in it — the whole Halloween haul once Maman has counted it, and the candy, lollipops and bags of chips
## she buys at the dépanneur. Kept in `GameState.flags.stash` as {kind: how many}, the kinds being `Halloween.KINDS`,
## so one drawing (`CandyIcon`) serves the count sheet and the box alike.

const FLAG := "stash"
## What she says when she pulls the box out and there is nothing left in it.
const EMPTY := "Ma cachette est vide !\nFaudrait ben que je passe au dépanneur."


## Everything hidden in the box: {kind: how many}. Kinds with none left are not in it.
static func all() -> Dictionary:
	return GameState.flags.get(FLAG, {})


static func total() -> int:
	var box := all()
	var n := 0
	for kind: String in box:
		n += int(box[kind])
	return n


## Hides `n` more of `kind` (one of `Halloween.KINDS`) in the box.
static func add(kind: String, n := 1) -> void:
	if n <= 0 or not Halloween.KINDS.has(kind):
		return
	var box: Dictionary = all().duplicate()
	box[kind] = int(box.get(kind, 0)) + n
	GameState.flags[FLAG] = box


## Takes one out to eat it. False when there is none of that kind left.
static func take(kind: String) -> bool:
	var box: Dictionary = all().duplicate()
	var left := int(box.get(kind, 0)) - 1
	if left < 0:
		return false
	if left == 0:
		box.erase(kind)
	else:
		box[kind] = left
	GameState.flags[FLAG] = box
	return true


## The Halloween bag goes into the box in one go, once Maman has counted it on the kitchen table.
static func from_halloween() -> void:
	var counted := Halloween.counted()
	for kind: String in Halloween.KINDS:
		add(kind, int(counted.get(kind, 0)))
