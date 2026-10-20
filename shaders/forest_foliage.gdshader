shader_type spatial;
// Forest trees (MultiMesh): flat colour or per-instance sRGB colour, and a
// see-through hole round the hero — fragments between the camera and
// `focus_point` are dithered away so the hero never disappears behind a tree.

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_instance_color = false;
uniform vec3 focus_point = vec3(0.0, -1000.0, 0.0);
uniform float clear_radius = 2.8;

varying vec3 world_pos;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

vec3 srgb_to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo.rgb;
	if (use_instance_color) {
		base *= srgb_to_linear(COLOR.rgb);
	}
	ALBEDO = base;
	ROUGHNESS = 0.9;
	// Works for the orthographic camera: the view axis through the hero.
	vec3 to_camera = normalize(INV_VIEW_MATRIX[2].xyz);
	vec3 offset = world_pos - focus_point;
	float ahead = dot(offset, to_camera);
	if (ahead > 0.6) {
		float side = length(offset - to_camera * ahead);
		float fade = 1.0 - smoothstep(clear_radius * 0.55, clear_radius, side);
		ivec2 cell = ivec2(FRAGCOORD.xy) % 4;
		if (fade * 0.85 > (BAYER[cell.y * 4 + cell.x] + 0.5) / 16.0) {
			discard;
		}
	}
}
