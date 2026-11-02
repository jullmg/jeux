extends Node2D
# Catalogue of every shop object (ShopArt), twelve to a page, to judge their drawing:
# Godot --path . --screen 1 res://tools/shop_objects.tscn -- --screenshot=/tmp/shop.png [--page=0]

const OBJECTS := [
	["door"], ["counter"], ["candy_wall"], ["drinks_fridge"], ["freezer"], ["newspaper_rack"], ["halloween_display"], ["lotto_poster"],
	["ad_poster", 0], ["ad_poster", 1], ["ad_poster", 2], ["ad_poster", 3], ["ad_poster", 4], ["chips_gondola"], ["chip_treat", 0], ["clip_strip"],
	["back_shelves"], ["gondola"], ["milk_cooler"], ["slush_machine"], ["coffee_station"], ["bread_rack"], ["atm"], ["security_mirror"],
	["specials_board"], ["back_door"], ["treat", "chips"], ["milk_pint"], ["high_shelf", 1], ["hanging_sign"], ["exit_sign"], ["wet_floor_sign"],
	["camera_dome"], ["fire_extinguisher"], ["bulletin_board"], ["baskets_stack"], ["modern_counter"], ["tidy_back_shelves"], ["shopping_cart"], ["old_register"],
	["spinner_rack"], ["produce_crates"], ["flower_bucket"], ["gumball_machine"], ["box_stack", 1], ["pallet_cases"], ["hand_truck"], ["mop_bucket"],
	["broom"], ["step_ladder"], ["a_frame_sign"], ["open_sign"], ["trash_can"], ["newspaper_pile"], ["vending_machine"], ["egg_tray"],
	["water_cooler"], ["toy_rack"], ["salt_bag"], ["tin_pyramid"], ["cctv_monitor"], ["floor_junk", 1],
]
const PER_PAGE := 12
const COLS := 4


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color("#EDE6D8")
	back.size = Vector2(1280, 720)
	add_child(back)
	var page := int(_arg("--page=", "0"))
	var cell := Vector2(320.0, 240.0)
	for k in PER_PAGE:
		var i := page * PER_PAGE + k
		if i >= OBJECTS.size():
			break
		var entry: Array = OBJECTS[i]
		var tex: Texture2D = Callable(ShopArt, entry[0]).callv(entry.slice(1))
		var origin := Vector2((k % COLS) * cell.x, (k / COLS) * cell.y)
		var s := minf(1.0, minf((cell.x - 30.0) / tex.get_width(), (cell.y - 50.0) / tex.get_height()))
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		sprite.scale = Vector2.ONE * s
		sprite.position = origin + Vector2((cell.x - tex.get_width() * s) / 2.0, 14.0 + (cell.y - 50.0 - tex.get_height() * s) / 2.0)
		add_child(sprite)
		var label := Label.new()
		label.text = "%d  %s" % [i, " ".join(entry.map(func(x): return str(x)))]
		label.position = origin + Vector2(10, cell.y - 30.0)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color("#3A3A48"))
		add_child(label)
	var shot := _arg("--screenshot=", "")
	if shot != "":
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot)
		get_tree().quit()


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
