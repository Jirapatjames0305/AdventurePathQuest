shader_type spatial;
// Brick path along a ribbon mesh: UV.x runs 0..1 across the path,
// UV.y is the distance along it in world units. Stone kerbs on both edges.

uniform vec3 brick_color_a : source_color = vec3(0.72, 0.62, 0.5);
uniform vec3 brick_color_b : source_color = vec3(0.8, 0.7, 0.56);
uniform vec3 brick_color_c : source_color = vec3(0.66, 0.56, 0.46);
uniform vec3 mortar_color : source_color = vec3(0.5, 0.46, 0.4);
uniform vec3 kerb_color : source_color = vec3(0.52, 0.5, 0.47);
uniform float width = 4.0;
uniform float brick_length = 0.9;
uniform float brick_width = 0.45;
uniform float mortar = 0.05;
uniform float kerb_width = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float across = UV.x * width;
	float along = UV.y;
	if (across < kerb_width || across > width - kerb_width) {
		float block = floor(along / 1.4);
		float u = fract(along / 1.4);
		float joint = step(u, 0.03) + step(0.97, u);
		ALBEDO = mix(kerb_color * (0.9 + 0.1 * hash(vec2(block, step(across, kerb_width)))), mortar_color, clamp(joint, 0.0, 1.0));
		ROUGHNESS = 0.9;
	} else {
		// Bricks laid across the path, rows advancing along it (running bond).
		float row = floor(along / brick_width);
		float v = fract(along / brick_width);
		float u_raw = (across - kerb_width) / brick_length + mod(row, 2.0) * 0.5;
		float brick = floor(u_raw);
		float u = fract(u_raw);
		float joint = step(u, mortar * 0.5) + step(1.0 - mortar * 0.5, u) + step(v, mortar) + step(1.0 - mortar, v);
		float pick = hash(vec2(row, brick));
		vec3 col = pick < 0.33 ? brick_color_a : (pick < 0.66 ? brick_color_b : brick_color_c);
		col *= 0.9 + 0.2 * hash(vec2(brick + 3.0, row));
		ALBEDO = mix(col, mortar_color, clamp(joint, 0.0, 1.0));
		ROUGHNESS = 0.85;
	}
}
