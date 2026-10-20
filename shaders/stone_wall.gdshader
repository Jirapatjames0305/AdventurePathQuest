shader_type spatial;
// Stone blocks in running bond, laid in world space on whichever plane the
// surface faces (walls along X or Z, tops, and roughly on round towers).

uniform vec3 stone_a : source_color = vec3(0.66, 0.63, 0.58);
uniform vec3 stone_b : source_color = vec3(0.74, 0.71, 0.65);
uniform vec3 stone_c : source_color = vec3(0.58, 0.56, 0.52);
uniform vec3 mortar_color : source_color = vec3(0.46, 0.44, 0.41);
uniform float block_width = 1.3;
uniform float block_height = 0.6;
uniform float mortar = 0.05;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p;
	if (abs(world_normal.y) > 0.7) {
		p = world_pos.xz;
	} else if (abs(world_normal.x) > abs(world_normal.z)) {
		p = vec2(world_pos.z, world_pos.y);
	} else {
		p = vec2(world_pos.x, world_pos.y);
	}
	float row = floor(p.y / block_height);
	float v = fract(p.y / block_height);
	float u_raw = p.x / block_width + mod(row, 2.0) * 0.5;
	float block = floor(u_raw);
	float u = fract(u_raw);
	float joint = step(u, mortar * 0.5) + step(1.0 - mortar * 0.5, u) + step(v, mortar) + step(1.0 - mortar, v);
	float pick = hash(vec2(row, block));
	vec3 col = pick < 0.33 ? stone_a : (pick < 0.66 ? stone_b : stone_c);
	col *= 0.9 + 0.18 * hash(vec2(block + 7.0, row));
	ALBEDO = mix(col, mortar_color, clamp(joint, 0.0, 1.0));
	ROUGHNESS = 0.9;
}
