shader_type spatial;
// Straight running-bond brick paving for a square area, with a stone kerb
// around the edge. Coordinates are the mesh's local XZ (centered on 0).

uniform vec3 brick_color_a : source_color = vec3(0.62, 0.6, 0.55);
uniform vec3 brick_color_b : source_color = vec3(0.7, 0.67, 0.6);
uniform vec3 brick_color_c : source_color = vec3(0.55, 0.53, 0.5);
uniform vec3 mortar_color : source_color = vec3(0.46, 0.44, 0.4);
uniform vec3 border_color : source_color = vec3(0.45, 0.43, 0.4);
uniform float brick_length = 1.0;
uniform float brick_width = 0.5;
uniform float mortar = 0.05;
uniform float half_size = 16.0;
uniform float border_width = 0.7;

varying vec3 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 p = local_pos.xz;
	float edge = half_size - max(abs(p.x), abs(p.y));
	if (edge < border_width) {
		// Kerb stones along whichever edge we're on.
		float along = abs(p.x) > abs(p.y) ? p.y : p.x;
		float block_u = fract(along / (brick_length * 1.6));
		float joint = step(block_u, mortar * 0.6) + step(1.0 - mortar * 0.6, block_u);
		float shade = 0.9 + 0.1 * hash(vec2(floor(along / (brick_length * 1.6)), sign(p.x) + 3.0 * sign(p.y)));
		ALBEDO = mix(border_color * shade, mortar_color, clamp(joint, 0.0, 1.0));
		ROUGHNESS = 0.9;
	} else {
		float row = floor(p.y / brick_width);
		float v = fract(p.y / brick_width);
		float u_raw = p.x / brick_length + mod(row, 2.0) * 0.5;
		float brick = floor(u_raw);
		float u = fract(u_raw);
		float joint = step(u, mortar * 0.5) + step(1.0 - mortar * 0.5, u) + step(v, mortar) + step(1.0 - mortar, v);
		float pick = hash(vec2(row, brick));
		vec3 col = pick < 0.33 ? brick_color_a : (pick < 0.66 ? brick_color_b : brick_color_c);
		col *= 0.9 + 0.2 * hash(vec2(brick + 5.0, row));
		ALBEDO = mix(col, mortar_color, clamp(joint, 0.0, 1.0));
		ROUGHNESS = 0.85;
	}
}
