shader_type canvas_item;
render_mode unshaded;

// Applied to the battle's root CanvasGroup: everything drawn in the world is "printed".
// 1. Every colour is re-inked with one of the three blocks the print was cut for: warm hues
//    take vermilion, cool hues take indigo, neutrals take sumi. Darker sources print darker,
//    so any legacy FX colour reads as ink on the paper floor below the group.
// 2. No translucency, as in a real print: alpha becomes ink coverage through a world-anchored
//    paper-grain threshold, so washes and faint lines print as dry, broken ink.
// 3. A sumi keyline is cut around every solid colour block, offset by a pixel or two:
//    the misregistration of a hand-printed woodblock.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec3 sumi : source_color = vec3(0.118, 0.106, 0.094);
uniform vec3 vermilion : source_color = vec3(0.847, 0.271, 0.169);
uniform vec3 indigo : source_color = vec3(0.153, 0.275, 0.420);
uniform sampler2D grain_tex : repeat_enable, filter_nearest;
uniform vec2 grain_origin = vec2(0.0);  // canvas transform origin, set every frame by the battle
uniform float grain_cell = 1.5;         // screen pixels per grain texel
uniform float grain_soft = 0.08;
uniform vec2 key_offset = vec2(1.5, 1.5);
uniform float key_width = 1.5;
uniform float key_strength = 0.75;

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 to_pigment(vec3 rgb) {
	vec3 hsv = rgb2hsv(rgb);
	float warm = max(1.0 - smoothstep(0.13, 0.20, hsv.x), smoothstep(0.80, 0.86, hsv.x));
	vec3 block = mix(indigo, vermilion, warm);
	vec3 pigment = mix(sumi, block, smoothstep(0.15, 0.55, hsv.z));
	vec3 neutral = mix(rgb, sumi, smoothstep(0.40, 0.90, hsv.z));
	return mix(neutral, pigment, smoothstep(0.10, 0.26, hsv.y));
}

// Only solid blocks get a keyline; washes and thin translucent lines stay clean.
float solid_at(vec2 uv) {
	return smoothstep(0.82, 0.96, textureLod(screen_texture, uv, 0.0).a);
}

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	c.rgb = to_pigment(c.rgb);
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 world_px = SCREEN_UV / px - grain_origin;
	// Keep the threshold band inside (0, 1) so bare paper (alpha 0) never prints a speck.
	float g = mix(grain_soft + 0.02, 1.0 - grain_soft, texture(grain_tex, world_px / (256.0 * grain_cell)).r);
	c.a = smoothstep(g - grain_soft, g + grain_soft, c.a * 1.06);
	vec2 kuv = SCREEN_UV - key_offset * px;
	float centre = solid_at(kuv);
	float ring = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		ring = max(ring, solid_at(kuv + vec2(cos(a), sin(a)) * key_width * px));
	}
	float key_a = clamp(ring - centre, 0.0, 1.0) * key_strength;
	float out_a = key_a + c.a * (1.0 - key_a);
	vec3 out_rgb = (sumi * key_a + c.rgb * c.a * (1.0 - key_a)) / max(out_a, 0.0001);
	COLOR = vec4(out_rgb, out_a);
}
