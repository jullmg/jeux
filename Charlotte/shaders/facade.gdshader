shader_type canvas_item;
// Weathering for the flat vector facades: a fine paper grain, soft mottling of the colour (bricks and paint are never
// even), and grime gathering in streaks at the foot of the walls. `seed` makes each building wear differently.

uniform float seed = 0.0;
uniform float grain = 0.05;
uniform float mottle = 0.08;
uniform float grime = 0.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float g = hash(floor(px * 0.5) + seed) - 0.5;
	float m = (noise(px * 0.018 + seed) - 0.5) + (noise(px * 0.07 + seed * 3.1) - 0.5) * 0.5;
	c.rgb *= 1.0 + g * grain + m * mottle;
	float foot = smoothstep(0.74, 1.0, UV.y);
	float streak = noise(vec2(px.x * 0.06, px.y * 0.004) + seed * 1.7);
	c.rgb *= 1.0 - grime * foot * (0.5 + streak);
	COLOR = c;
}
