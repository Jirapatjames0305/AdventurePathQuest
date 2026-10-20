shader_type spatial;
// Cobblestone road surface: irregular stones (Voronoi cells) laid in world
// space so every road matches at junctions, with sunken mortar joints and a
// gutter of darker flat slabs along both edges.
// UV.x runs 0..1 across the road (set by StonePath); `width` is in metres.

uniform vec3 stone_a : source_color = vec3(0.63, 0.59, 0.53);
uniform vec3 stone_b : source_color = vec3(0.71, 0.67, 0.6);
uniform vec3 stone_c : source_color = vec3(0.56, 0.53, 0.48);
uniform vec3 mortar_color : source_color = vec3(0.4, 0.38, 0.34);
uniform vec3 gutter_color : source_color = vec3(0.5, 0.48, 0.45);
uniform float cell_size = 0.55;
uniform float mortar = 0.06;
uniform float width = 4.0;
uniform float gutter = 0.35;

varying vec3 world_pos;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float hash1(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float across = UV.x * width;
	float to_edge = min(across, width - across);
	if (to_edge < gutter) {
		// Gutter: flat slabs along the road edge.
		float slab = floor(dot(world_pos.xz, vec2(1.0)) / 0.8);
		float joint = step(fract(dot(world_pos.xz, vec2(1.0)) / 0.8), 0.05);
		ALBEDO = mix(gutter_color * (0.92 + 0.12 * hash1(vec2(slab, 3.0))), mortar_color, joint);
		ROUGHNESS = 0.9;
	} else {
		vec2 p = world_pos.xz / cell_size;
		vec2 cell = floor(p);
		vec2 f = fract(p);
		float d1 = 8.0;
		float d2 = 8.0;
		vec2 nearest = vec2(0.0);
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 neighbour = vec2(float(x), float(y));
				vec2 point = neighbour + 0.15 + 0.7 * hash2(cell + neighbour);
				float d = length(point - f);
				if (d < d1) {
					d2 = d1;
					d1 = d;
					nearest = cell + neighbour;
				} else if (d < d2) {
					d2 = d;
				}
			}
		}
		float edge = d2 - d1;
		float pick = hash1(nearest);
		vec3 col = pick < 0.33 ? stone_a : (pick < 0.66 ? stone_b : stone_c);
		col *= 0.88 + 0.2 * hash1(nearest + 5.0);
		// Rounded stones: darker toward their edges, mortar in the joints.
		col *= mix(0.78, 1.0, smoothstep(0.0, 0.35, edge));
		ALBEDO = mix(mortar_color, col, smoothstep(mortar, mortar + 0.04, edge));
		ROUGHNESS = 0.85;
	}
}
