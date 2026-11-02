class_name Carry
extends RefCounted
## Everything Charlotte holds in her arms, behind ONE saved indicator: `GameState.flags.carried` = "" (hands free), or
## "<kind>" / "<kind>:<id>": "milk" (Mom's pint), "can" (the watering can), "cat:<quest id>" (a lost cat). One thing at a
## time, enforced here for every quest:
##   - `Carry.take(who, kind, id)` is the only way to put something in her arms; it refuses (returns false) when her hands
##     are not free, so the caller just says `Carry.FULL_HANDS`;
##   - `Carry.put_down(who)` empties her arms; `Carry.has(kind)` / `Carry.busy()` / `Carry.cat_id()` ask what she holds;
##   - the scenes (`Interior`, `StreetScene._build_lost_cats`) call `Carry.restore(who)` as they open, so it follows her
##     through doors and saves, with nothing for a quest to remember.
## A NEW thing to carry = one more case in `_build()` (its node and where her hands grip it) and that is all.

const KEY := "carried"
const FULL_HANDS := "J'ai déjà les mains pleines !"
## Where her hands hold the watering can, in the can's own space (its handle).
const CAN_HANDLE := Vector2(18, -33)


## What is in her arms: "cat", "milk", "can" or "".
static func what() -> String:
	return item().get_slice(":", 0)


## The saved indicator itself ("milk", "can", "cat:cat2", or "").
static func item() -> String:
	return str(GameState.flags.get(KEY, ""))


static func has(kind: String) -> bool:
	return what() == kind


static func busy() -> bool:
	return item() != ""


## The lost cat she holds (its quest id), or "".
static func cat_id() -> String:
	var parts := item().split(":")
	return parts[1] if parts.size() > 1 and parts[0] == "cat" else ""


## Puts `kind` (with its `id` for a cat) in her arms. False, and nothing changes, if her hands are not free.
static func take(who: Character, kind: String, id := "") -> bool:
	if busy():
		return false
	GameState.flags[KEY] = kind if id == "" else "%s:%s" % [kind, id]
	_hold(who)
	return true


## Empties her arms (what she held is gone: given away, put back, handed over).
static func put_down(who: Character) -> void:
	GameState.flags.erase(KEY)
	if who:
		who.carry(null)
		who.carry_grip = Vector2.ZERO


## Gives the thing back to a fresh Character (a new scene, a loaded game); does nothing if her hands are already full.
static func restore(who: Character) -> void:
	if busy() and who and not who.is_holding():
		_hold(who)


## Forgets what she holds without a Character at hand (the debug menu, a new game).
static func clear() -> void:
	GameState.flags.erase(KEY)


## Old saves kept three separate flags; fold them into the single one.
static func migrate() -> void:
	var flags: Dictionary = GameState.flags
	var old := ""
	if flags.has("carrying") and str(flags.carrying) != "":
		old = "cat:%s" % flags.carrying
	elif flags.get("has_milk", false):
		old = "milk"
	elif flags.get("has_can", false):
		old = "can"
	for key in ["carrying", "has_milk", "has_can"]:
		flags.erase(key)
	if old != "" and not flags.has(KEY):
		flags[KEY] = old


static func _hold(who: Character) -> void:
	var node := _build(what(), cat_id())
	if node == null:
		clear()
		return
	who.carry(node)
	who.carry_grip = CAN_HANDLE if what() == "can" else Vector2.ZERO


# The node for each kind of thing: add a case for a new one.
static func _build(kind: String, id: String) -> Node2D:
	match kind:
		"milk":
			return _milk()
		"can":
			var can := Sprite2D.new()
			can.texture = InteriorArt.watering_can()
			can.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			# Held up in front of her, a little bigger than it looks on the floor at the back of the kitchen.
			can.scale = Vector2.ONE * 1.5
			can.offset = Vector2(30, -4)
			can.name = "can"
			return can
		"cat":
			return LostCats.held(id)
	push_error("Carry: nothing known as '%s'" % kind)
	return null


## The pint of milk for Mom, a one-litre carton held against her chest.
static func _milk() -> Sprite2D:
	var carton := Sprite2D.new()
	carton.texture = ShopArt.milk_pint()
	carton.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	carton.scale = Vector2.ONE * 0.78
	carton.offset = Vector2(2, -4)
	carton.name = "milk"
	return carton
