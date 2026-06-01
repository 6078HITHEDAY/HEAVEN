// 创建新着色器文件: cube_flow.gdshader

shader_type spatial;

// 可调参数
uniform vec4 base_color : source_color = vec4(0.2, 0.3, 0.8, 1.0);  // 基础颜色
uniform vec4 flow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);   // 流光颜色
uniform float speed = 1.5;            // 流光速度
uniform float flow_width = 0.3;       // 流光宽度
uniform float glow_intensity = 2.0;   // 发光强度

void fragment() {
    // 计算边缘距离（从立方体中心到边缘）
    vec2 uv = abs(UV * 2.0 - 1.0);
    float edge_dist = max(uv.x, uv.y);

    // 创建动态流光效果
    float flow = sin(edge_dist * 10.0 - TIME * speed);
    float glow = smoothstep(1.0 - flow_width, 1.0, flow);

    // 混合基础色和流光色
    vec3 final_color = mix(base_color.rgb, flow_color.rgb, glow);

    // 应用颜色和发光
    ALBEDO = final_color;
    EMISSION = final_color * glow * glow_intensity;

    // 增强反射效果
    METALLIC = 0.2;
    ROUGHNESS = 0.7;
}