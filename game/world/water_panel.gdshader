shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D curl_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D double_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D sweep_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D ribbon_art : source_color, filter_linear_mipmap, repeat_disable;
// Fixed logical field: RGBA = spring height, amplitude, wind strength, clouds.
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
    float sky = profile_coordinate(field.a, vec4(0.12, 0.65, 0.88, 1.0));
    float height_scale = mix(height_range.x, height_range.y, clamp((wind + sky) / 6.0, 0.0, 1.0));
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
        // Match Godot's YXZ Euler order and the existing world-Y art scale.
        vertex = rotate_y((seed_value - 0.5) * 0.12) * rotate_x(-0.18 + tilt.x * 0.45) * rotate_z(tilt.y * 0.6) * vertex;
        vertex.y *= mix(0.70, 0.85, seed_value) * height_scale;
        offset = vec3(stagger, -1.65 * ratio * height_scale, (seed_value - 0.5) * 0.36 * ratio);
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
    if (card_data.a < 0.5) { drawing = texture(ribbon_art, uv); }
    // The open bucket remains dry; cards are scenery around its physical hull.
    if (distance(world_position.xz, bucket_center) < 1.18) { discard; }
    ALBEDO = drawing.rgb * illumination * mix(0.94, 1.04, card_data.g);
    ALPHA = drawing.a;
    ALPHA_SCISSOR_THRESHOLD = 0.45;
}
