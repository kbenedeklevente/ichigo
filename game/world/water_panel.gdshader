shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D illustration : source_color, filter_linear_mipmap;
uniform vec2 bucket_center = vec2(0.0);
uniform float illumination = 1.0;
uniform float render_extent = 30.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 ink = texture(illustration, UV);
	if (ink.a < 0.5 || length(world_position.xz - bucket_center) < 0.98) { discard; }
	float edge_distance = max(abs(world_position.x - bucket_center.x), abs(world_position.z - bucket_center.y));
	float haze = smoothstep(render_extent * 0.48, render_extent * 0.94, edge_distance);
	float fiber = fract(sin(dot(floor(UV * 650.0), vec2(127.1,311.7))) * 43758.5453) - 0.5;
	vec3 color = ink.rgb + fiber * 0.035;
	ALBEDO = mix(color, vec3(0.5686,0.647,0.639), haze) * illumination;
}
