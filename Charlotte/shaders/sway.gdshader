shader_type canvas_item;
// Wind sway: the top of the sprite moves, the base stays planted.

uniform float strength = 7.0;
uniform float speed = 1.1;
uniform float phase = 0.0;

void vertex() {
	float top = 1.0 - UV.y;
	float gust = sin(TIME * speed + phase) + 0.35 * sin(TIME * speed * 2.7 + phase * 1.7);
	VERTEX.x += gust * strength * top * top;
}
