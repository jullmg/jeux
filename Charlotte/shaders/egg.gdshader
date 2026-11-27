shader_type canvas_item;
// An Easter egg seen from the front (ui/egg_studio.gd): its rect holds an egg, narrower at the top; each pixel is found on the
// egg's surface (longitude turned by `turn`, latitude) and takes its colour from `surf`, a 2:1 map of the whole shell. Lit from
// the upper left like the rest of the game; `wax` shines a little, `glitter` twinkles, `wet` is the gloss of a fresh dye bath.

uniform sampler2D surf : source_color, filter_linear, repeat_enable;
uniform sampler2D wax : filter_linear, repeat_enable;
uniform sampler2D glitter : source_color, filter_linear, repeat_enable;
uniform float turn = 0.0;
uniform float wet = 0.0;
uniform float time = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float k = 0.88 + 0.12 * p.y;
	float xs = p.x / k;
	float r2 = xs * xs + p.y * p.y;
	if (r2 > 1.0) {
		discard;
	}
	float z = sqrt(max(1.0 - r2, 0.0));
	float lon = atan(xs, z) + turn;
	float lat = asin(clamp(p.y, -1.0, 1.0));
	vec2 st = vec2(lon / TAU, lat / PI + 0.5);
	vec3 base = texture(surf, st).rgb;
	float w = texture(wax, st).a;
	vec4 gl = texture(glitter, st);
	vec3 n = normalize(vec3(xs * 0.9, p.y, z));
	vec3 L = normalize(vec3(-0.55, -0.55, 0.65));
	float diff = max(dot(n, L), 0.0);
	vec3 col = base * (0.44 + 0.66 * diff);
	// Light bouncing up from the table on the lower half.
	col += base * 0.1 * max(n.y, 0.0);
	vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
	float sp = pow(max(dot(n, H), 0.0), 28.0);
	col += vec3(1.0) * sp * (0.16 + 0.5 * wet + 0.3 * w);
	// Wax lines catch the light along their edges.
	col = mix(col, col + vec3(0.06), w * 0.5);
	float tw = 0.3 + 0.7 * pow(0.5 + 0.5 * sin(time * 5.0 + st.x * 157.0 + st.y * 91.0), 3.0);
	col = mix(col, gl.rgb * (0.75 + 0.55 * tw) + vec3(sp * tw), gl.a * 0.92);
	float edge = smoothstep(1.0, 0.965, r2);
	COLOR = vec4(col, edge);
}
