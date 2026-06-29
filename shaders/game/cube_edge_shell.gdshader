shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_prepass_alpha;

uniform float cube_half_size = 3.0;
uniform float edge_width = 0.08;
uniform vec4 edge_color : source_color = vec4(1.0, 0.82, 0.35, 1.0);
uniform vec4 shell_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float edge_emission = 2.2;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 p = clamp(local_pos / cube_half_size, vec3(-1.0), vec3(1.0));
	vec3 edge_distance = 1.0 - abs(p);
	
	float edge_xy = max(edge_distance.x, edge_distance.y);
	float edge_xz = max(edge_distance.x, edge_distance.z);
	float edge_yz = max(edge_distance.y, edge_distance.z);
	float nearest_edge = min(min(edge_xy, edge_xz), edge_yz) * cube_half_size;
	
	float edge_mask = 1.0 - smoothstep(edge_width * 0.65, edge_width, nearest_edge);
	vec3 color = mix(shell_color.rgb, edge_color.rgb, edge_mask);
	float alpha = edge_color.a * edge_mask;
	float emission_strength = edge_emission * edge_mask;
	
	ALBEDO = color;
	ALPHA = alpha;
	EMISSION = edge_color.rgb * emission_strength;
}
