shader_type canvas_item;
// Final grade: warm autumn afternoon light, sun bloom and rays, warm shadows, soft vignette, film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 sun_uv = vec2(0.12, 0.1);
uniform vec3 tint = vec3(1.05, 0.99, 0.9);
uniform float saturation = 1.1;
uniform float contrast = 0.12;
uniform float vignette = 0.5;
uniform float bloom = 0.16;
uniform float rays = 0.035;
uniform vec3 shadow_tint = vec3(0.07, 0.025, 0.0);
uniform float grain = 0.03;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c *= tint;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = mix(c, c * c * (3.0 - 2.0 * c), contrast);
	c += shadow_tint * (1.0 - smoothstep(0.0, 0.55, l));

	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 d = (SCREEN_UV - sun_uv) * aspect;
	float dist = length(d);
	vec3 sun = vec3(1.0, 0.78, 0.48);
	c += sun * bloom * exp(-dist * 3.2);
	float ang = atan(d.y, d.x);
	float beams = pow(max(sin(ang * 7.0 + TIME * 0.05), 0.0), 3.0) + 0.6 * pow(max(sin(ang * 11.0 - TIME * 0.03 + 1.3), 0.0), 4.0);
	c += sun * rays * beams * smoothstep(1.2, 0.15, dist) * smoothstep(-0.05, 0.15, d.y);

	vec2 v = SCREEN_UV - 0.5;
	c *= 1.0 - dot(v, v) * vignette * 1.6;
	float n = fract(sin(dot(FRAGCOORD.xy + fract(TIME * 7.0) * 113.0, vec2(12.9898, 78.233))) * 43758.5453);
	c += (n - 0.5) * grain;
	COLOR = vec4(c, 1.0);
}
