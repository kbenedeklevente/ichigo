shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D curl_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D double_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D sweep_art : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 bucket_center;
uniform float illumination = 1.0;
varying vec3 world_position;
varying vec4 card_data;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    card_data = INSTANCE_CUSTOM;
}

void fragment() {
    vec2 uv = UV;
    if (card_data.b > 0.5) { uv.x = 1.0 - uv.x; }
    vec4 drawing = texture(curl_art, uv);
    if (card_data.r > 0.66) { drawing = texture(sweep_art, uv); }
    else if (card_data.r > 0.33) { drawing = texture(double_art, uv); }
    // The open bucket remains dry; cards are scenery around its physical hull.
    if (distance(world_position.xz, bucket_center) < 1.18) { discard; }
    ALBEDO = drawing.rgb * illumination * mix(0.94, 1.04, card_data.g);
    ALPHA = drawing.a;
    ALPHA_SCISSOR_THRESHOLD = 0.45;
}
