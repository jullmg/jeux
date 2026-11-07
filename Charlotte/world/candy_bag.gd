class_name CandyBag
extends Sprite2D
## The bag a child carries round on Halloween night, hanging from the hand and swinging as they walk. There are
## several sorts (`KINDS`, drawn by `HalloweenArt.bag_texture`): the orange pumpkin pail, the plastic sack, a
## pillowcase off the bed, a cat tote, a little cauldron, a spider-web tote, a ghost bag and a monster bag.
## `CandyBag.give(child)` hangs one on anybody: it becomes their child node, so it follows them everywhere and is
## drawn over them. Charlotte keeps hers for the evening (`GameState.flags.candy_bag_kind`).

const KINDS := ["citrouille", "sac", "taie", "chat", "chaudron", "toile", "fantome", "monstre"]
## The handle of every bag canvas, which is the point the hand holds.
const HANDLE := Vector2(48, 6)
## How big a bag is in the character's own units.
const SIZE := 0.86

var who: Character
var _t := 0.0


## Hangs a bag on `child` (a random sort when `kind` is empty) and gives it back.
static func give(child: Character, kind := "") -> CandyBag:
	var bag := CandyBag.new()
	bag.who = child
	bag.texture = HalloweenArt.bag_texture(kind if KINDS.has(kind) else KINDS[randi() % KINDS.size()])
	bag.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bag.centered = false
	bag.offset = -HANDLE
	bag._t = randf() * TAU
	child.add_child(bag)
	# A hand round the handle, not hanging open.
	child.hand_mode = "grip"
	return bag


## The bag Charlotte carries all evening: picked once, then kept with the game.
static func charlotte_kind() -> String:
	var kept := str(GameState.flags.get("candy_bag_kind", ""))
	if not KINDS.has(kept):
		kept = KINDS[randi() % KINDS.size()]
		GameState.flags["candy_bag_kind"] = kept
	return kept


func _process(delta: float) -> void:
	if not is_instance_valid(who):
		queue_free()
		return
	_t += delta
	# It hangs from the hand that walks, so it swings by itself; a little more when they run.
	position = who.to_local(who.hand_position())
	scale = Vector2(float(who.facing), 1.0) * SIZE
	rotation = sin(_t * 2.6) * 0.07 * float(who.facing)
