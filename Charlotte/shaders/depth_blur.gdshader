shader_type canvas_item;
// Out of focus: a blurred copy of what has been drawn so far (the sky and far skyline, or a cross street's vista),
// laid over it. With `vp` set (screen uv of a vanishing point), only round it: the further, the softer.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float lod = 1.4;
uniform vec2 vp = vec2(-1.0, -1.0);
uniform float radius = 0.16;
uniform float aspect = 1.7778;

void fragment() {
	vec3 blurred = textureLod(screen_tex, SCREEN_UV, lod).rgb;
	float w = 1.0;
	if (vp.x >= 0.0) {
		vec2 d = (SCREEN_UV - vp) * vec2(aspect, 1.0);
		w = 1.0 - smoothstep(radius * 0.25, radius, length(d));
	}
	COLOR = vec4(blurred, w);
}
