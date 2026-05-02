shader_type canvas_item;

uniform vec2 car_pos = vec2(0.5, 0.5);
uniform float radius = 0.25;
uniform float edge_softness = 0.08;

void fragment() {
    float dist = distance(UV, car_pos);
    float alpha = smoothstep(radius - edge_softness, radius + edge_softness, dist) * 0.88;
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
