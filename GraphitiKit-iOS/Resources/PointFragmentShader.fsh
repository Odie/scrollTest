#version 100
#ifdef GL_ES
precision lowp float;
#endif

//#extension GL_EXT_shader_framebuffer_fetch : require

// Color sent in from the vertex shader
varying     vec4        varInColor;
// Texture coordinate from the vertex shader
varying     vec2        varTexCoord;

// Texture to be sampled
uniform     sampler2D   uniTexture;
uniform     int         u_opacityModifyRGB;

void main()
{
    vec4 modColor = vec4(varInColor.r * varInColor.a,
                         varInColor.g * varInColor.a,
                         varInColor.b * varInColor.a,
                         varInColor.a);
    // replace branching
    vec4 color = mix(varInColor,modColor,float(u_opacityModifyRGB==1));
    color = color * texture2D(uniTexture, gl_PointCoord);
    gl_FragColor = color;
//    gl_FragColor.rgba = color.rgba + gl_LastFragData[0].rgba;
    
//    gl_FragColor.a = max(color.a,gl_FragColor.a);
//    gl_FragColor.a = 1.0;
    
//    gl_FragColor.rgb = color.rgb * texture2D(texture, gl_PointCoord).rgb;// + gl_LastFragData[0].rgb;
//    gl_FragColor.g = min(gl_FragColor.g,0.6);
//    gl_FragColor.a = 1.0;
}