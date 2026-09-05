shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D illustration : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D field_texture : filter_linear, repeat_disable;
uniform vec2 field_origin;
uniform float field_side = 33.0;
uniform float cell_size = 4.0;
uniform float crest_phase = 0.0;
uniform float face_rise = 0.56;
uniform float profile_travel = 0.38;
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
			vec2 center = cell * cell_size + vec2((seed - 0.5) * 1.5, (fract(seed * 7.0) - 0.5) * 1.05);
			vec2 local = (traveled - center) * (4.0 / cell_size);
			float half_width = 2.15 + 0.30 * seed;
			float across = local.x / half_width;
			float taper = 1.0 - smoothstep(0.48, 1.0, abs(across));
			float curl = 0.48 * sin(across * 3.2 + seed * 2.0) + 0.20 * across;
			float along = local.y + curl;
			float shoulder = 1.36 + 0.16 * seed;
			float front = 0.23 + 0.04 * seed;
			float profile = smoothstep(-shoulder, -0.08, along) * (1.0 - smoothstep(0.0, front, along));
			float crown = 0.70 + 0.30 * pow(0.5 + 0.5 * sin(across * 4.0 + seed * 4.0), 2.0);
			float echo = smoothstep(-1.85, -1.52, along) * (1.0 - smoothstep(-1.45, -1.12, along));
			float rise = face_rise * (0.92 + 0.16 * seed) * taper * (crown * profile + 0.20 * echo);
			relief += rise;
			// Extend illustration coordinates through buried roots. Selecting only
			// nonzero heights snapped UVs to zero and left triangular ink shards.
			float art_influence = taper * max(0.0, 1.0 - abs(along) / 2.4);
			if (art_influence > dominant) {
				dominant = art_influence;
				// Atlas V: broader upper shoulder, narrow lip, dark descending face.
				float art_v = along < -0.08 ? 0.66 * (along + shoulder) / (shoulder - 0.08) : (along < 0.0 ? mix(0.66, 0.69, (along + 0.08) / 0.08) : mix(0.69, 1.0, along / front));
				drawing_uv = vec2(across * 0.5 + 0.5, art_v);
				drawing_weight = taper * smoothstep(0.0, 0.06, max(profile, echo));
			}
		}
	}
	VERTEX.y = fields.r + relief * (1.0 + 0.18 * clamp((fields.g - 0.12) / 0.66, 0.0, 1.0));
	world_position = vec3(world.x, VERTEX.y, world.z);
}

void fragment() {
	if (length(world_position.xz - bucket_center) < 0.98) { discard; }
	vec3 ink = texture(illustration, drawing_uv).rgb;
	// Long carved tide lines connect the individual raised ribbons into one sea.
	float flow = world_position.z + 0.42 * sin(world_position.x * 0.48) + 0.18 * sin(world_position.x * 1.27 + world_position.z * 0.30);
	float cut = abs(sin(flow * 11.0));
	float line = 1.0 - smoothstep(0.05, 0.19 + fwidth(flow) * 8.0, cut);
	float current = smoothstep(-0.4, 0.7, sin(flow * 1.1));
	vec3 substrate = mix(vec3(0.018, 0.145, 0.25), vec3(0.035, 0.24, 0.36), current);
	substrate = mix(substrate, vec3(0.43, 0.61, 0.66), line * 0.23);
	float edge_distance = max(abs(world_position.x - bucket_center.x), abs(world_position.z - bucket_center.y));
	float haze = smoothstep(render_extent * 0.50, render_extent * 0.98, edge_distance);
	float fiber = fract(sin(dot(floor(world_position.xz * 155.0), vec2(127.1,311.7))) * 43758.5453) - 0.5;
	vec3 color = mix(substrate, ink, clamp(drawing_weight, 0.0, 1.0)) + fiber * 0.012;
	ALBEDO = mix(color, vec3(0.18,0.34,0.43), haze) * illumination;
}
