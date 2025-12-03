// referenced / modified https://godotshaders.com/shader/rain-and-snow-with-parallax-scrolling-effect
shader_type canvas_item;

//render_mode unshaded;

instance uniform float time_offset = 0.0;
instance uniform float drop_count = 250.0;
instance uniform float slant = 0.2;
instance uniform float rain_len = 0.08;
instance uniform float rain_speed = 0.5;
instance uniform float rain_width = 0.2;

void vertex() {
	VERTEX.x += VERTEX.y * slant;
}

void fragment() {
	vec2 uv = vec2(0.0);
	uv.x = UV.x;//(UV.x - UV.y * slant);
	float remainder = mod(uv.x, 1.0 / drop_count);
	uv.x -= remainder;
	float offset = sin(uv.x * drop_count);
	uv.y = UV.y + offset;
	float time = TIME + time_offset;
	
	COLOR.a *= mix(1.0, 0.2, UV.y) * smoothstep(1.0 - (rain_len), 1.0, fract(uv.y - time * (rain_speed))) * step(remainder * drop_count, rain_width);
}
