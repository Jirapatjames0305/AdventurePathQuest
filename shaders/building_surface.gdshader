shader_type spatial;
// Detailed surfaces for town buildings, laid in world space so any mesh shape
// (box, prism roof, cone) gets consistent detail without UVs.
// mode 0 = plaster (mottled, grime near the ground)
// mode 1 = stone blocks (running bond)
// mode 2 = roof tiles (overlapping rows with rounded lower edges)
// mode 3 = timber (wood grain)

uniform int mode = 0;
uniform vec3 base_color : source_color = vec3(0.9, 0.85, 0.75);

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.5 + noise(p * 2.1) * 0.3 + noise(p * 4.3) * 0.2;
}

// Coordinates on the face: x along the surface, y up (or z for flat tops).
vec2 face_coords() {
	if (abs(world_normal.y) > 0.85) {
		return world_pos.xz;
	}
	vec2 n = normalize(world_normal.xz);
	float along = dot(world_pos.xz, vec2(-n.y, n.x));
	return vec2(along, world_pos.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = face_coords();
	vec3 col = base_color;
	float rough = 0.9;
	if (mode == 0) {
		// Plaster: soft mottling, faint vertical streaks, grime at the base.
		float mottle = fbm(p * 1.3);
		float streak = noise(vec2(p.x * 6.0, p.y * 0.4));
		col *= 0.93 + 0.1 * mottle - 0.03 * streak;
		col *= mix(0.78, 1.0, smoothstep(0.0, 1.1, world_pos.y));
	} else if (mode == 1) {
		// Stone blocks in running bond with mortar joints.
		vec2 size = vec2(0.9, 0.45);
		float row = floor(p.y / size.y);
		float u_raw = p.x / size.x + mod(row, 2.0) * 0.5;
		float block = floor(u_raw);
		float u = fract(u_raw);
		float v = fract(p.y / size.y);
		float joint = step(u, 0.04) + step(0.96, u) + step(v, 0.07) + step(0.93, v);
		col *= 0.86 + 0.24 * hash(vec2(block, row));
		col *= 0.95 + 0.1 * fbm(p * 3.0);
		col = mix(col, base_color * 0.62, clamp(joint, 0.0, 1.0));
	} else if (mode == 2) {
		// Roof tiles: rows stepping up the slope; each tile's lower edge is
		// rounded and shadowed, giving overlapping scallops.
		vec2 size = vec2(0.42, 0.3);
		float row = floor(p.y / size.y);
		float u_raw = p.x / size.x + mod(row, 2.0) * 0.5;
		float tile = floor(u_raw);
		float u = fract(u_raw) - 0.5;
		float v = fract(p.y / size.y);
		float edge = 0.18 * (1.0 - 4.0 * u * u);
		float shadow = 1.0 - smoothstep(edge - 0.02, edge + 0.12, v);
		col *= 0.84 + 0.28 * hash(vec2(tile, row));
		col *= 1.0 - 0.38 * shadow;
		col *= 1.0 - 0.25 * step(0.46, abs(u));
		rough = 0.7;
	} else {
		// Timber: long grain streaks with darker knots.
		float grain = noise(vec2(p.x * 1.5, p.y * 18.0) + vec2(fbm(p * 2.0) * 3.0, 0.0));
		col *= 0.82 + 0.3 * grain;
		col *= 1.0 - 0.25 * smoothstep(0.82, 0.95, noise(p * 4.0));
	}
	ALBEDO = col;
	ROUGHNESS = rough;
}
