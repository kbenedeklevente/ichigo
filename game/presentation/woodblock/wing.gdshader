shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D illustration : source_color, filter_linear_mipmap;
uniform vec2 player_position;
uniform float illumination = 1.0;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec4 ink = texture(illustration, UV);
    // Opaque cutouts: no alpha-scissor sorting, no rectangular transparent shadows.
    if (ink.a < 0.48) { discard; }
    // Scallop the physical ends like hand-cut scenic wings, within the overlap.
    float cut_edge = 0.025 + 0.018 * sin(UV.y * 8.0) + 0.006 * sin(UV.y * 27.0);
    if (UV.x < cut_edge || UV.x > 1.0 - cut_edge) { discard; }
    float distance_back = max(0.0, player_position.y - world_position.z);
    float middle = smoothstep(5.0, 35.0, distance_back);
    float mist = smoothstep(32.0, 90.0, distance_back);
    vec3 azure = mix(ink.rgb, vec3(0.49, 0.69, 0.74), 0.53);
    vec3 color = mix(ink.rgb, azure, middle);
    color = mix(color, vec3(0.89, 0.87, 0.75), mist * 0.88);
    ALBEDO = color * illumination;
    ROUGHNESS = 1.0;
}
