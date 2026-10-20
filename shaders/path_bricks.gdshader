shader_type spatial;
// Brick path paving in world space: straight running bond aligned to the world
// axes (same as the plaza square), so bricks stay square-cut on every segment
// and around corners. Kerbs are separate meshes (see StonePath).

uniform vec3 brick_color_a : source_color = vec3(0.72, 0.62, 0.5);
uniform vec3 brick_color_b : source_color = vec3(0.8, 0.7, 0.56);
uniform vec3 brick_color_c : source_color = vec3(0.66, 0.56, 0.46);
uniform vec3 mortar_color : source_color = vec3(0.5, 0.46, 0.4);
uniform float brick_length = 1.0;
uniform float brick_width = 0.5;
uniform float mortar = 0.05;
// 0 = bricks run along world X, 1 = along world Z.
uniform float along_z = 0.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = along_z > 0.5 ? world_pos.zx : world_pos.xz;
	float row = floor(p.y / brick_width);
	float v = fract(p.y / brick_width);
	float u_raw = p.x / brick_length + mod(row, 2.0) * 0.5;
	float brick = floor(u_raw);
	float u = fract(u_raw);
	float joint = step(u, mortar * 0.5) + step(1.0 - mortar * 0.5, u) + step(v, mortar) + step(1.0 - mortar, v);
	float pick = hash(vec2(row, brick));
	vec3 col = pick < 0.33 ? brick_color_a : (pick < 0.66 ? brick_color_b : brick_color_c);
	col *= 0.9 + 0.2 * hash(vec2(brick + 3.0, row));
	ALBEDO = mix(col, mortar_color, clamp(joint, 0.0, 1.0));
	ROUGHNESS = 0.85;
}
