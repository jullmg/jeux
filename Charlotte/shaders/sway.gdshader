shader_type canvas_item;
// Wind sway: the top of the sprite moves, the base stays planted. `gust` (0..1) is driven by Wind.

uniform float strength = 7.0;
uniform float speed = 1.1;
uniform float phase = 0.0;
uniform float gust = 0.0;

void vertex() {
	float top = 1.0 - UV.y;
	float breeze = sin(TIME * speed + phase) + 0.35 * sin(TIME * speed * 2.7 + phase * 1.7);
	float push = gust * (2.6 + 0.5 * sin(TIME * 6.0 + phase));
	VERTEX.x += (breeze + push) * strength * top * top;
}
