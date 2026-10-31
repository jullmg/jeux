extends SceneTree
# Cuts the white page out of art/logo.jpg -> art/logo.png: Godot --headless --path . --script res://tools/cutout_logo.gd
# Flood-fills from the borders, so the sticker's own white outline stays opaque.

const SRC := "res://art/logo.jpg"
const DST := "res://art/logo.png"
const WIDTH := 1400
const WHITE := 232


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.resize(WIDTH, int(img.get_height() * float(WIDTH) / img.get_width()), Image.INTERPOLATE_LANCZOS)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var bg := PackedByteArray()
	bg.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if bg[i] == 1 or mini(data[i * 4], mini(data[i * 4 + 1], data[i * 4 + 2])) < WHITE:
			continue
		bg[i] = 1
		var x := i % w
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if i >= w: stack.append(i - w)
		if i < w * (h - 1): stack.append(i + w)
	for i in w * h:
		if bg[i] == 1:
			data[i * 4 + 3] = 0
			continue
		var x := i % w
		var edge := (x > 0 and bg[i - 1] == 1) or (x < w - 1 and bg[i + 1] == 1) \
			or (i >= w and bg[i - w] == 1) or (i < w * (h - 1) and bg[i + w] == 1)
		if not edge:
			continue
		# Anti-aliased rim: turn the leftover white blend into transparency.
		var lo := mini(data[i * 4], mini(data[i * 4 + 1], data[i * 4 + 2]))
		var a := clampf((255.0 - lo) / (255.0 - 120.0), 0.0, 1.0)
		data[i * 4 + 3] = int(a * 255.0)
		if a > 0.01:
			for c in 3:
				data[i * 4 + c] = clampi(int((data[i * 4 + c] - 255.0 * (1.0 - a)) / a), 0, 255)
	var out := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	out.save_png(ProjectSettings.globalize_path(DST))
	print("logo cut out: %dx%d" % [w, h])
	quit()
