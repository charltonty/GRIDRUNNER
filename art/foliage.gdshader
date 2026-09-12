shader_type spatial;
render_mode cull_disabled;
void fragment() {
    vec2 p=UV*2.0-1.0;
    float mask=1.0-smoothstep(0.72,0.9,length(p*vec2(0.8,1.0)));
    mask*=1.0-smoothstep(0.82,0.95,abs(p.x)+0.2*sin(p.y*22.0));
    ALPHA=mask;
    ALPHA_SCISSOR_THRESHOLD=0.5;
    ALBEDO=pow(COLOR.rgb,vec3(2.2))*(0.65+0.25*(1.0-abs(p.y)));
    ROUGHNESS=1.0;
    SPECULAR=0.08;
    BACKLIGHT=vec3(0.035,0.045,0.02);
}
