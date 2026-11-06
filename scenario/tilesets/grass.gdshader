shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float noise_scale = 0.003;   // menor = manchas maiores
uniform vec3 tint_a : source_color = vec3(0.80, 1.0, 0.75);
uniform vec3 tint_b : source_color = vec3(1.0, 1.0, 0.70);
uniform float strength : hint_range(0.0, 1.0) = 0.6;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float n = texture(noise_tex, world_pos * noise_scale).r;
	n = smoothstep(0.35, 0.65, n);   // estica o contraste
	n = floor(n * 4.0) / 4.0; 
	vec3 tint = mix(tint_a, tint_b, n);
	COLOR.rgb *= mix(vec3(1.0), tint, strength);
}
