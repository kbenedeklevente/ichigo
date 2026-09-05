shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float simulation_time = 0.0;
uniform vec2 bucket_center = vec2(0.0);
uniform bool distant_surface = false;
varying vec3 world_position;

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	VERTEX.y = distant_surface ? 0.0 : 0.15 * sin(6.28318530718 * (world.x / 8.0 - simulation_time / 4.0));
	world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float distance_from_bucket = length(p - bucket_center);
	// The open bucket displaces water. Mask both ocean layers inside its walls.
	if (distance_from_bucket < 0.98) { discard; }
	float ribbon = p.y + 0.38 * sin(p.x * 0.65) + 0.11 * sin(p.x * 2.3);
	float band = sin(ribbon * 2.5 + 0.12 * sin(simulation_time * 0.5));
	float step_band = floor((band * 0.5 + 0.5) * 4.0) / 4.0;
	vec3 dark_ink = vec3(0.17,0.34,0.41);
	vec3 blue_paper = vec3(0.37,0.55,0.59);
	vec3 color = mix(dark_ink, blue_paper, 0.3 + step_band * 0.6);
	float edge = smoothstep(0.91,0.98,band) * (1.0-smoothstep(0.98,1.0,band));
	color += vec3(0.14,0.16,0.14) * edge * 0.36;
	float fiber = grain(floor(p * 130.0)) - 0.5;
	color += fiber * 0.028;
	float haze = smoothstep(12.0,52.0,distance_from_bucket);
	color = mix(color, vec3(0.5686,0.647,0.639), haze);
	if (distant_surface) { color = vec3(0.5686,0.647,0.639); }
	ALBEDO = color;
}
