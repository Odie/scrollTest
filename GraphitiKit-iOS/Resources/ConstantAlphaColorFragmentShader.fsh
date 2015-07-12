#version 100
#ifdef GL_ES
precision lowp float;
#endif

#extension GL_EXT_shader_framebuffer_fetch : require

// Color sent in from the vertex shader
varying     vec4        varInColor;
// Texture coordinate from the vertex shader
varying     vec2        varTexCoord;

uniform     int         u_opacityModifyRGB;

void main()
{
    vec4 modColor = vec4(varInColor.r * varInColor.a,
                         varInColor.g * varInColor.a,
                         varInColor.b * varInColor.a,
                         varInColor.a);
    // replace branching
    vec4 color = mix(varInColor,modColor,float(u_opacityModifyRGB==1));
    gl_FragColor.rgb = color.rgb + gl_LastFragData[0].rgb * (color.a-color.a);
    float alpha = mix(color.a,gl_LastFragData[0].a,float(color.a<=gl_LastFragData[0].a));
    gl_FragColor.a = alpha;
}