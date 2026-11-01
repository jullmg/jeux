shader_type canvas_item;
// Soft shading on a paper-cutout character's parts: lit by the low sun on the upper left (a warm highlight), turning
// into shade on the right. `facing` keeps the light on the same side when the puppet is mirrored.

uniform float facing = 1.0;
uniform float shade = 0.18;
uniform float highlight = 0.1;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float x = facing > 0.0 ? UV.x : 1.0 - UV.x;
	float dark = smoothstep(0.4, 1.0, x) * shade;
	float lit = (1.0 - smoothstep(0.0, 0.4, x)) * (1.0 - smoothstep(0.0, 0.6, UV.y)) * highlight;
	c.rgb = c.rgb * (1.0 - dark) + vec3(1.0, 0.93, 0.8) * lit * c.a;
	COLOR = c;
}
