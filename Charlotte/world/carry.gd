class_name Carry
extends RefCounted
## What Charlotte holds in her arms. Only one thing at a time: a lost cat (`GameState.flags.carrying`), Mom's pint of milk
## (`flags.has_milk`) or the watering can (`flags.has_can`). Anything that would put something else in her arms first asks
## `Carry.busy()`, and says `Carry.FULL_HANDS` if she is already holding something. The flags are saved, and each scene puts
## the thing back in her arms when it opens (`Interior`, `StreetScene._build_lost_cats`, the house for the can).
##
## A new quest that puts something in her arms: (1) keep a flag for it in `GameState.flags` and add it to `what()` here;
## (2) before handing it over, `if Carry.busy(): say Carry.FULL_HANDS; return`; (3) restore it when a scene opens, next to the
## milk; (4) clear the flag and `carry(null)` when she puts it down. `Character.carry()` itself refuses a second thing as a
## last resort (a warning in the console).

const FULL_HANDS := "J'ai déjà les mains pleines !"


## "cat", "milk", "can" or "" (her hands are free).
static func what() -> String:
	if LostCats.carrying() != "":
		return "cat"
	if GameState.flags.get("has_milk", false):
		return "milk"
	if GameState.flags.get("has_can", false):
		return "can"
	return ""


static func busy() -> bool:
	return what() != ""


## The pint of milk for Mom, a one-litre carton held against her chest; its name is a plain label on the blue band.
static func milk() -> Sprite2D:
	var carton := Sprite2D.new()
	carton.texture = ShopArt.milk_pint()
	carton.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	carton.scale = Vector2.ONE * 0.78
	carton.offset = Vector2(2, -4)
	var name := Label.new()
	name.text = "Québon"
	name.add_theme_font_size_override("font_size", 19)
	name.add_theme_color_override("font_color", Color.WHITE)
	name.add_theme_color_override("font_outline_color", Color("#1D5E96"))
	name.add_theme_constant_override("outline_size", 3)
	name.size = Vector2(72, 26)
	name.position = Vector2(-34, 6)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carton.add_child(name)
	return carton
