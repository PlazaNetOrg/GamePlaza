shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(0.05, 0.05, 0.09); // Nearly black
uniform vec3 blob_color : source_color = vec3(0.10, 0.15, 0.25); // Soft cool gray/blue
uniform float blob_strength : hint_range(0.0, 1.0) = 0.8;
uniform float time_speed : hint_range(0.0, 10.0) = 1.5;

float blob(vec2 uv, vec2 center, float size, float softness) {
    float d = length(uv - center);
    return exp(-pow(d * size, softness));
}

void fragment() {
    vec2 uv = UV;
    vec3 color = base_color.rgb;

    float t = TIME * time_speed;
    float b1 = blob(uv, vec2(0.3 + sin(t * 0.2) * 0.1, 0.4 + cos(t * 0.3) * 0.1), 4.0, 2.0);
    float b2 = blob(uv, vec2(0.7 + cos(t * 0.15) * 0.1, 0.6 + sin(t * 0.25) * 0.1), 5.0, 2.2);
    float b3 = blob(uv, vec2(0.5 + sin(t * 0.1) * 0.15, 0.3 + cos(t * 0.12) * 0.1), 6.0, 2.5);
    float blobs = (b1 + b2 + b3) * blob_strength;

    color = mix(color, blob_color.rgb, blobs);
    COLOR = vec4(color, 1.0);
}
