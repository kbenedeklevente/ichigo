shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D illustration : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D field_texture : filter_linear, repeat_disable;
uniform vec2 field_origin;
uniform float field_side = 33.0;
uniform float cell_size = 4.0;
uniform float crest_phase = 0.0;
uniform float face_rise = 0.34;
uniform float profile_travel = 0.24;
uniform vec2 bucket_center = vec2(0.0);
uniform float illumination = 1.0;
uniform float render_extent = 34.0;
varying vec3 world_position;
varying vec2 drawing_uv;
varying float drawing_weight;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 grid = clamp((world.xz - field_origin) / cell_size, vec2(0.0), vec2(field_side - 1.0));
	vec2 fields = texture(field_texture, (grid + 0.5) / field_side).rg;
	vec2 traveled = world.xz - vec2(0.0, crest_phase * profile_travel);
	vec2 owner = floor(traveled / cell_size + 0.5);
	float relief = 0.0;
	float dominant = 0.0;
	drawing_uv = vec2(0.0);
	drawing_weight = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = owner + vec2(float(x), float(y));
			float seed = mod(cell.x * 17.0 + cell.y * 31.0, 13.0) / 13.0;
			vec2 center = cell * cell_size + vec2((seed - 0.5) * 1.2, (fract(seed * 7.0) - 0.5) * 0.8);
			vec2 local = (traveled - center) * (4.0 / cell_size);
			float half_width = 2.55 + 0.35 * seed;
			float across = local.x / half_width;
			float taper = smoothstep(0.0, 0.70, 1.0 - abs(across));
			float scallop = 0.10 * cos(across * 9.42477796 + seed * 3.0);
			float along = local.y + 0.46 * across * across + scallop;
			float shoulder = 1.48 + 0.22 * seed;
			float front = 0.76 + 0.12 * seed;
			float profile = smoothstep(-shoulder, -0.16, along) * (1.0 - smoothstep(0.08, front, along));
			float rise = face_rise * (0.88 + 0.18 * seed) * taper * profile;
			relief += rise;
			// Extend illustration coordinates through buried roots. Selecting only
			// nonzero heights snapped UVs to zero and left triangular ink shards.
			float art_influence = taper * max(0.0, 1.0 - abs(along) / 2.4);
			if (art_influence > dominant) {
				dominant = art_influence;
				// Atlas V: engraved shoulder to rounded ivory lip, then pale teal front.
				float art_v = along < -0.16 ? 0.59 * (along + shoulder) / (shoulder - 0.16) : (along < 0.08 ? mix(0.59, 0.70, (along + 0.16) / 0.24) : mix(0.70, 1.0, (along - 0.08) / (front - 0.08)));
				drawing_uv = vec2(across * 0.5 + 0.5, art_v);
				drawing_weight = taper * smoothstep(0.0, 0.09, profile);
			}
		}
	}
	VERTEX.y = fields.r + relief * (1.0 + 0.18 * clamp((fields.g - 0.12) / 0.66, 0.0, 1.0));
	world_position = vec3(world.x, VERTEX.y, world.z);
}

void fragment() {
	if (length(world_position.xz - bucket_center) < 0.98) { discard; }
	vec3 ink = texture(illustration, drawing_uv).rgb;
	vec3 substrate = vec3(0.59, 0.72, 0.73);
	float edge_distance = max(abs(world_position.x - bucket_center.x), abs(world_position.z - bucket_center.y));
	float haze = smoothstep(render_extent * 0.42, render_extent * 0.94, edge_distance);
	float fiber = fract(sin(dot(floor(world_position.xz * 155.0), vec2(127.1,311.7))) * 43758.5453) - 0.5;
	vec3 color = mix(substrate, ink, clamp(drawing_weight, 0.0, 1.0)) + fiber * 0.026;
	ALBEDO = mix(color, vec3(0.76,0.80,0.75), haze) * illumination;
}
