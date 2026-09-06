shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D curl_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D double_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D sweep_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D ribbon_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D storm_curl_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D storm_double_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D storm_sweep_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D foam_art : source_color, filter_linear_mipmap, repeat_disable;
uniform int breaker_count = 0;
uniform vec4 breaker_state[3]; // anchor XZ, height gain, collapse lean
uniform vec4 splash_state[3]; // center XZ, spread, opacity
uniform vec2 breaker_direction[3];
varying float storm_art_mix;
// Fixed logical field: RGBA = spring height, amplitude, wind strength, sky strength (0–4).
// Explicit four-texel interpolation also works when float linear filtering is
// unavailable on a compatibility backend.
uniform sampler2D weather_fields : filter_nearest, repeat_disable;
uniform vec2 field_origin;
uniform float field_side = 33.0;
uniform float logical_cell_size = 4.0;
uniform float visual_spacing = 4.0;
uniform float visual_center_offset = 0.0;
uniform float vertical_motion_scale = 2.0;
uniform vec2 height_range = vec2(0.5, 2.0);
uniform vec2 crest_height_range = vec2(0.35, 2.0);
uniform float crest_curve_shape = 9.0;
uniform float extreme_wind_strength = 12.0;
uniform vec2 bucket_center;
uniform float illumination = 1.0;
varying vec3 world_position;
varying vec4 card_data;

float profile_coordinate(float value, vec4 anchors) {
    if (value <= anchors.y) { return clamp((value - anchors.x) / (anchors.y - anchors.x), 0.0, 1.0); }
    if (value <= anchors.z) { return 1.0 + clamp((value - anchors.y) / (anchors.z - anchors.y), 0.0, 1.0); }
    return 2.0 + clamp((value - anchors.z) / (anchors.w - anchors.z), 0.0, 1.0);
}

mat3 rotate_x(float a) {
    return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(a), sin(a)), vec3(0.0, -sin(a), cos(a)));
}
mat3 rotate_y(float a) {
    return mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a)));
}
mat3 rotate_z(float a) {
    return mat3(vec3(cos(a), sin(a), 0.0), vec3(-sin(a), cos(a), 0.0), vec3(0.0, 0.0, 1.0));
}

void vertex() {
    card_data = INSTANCE_CUSTOM;
    vec2 anchor = MODEL_MATRIX[3].xz;
    vec2 grid = clamp((anchor - field_origin) / logical_cell_size, vec2(0.0), vec2(field_side - 1.0));
    vec2 cell = min(floor(grid), vec2(field_side - 2.0));
    vec2 f = grid - cell;
    vec4 a = textureLod(weather_fields, (cell + vec2(0.5)) / field_side, 0.0);
    vec4 b = textureLod(weather_fields, (cell + vec2(1.5, 0.5)) / field_side, 0.0);
    vec4 c = textureLod(weather_fields, (cell + vec2(0.5, 1.5)) / field_side, 0.0);
    vec4 d = textureLod(weather_fields, (cell + vec2(1.5)) / field_side, 0.0);
    vec4 field = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    float dx = mix(b.r - a.r, d.r - c.r, f.y) / logical_cell_size;
    float dz = mix(c.r - a.r, d.r - b.r, f.x) / logical_cell_size;
    vec2 tilt = vec2(atan(-dz), atan(dx));
    float wind = profile_coordinate(field.b, vec4(0.12, 1.8, 5.0, 9.0));
    if (field.b > 9.0) { wind = 3.0 + clamp((field.b - 9.0) / (extreme_wind_strength - 9.0), 0.0, 1.0); }
    float sky = clamp(field.a, 0.0, 4.0);
    float height_scale = mix(height_range.x, height_range.y, clamp((min(wind, 3.0) + min(sky, 3.0)) / 6.0, 0.0, 1.0));
    storm_art_mix = smoothstep(11.85, 11.97, field.b) * smoothstep(3.95, 3.99, field.a);
    float seed_value = card_data.g;
    // Density affects only the reclining lower-water panels. Curling crests
    // keep original size, spacing and seed identity at every slider value.
    float spacing = card_data.a > 0.5 ? logical_cell_size : visual_spacing;
    float center_offset = card_data.a > 0.5 ? 0.0 : visual_center_offset;
    float ratio = spacing / 4.0;
    float row = round((anchor.y - center_offset) / spacing);
    float stagger = mod(row, 2.0) < 0.5 ? spacing * 0.5 : 0.0;
    vec3 vertex = VERTEX * ratio;
    vec3 offset;
    if (card_data.a > 0.5) {
        // Reversed normalized logarithm: low longer, steeper near maximum.
        // Five levels per axis means coordinates 0..4, combined maximum 8.
        float strength = clamp((wind + sky) / 8.0, 0.0, 1.0);
        float curve = 1.0 - log(1.0 + crest_curve_shape * (1.0 - strength)) / log(1.0 + crest_curve_shape);
        height_scale = mix(crest_height_range.x, crest_height_range.y, curve);
        float lean = 0.0;
        vec2 crash_direction = vec2(0.0);
        for (int i = 0; i < 3; i++) {
            if (i < breaker_count && distance(anchor, breaker_state[i].xy) < 0.1) {
                height_scale *= breaker_state[i].z;
                lean = breaker_state[i].w;
                crash_direction = breaker_direction[i];
            }
        }
        // Match Godot's YXZ Euler order and the existing world-Y art scale.
        vertex = rotate_y((seed_value - 0.5) * 0.12) * rotate_x(-0.18 + tilt.x * 0.45) * rotate_z(tilt.y * 0.6) * vertex;
        vertex.y *= mix(0.70, 0.85, seed_value) * height_scale;
        // The extended storm drawing has a submerged rectangular foundation.
        // Lift its crown modestly, blending with the art and collapsing with it.
        float root_depth = mix(1.65, 1.35, storm_art_mix);
        offset = vec3(stagger, -root_depth * ratio * height_scale, (seed_value - 0.5) * 0.36 * ratio);
        // The exposed lip pitches forward; the submerged root stays anchored.
        vertex.xz += crash_direction * max(vertex.y + offset.y, 0.0) * lean * 1.8;
    } else {
        vertex *= vec3(1.18, 1.65, 1.0);
        vertex = rotate_x(-1.15 + tilt.x * 0.2) * rotate_z(tilt.y * 0.2) * vertex;
        vertex.y *= height_scale;
        offset = vec3(stagger - ratio, -2.25 * ratio * height_scale, 4.0 * ratio);
    }
    VERTEX = vertex + offset + vec3(0.0, field.r * vertical_motion_scale, 0.0);
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = UV;
    if (card_data.b > 0.5) { uv.x = 1.0 - uv.x; }
    vec4 drawing = texture(curl_art, uv);
    if (card_data.r > 0.66) { drawing = texture(sweep_art, uv); }
    else if (card_data.r > 0.33) { drawing = texture(double_art, uv); }
    if (card_data.a > 0.5 && storm_art_mix > 0.0) {
        vec4 storm = texture(storm_curl_art, uv);
        if (card_data.r > 0.66) { storm = texture(storm_sweep_art, uv); }
        else if (card_data.r > 0.33) { storm = texture(storm_double_art, uv); }
        // The selected generated sprite has a baked pale neutral backdrop.
        // Key it in the material while preserving chromatic ivory foam/blue ink.
        // Keep the original PNG unchanged; ordinary SVGs never use this key.
        float brightest = max(storm.r, max(storm.g, storm.b));
        float darkest = min(storm.r, min(storm.g, storm.b));
        float saturation = (brightest - darkest) / max(brightest, 0.001);
        float ink = 1.0 - smoothstep(0.75, 0.88, darkest);
        storm.a *= max(ink, smoothstep(0.020, 0.029, saturation));
        drawing = mix(drawing, storm, storm_art_mix);
    }
    if (card_data.a < 0.5) {
        drawing = texture(ribbon_art, uv);
        float coverage = 0.0;
        for (int i = 0; i < 3; i++) {
            if (i < breaker_count && splash_state[i].w > 0.0) {
                vec2 direction = breaker_direction[i];
                vec2 delta = world_position.xz - splash_state[i].xy;
                vec2 local = vec2(dot(delta, vec2(-direction.y, direction.x)), dot(delta, direction));
                vec2 q = local / (vec2(4.0, 6.0) * splash_state[i].z);
                float ragged = 0.06 * sin(local.x * 2.4 + local.y * 1.7) + 0.04 * sin(local.y * 4.1);
                coverage = max(coverage, (1.0 - smoothstep(0.65, 1.0, length(q) + ragged)) * splash_state[i].w);
            }
        }
        if (coverage > 0.001) {
            // Sample world-space rings on the deformed lower cards, not upright
            // crests. No extra mesh, opaque duplicate surface, or particles.
            float pitch = max(0.25, visual_spacing);
            vec2 tile = floor(world_position.xz / pitch);
            float seed = fract(sin(dot(tile, vec2(127.1, 311.7))) * 43758.5453);
            vec2 ring_uv = fract(world_position.xz / pitch) - 0.5;
            float angle = seed * 6.283185;
            ring_uv = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * ring_uv;
            ring_uv /= mix(0.68, 0.94, seed);
            ring_uv += 0.5;
            vec4 foam = texture(foam_art, clamp(ring_uv, vec2(0.0), vec2(1.0)));
            float ring = foam.a;
            float sparse = smoothstep(seed * 0.65, seed * 0.65 + 0.25, coverage);
            drawing.rgb = mix(drawing.rgb, foam.rgb, ring * coverage * sparse);
        }
    }
    // The open bucket remains dry; cards are scenery around its physical hull.
    if (distance(world_position.xz, bucket_center) < 1.18) { discard; }
    ALBEDO = drawing.rgb * illumination * mix(0.94, 1.04, card_data.g);
    ALPHA = drawing.a;
    ALPHA_SCISSOR_THRESHOLD = 0.45;
}
