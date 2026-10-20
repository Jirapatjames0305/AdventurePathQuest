shader_type spatial;
// Brick paving laid in concentric rings around the node's origin (a plaza
// around a fountain). Bricks get per-brick colour variation and mortar joints.

uniform vec3 brick_color_a : source_color = vec3(0.48, 0.27, 0.2);
uniform vec3 brick_color_b : source_color = vec3(0.58, 0.36, 0.27);
uniform vec3 brick_color_c : source_color = vec3(0.44, 0.31, 0.25);
uniform vec3 mortar_color : source_color = vec3(0.6, 0.56, 0.5);
uniform vec3 border_color : source_color = vec3(0.5, 0.48, 0.45);
uniform float brick_length = 0.9;
uniform float ring_width = 0.45;
uniform float mortar = 0.05;
uniform float inner_radius = 3.4;
uniform float outer_radius = 10.0;
uniform float border_width = 0.6;

varying vec3 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 p = local_pos.xz;
	float r = length(p);
	if (r > outer_radius - border_width || r < inner_radius + border_width) {
		// Stone kerb at the inner and outer edges, cut into blocks.
		float angle = atan(p.y, p.x) / TAU + 0.5;
		float blocks = floor(TAU * r / (brick_length * 1.6));
		float block_u = fract(angle * blocks);
		float joint = step(block_u, mortar * 0.6) + step(1.0 - mortar * 0.6, block_u);
		float shade = 0.9 + 0.1 * hash(vec2(floor(angle * blocks), step(r, inner_radius + border_width)));
		ALBEDO = mix(border_color * shade, mortar_color * 0.8, clamp(joint, 0.0, 1.0));
		ROUGHNESS = 0.9;
	} else {
		float ring = floor(r / ring_width);
		float ring_v = fract(r / ring_width);
		float ring_radius = (ring + 0.5) * ring_width;
		float count = max(6.0, floor(TAU * ring_radius / brick_length));
		float angle = atan(p.y, p.x) / TAU + 0.5;
		// Offset every other ring by half a brick (running bond).
		float u = angle * count + mod(ring, 2.0) * 0.5;
		float brick = floor(u);
		float brick_u = fract(u);
		float joint_u = step(brick_u, mortar * 0.5) + step(1.0 - mortar * 0.5, brick_u);
		float joint_v = step(ring_v, mortar) + step(1.0 - mortar, ring_v);
		float pick = hash(vec2(ring, brick));
		vec3 brick_col = pick < 0.33 ? brick_color_a : (pick < 0.66 ? brick_color_b : brick_color_c);
		brick_col *= 0.88 + 0.24 * hash(vec2(brick, ring + 17.0));
		ALBEDO = mix(brick_col, mortar_color, clamp(joint_u + joint_v, 0.0, 1.0));
		ROUGHNESS = 0.85;
	}
}
