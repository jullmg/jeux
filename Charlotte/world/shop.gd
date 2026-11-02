class_name Shop
extends Interior
## What the corner stores share (dépanneur Xin-Xin and Oh Bon!): the shopkeeper, plain-text labels on the art, hanging
## aisle signs, paying from her pocket money, the pint of milk for Mom's quest, a bag of chips, the real-time wall
## clock, a blinking camera light and a panel that stutters. A shop extends this and builds its own room.

var _clerk: Character


# A sign hanging by two chains from the ceiling grid, its words a label on the board.
func _hang(x: float, text: String, color: Color) -> void:
	var sc := 0.8
	_put(ShopArt.hanging_sign(color.to_html(false).insert(0, "#")), x, CEILING + 100.0 * sc - 6.0, sc)
	_wall_label(text, Vector2(x + 68.0 * sc * 1.0 - 8.0, CEILING + 100.0 * sc - 6.0 - 100.0 * sc + 67.0 * sc), 15, Color.WHITE, color.darkened(0.55), 3)

## Adds `count` customers browsing at `stops` (x of the shelves), in this season's clothes, at their own pace.
func _add_customers(count: int, stops: Array[float], seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var person := ShopCustomer.new()
		person.look = CharacterLook.random(rng, ["adult", "senior", "teen", "adult"][i % 4])
		Season.dress_for_weather(person.look)
		person.stops = stops
		person.scale = Vector2.ONE * CHAR_SCALE
		person.position = Vector2(stops[(i * 2 + 1) % stops.size()], FEET_Y - 6.0)
		person.modulate = Color(0.96, 0.95, 0.97)
		add_child(person)


## A thin wisp of steam rising from a hot drinks machine at `at`.
func _steam(at: Vector2) -> void:
	var puff := CPUParticles2D.new()
	puff.position = at
	puff.amount = 8
	puff.lifetime = 2.4
	puff.preprocess = 2.4
	puff.direction = Vector2(0.15, -1.0)
	puff.spread = 12.0
	puff.initial_velocity_min = 14.0
	puff.initial_velocity_max = 22.0
	puff.scale_amount_min = 3.0
	puff.scale_amount_max = 6.0
	puff.color = Color(1, 1, 1, 0.22)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
	puff.color_ramp = fade
	add_child(puff)


func _wall_label(text: String, center: Vector2, size: int, color: Color, outline: Color, outline_size := 5) -> void:
	var label := Label.new()
	label.text = text
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = outline_size
	settings.outline_color = outline
	label.label_settings = settings
	label.size = Vector2(300, 40)
	label.position = center - label.size / 2.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


# An advertising light-box poster (ShopArt.ad_poster) hung with its title over the strip at the top.
func _ad(kind: int, x: float, bottom: float, s := 0.8) -> void:
	_put(ShopArt.ad_poster(kind), x, bottom, s, "wall")
	var ad: Dictionary = ShopArt.AD_POSTERS[kind % ShopArt.AD_POSTERS.size()]
	_wall_label(ad.title, Vector2(x + 50.0 * s, bottom - 140.0 * s + 18.0 * s), maxi(8, int(13.0 * s)), Color(ad.ink), Color(0, 0, 0, 0.0), 0)


# She picks something and pays from her pocket money; the shopkeeper thanks her (or tells her she's short).
func _buy(picture: Texture2D, text: String, price: float) -> void:
	if GameState.money < price - 0.001:
		_say(_clerk, "Il te manque des sous ! C'est %s." % Quests.money_text(price), 250.0, 3.0)
		Sfx.play("pop")
		return
	GameState.money -= price
	_treat(picture, "%s  − %s" % [text, Quests.money_text(price)])
	_thanks("Merci, bonne journée !")


# A bag of chips: one of the classic flavours, picked at random (or the one she looked at).
func _buy_chips() -> void:
	var f := randi() % ShopArt.CHIPS.size()
	_buy(ShopArt.chip_treat(f), "%s !" % String(ShopArt.CHIPS[f].said).capitalize(), 1.75)


# The pint of milk: Mom's money pays for it while she's on the "milk" quest, and Charlotte carries it home in her arms (if
# her hands are free); otherwise it's like anything else.
func _buy_milk() -> void:
	if Quests.active("milk") and not Carry.has("milk"):
		if not Carry.take(_charlotte, "milk"):
			_say(_charlotte, Carry.FULL_HANDS, 300.0)
			return
		Sfx.play("pop", _charlotte.position)
		_say(_charlotte, "Une pinte de lait pour Maman !", 300.0)
		_thanks("Bonjour à ta maman !")
	else:
		_buy(ShopArt.milk_pint(), "Une pinte de lait !", 2.49)


func _thanks(text: String) -> void:
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _say(_clerk, text, 250.0))


# A wall clock that shows the real time.
class _Clock:
	extends Node2D

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 34.0, Color("#2B2B2B"))
		draw_circle(Vector2.ZERO, 30.0, Color("#FBFAF6"))
		for i in 12:
			var d := Vector2.from_angle(TAU * i / 12.0)
			draw_line(d * 24.0, d * 28.0, Color("#2B2B2B"), 2.0)
		var now := Time.get_time_dict_from_system()
		var minutes: float = now.minute + now.second / 60.0
		var hours: float = fmod(now.hour, 12.0) + minutes / 60.0
		draw_line(Vector2.ZERO, Vector2.from_angle(hours / 12.0 * TAU - PI / 2.0) * 15.0, Color("#2B2B2B"), 3.5, true)
		draw_line(Vector2.ZERO, Vector2.from_angle(minutes / 60.0 * TAU - PI / 2.0) * 23.0, Color("#2B2B2B"), 2.5, true)
		draw_line(Vector2.ZERO, Vector2.from_angle(now.second / 60.0 * TAU - PI / 2.0) * 25.0, Color("#E04F5F"), 1.2, true)
		draw_circle(Vector2.ZERO, 3.0, Color("#E04F5F"))


# A tiny red light that blinks, on a security camera.
class _Blink:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var on := fmod(_t, 1.6) < 0.25
		if on:
			draw_circle(Vector2.ZERO, 5.0, Color(1, 0.2, 0.2, 0.25))
			draw_circle(Vector2.ZERO, 2.0, Color(1, 0.35, 0.3))
		else:
			draw_circle(Vector2.ZERO, 1.6, Color(0.4, 0.1, 0.1))


# A tired fluorescent panel: now and then it stutters.
class _Flicker:
	extends Node
	var targets: Array = []
	var _next := 6.0
	var _left := 0.0

	func _process(delta: float) -> void:
		_next -= delta
		if _next <= 0.0 and _left <= 0.0:
			_left = 0.45
			_next = randf_range(9.0, 25.0)
		_left = maxf(_left - delta, 0.0)
		var dim := 0.25 if _left > 0.0 and int(_left * 40.0) % 3 != 0 else 1.0
		for t in targets:
			if is_instance_valid(t):
				t.modulate.a = dim

