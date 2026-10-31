class_name CharacterLook
extends Resource

const AGES: Array[String] = ["child", "teen", "adult", "senior"]
const SKINS: Array[String] = ["#F9DCC8", "#F3CDB0", "#E8B892", "#D29A6E", "#B57A4E", "#8E5A36", "#6A4026"]
const HAIRS: Array[String] = ["#B0623A", "#3A2618", "#5A3A22", "#1E1612", "#C9A060", "#E3C78A", "#8A3B1E", "#2B2B2B"]
const GREYS: Array[String] = ["#D9D6D0", "#BDB8B0", "#F2F0EC", "#A8A39A"]
const EYES: Array[String] = ["#8A5530", "#4A6FA5", "#5E8A4A", "#3A2618", "#6B4E2E"]
const CLOTHES: Array[String] = [
	"#FFD23F", "#E04F5F", "#4A6FA5", "#1FB5C4", "#7E57C2", "#FF8A3D", "#3E8E5A",
	"#F4F1EA", "#2E3440", "#C2185B", "#8D6E63", "#5C6BC0", "#A5D6A7", "#FFB3C7",
]
const PANTS: Array[String] = ["#4A6FA5", "#2F3E5C", "#3A3A3A", "#8D6E63", "#5E6B3A", "#2B2B2B", "#6D4C41"]
const SHOES: Array[String] = ["#E04F5F", "#2B2B2B", "#F4F1EA", "#4A6FA5", "#8D6E63", "#FF5D8F", "#3E8E5A"]
const CHILD_HAIR: Array[String] = ["long_wavy", "ponytail", "bun", "curly", "bob", "short", "long_straight", "buzz"]
const ADULT_HAIR: Array[String] = ["short", "bob", "bun", "curly", "long_straight", "ponytail", "buzz", "bald"]

@export var age := "child"
@export var build := 1.0
@export var skin := Color("#F9DCC8")
@export var hair_style := "long_wavy"
@export var hair_color := Color("#B0623A")
@export var eye_color := Color("#8A5530")
@export var lashes := true
@export var mouth := "open_smile"
@export var freckles := false
@export var glasses := ""
@export var facial_hair := ""
@export var outfit := "dress"
@export var outfit_color := Color("#FFD23F")
@export var accent_color := Color("#FF5D8F")
@export var pattern := "dots"
@export var sleeve := "puff"
@export var legwear := "socks"
@export var legwear_color := Color("#FFFFFF")
@export var shoes := "mary_jane"
@export var shoe_color := Color("#FF5D8F")
@export var hat := ""
@export var hat_color := Color("#2B2B2B")
@export var scarf := ""
@export var backpack := ""
# Exact hex colours that win over the derived palette (used to keep Charlotte pixel-identical).
@export var overrides := {}

## What Charlotte chose in her wardrobe; kept between runs.
const OUTFIT_PATH := "user://charlotte_outfit.tres"
static var _outfit: CharacterLook


## Charlotte as she is dressed right now (her usual yellow dress unless she changed in her room).
static func charlotte() -> CharacterLook:
	if _outfit == null and ResourceLoader.exists(OUTFIT_PATH):
		_outfit = ResourceLoader.load(OUTFIT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as CharacterLook
	if _outfit:
		return _outfit.duplicate(true)
	return usual()


## Keeps the outfit for every scene, and on disk.
static func dress_charlotte(look: CharacterLook) -> void:
	_outfit = look.duplicate(true)
	ResourceSaver.save(_outfit, OUTFIT_PATH)


## Her usual look: the yellow polka-dot dress.
static func usual() -> CharacterLook:
	var look := CharacterLook.new()
	look.overrides = {
		"skin_line": "#D9A88E", "skin_shade": "#F2C7AE", "neck": "#EDC3AC", "blush": "#F5A3A0", "nose": "#D9947A",
		"hair_line": "#8A4527", "hair_light": "#E3A06A", "hair_mid": "#C97A4A",
		"iris_dark": "#5A3318",
		"cloth_shade": "#f51c52", "cloth_line": "#C99410", "cloth_fold": "#EDB61A",
		"accent_line": "#D63E72", "accent_light": "#FF7BA3",
		"shoe_line": "#D63E72", "shoe_light": "#FF9DBB",
	}
	return look


static func random(rng: RandomNumberGenerator, age_group := "") -> CharacterLook:
	var look := CharacterLook.new()
	look.age = age_group if age_group != "" else _pick(rng, AGES)
	var grown := look.age != "child"
	look.build = rng.randf_range(0.92, 1.14)
	look.skin = Color(_pick(rng, SKINS))
	look.eye_color = Color(_pick(rng, EYES))
	look.hair_style = _pick(rng, ADULT_HAIR if grown else CHILD_HAIR)
	look.hair_color = Color(_pick(rng, GREYS if look.age == "senior" else HAIRS))
	look.lashes = rng.randf() < 0.55
	look.mouth = "open_smile" if rng.randf() < 0.5 else "smile"
	look.freckles = rng.randf() < 0.2
	if rng.randf() < (0.45 if look.age == "senior" else 0.2):
		look.glasses = _pick(rng, ["#2B2B2B", "#8A4B2A", "#C0392B", "#4A6FA5"])
	# A beard or mustache only for a masculine look (no lashes, short hair); the draws are made either way so
	# everyone else on the street stays the same.
	if grown and look.age != "teen" and rng.randf() < 0.3:
		var whiskers := _pick(rng, ["beard", "mustache"])
		if not look.lashes and look.hair_style in ["short", "buzz", "bald", "curly"]:
			look.facial_hair = whiskers
	look.outfit = _pick(rng, ["dress", "tshirt", "sweater"] if not grown else ["dress", "tshirt", "sweater", "coat", "coat"])
	if look.outfit == "dress":
		look.facial_hair = ""
		if look.hair_style in ["bald", "buzz"]:
			look.hair_style = "bob"
	look.outfit_color = Color(_pick(rng, CLOTHES))
	look.accent_color = Color(_pick(rng, CLOTHES))
	if look.accent_color.is_equal_approx(look.outfit_color):
		look.accent_color = Color.WHITE
	match look.outfit:
		"dress":
			look.pattern = _pick(rng, ["dots", "flowers", "none"])
			look.sleeve = _pick(rng, ["puff", "short", "long"])
			look.legwear = _pick(rng, ["socks", "tights", "tights"])
		"tshirt":
			look.pattern = _pick(rng, ["stripes", "heart", "star", "none"])
			look.sleeve = "short"
			look.legwear = "pants"
		"sweater":
			look.pattern = _pick(rng, ["zigzag", "stripes", "none"])
			look.sleeve = "long"
			look.legwear = "pants"
		"coat":
			look.pattern = "none"
			look.sleeve = "long"
			look.legwear = "pants" if rng.randf() < 0.7 else "tights"
	look.legwear_color = Color(_pick(rng, PANTS)) if look.legwear != "socks" else Color.WHITE
	look.shoes = _pick(rng, ["sneaker", "boot", "mary_jane"] if look.outfit == "dress" else ["sneaker", "boot"])
	look.shoe_color = Color(_pick(rng, SHOES))
	if rng.randf() < 0.3:
		look.hat = "tuque"
		look.hat_color = Color(_pick(rng, CLOTHES))
	elif rng.randf() < 0.12:
		look.hat = "cap"
		look.hat_color = Color(_pick(rng, CLOTHES))
	if look.age == "child" and rng.randf() < 0.35:
		look.hat = _pick(rng, ["witch", "cat_ears"])
		look.hat_color = Color("#2B2B2B") if look.hat == "cat_ears" else Color(_pick(rng, ["#2B2B2B", "#5B2A86"]))
	if rng.randf() < 0.3:
		look.scarf = _pick(rng, CLOTHES)
	if look.age in ["child", "teen"] and rng.randf() < 0.45:
		look.backpack = _pick(rng, CLOTHES)
	return look


static func _pick(rng: RandomNumberGenerator, items: Array) -> String:
	return items[rng.randi_range(0, items.size() - 1)]
