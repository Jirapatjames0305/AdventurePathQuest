shader_type spatial;
// Fountain water: deep-to-light blue by radius with ripples rippling outward.

uniform vec3 deep_color : source_color = vec3(0.12, 0.38, 0.62);
uniform vec3 shallow_color : source_color = vec3(0.35, 0.7, 0.88);
uniform float radius = 2.6;
uniform float ripple_speed = 1.2;
uniform float ripple_density = 5.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float r = length(local_pos.xz);
	float t = clamp(r / radius, 0.0, 1.0);
	float ripple = sin(r * ripple_density * TAU / radius - TIME * ripple_speed * TAU);
	ALBEDO = mix(deep_color, shallow_color, t * 0.6 + ripple * 0.08 + 0.2);
	vec2 dir = r > 0.001 ? local_pos.xz / r : vec2(0.0);
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(dir.x, 0.0, dir.y, 0.0)).xyz * ripple * 0.12);
	ROUGHNESS = 0.08;
	METALLIC = 0.15;
	SPECULAR = 0.7;
}
