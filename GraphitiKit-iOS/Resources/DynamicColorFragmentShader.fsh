#version 100
#ifdef GL_ES
precision mediump float;
#endif

// Color sent in from the vertex shader
varying     vec4        varInColor;
// Texture coordinate from the vertex shader
varying     vec2        varTexCoord;
varying     vec2        varPos;
uniform     int         u_opacityModifyRGB;
uniform     int         createDash;

void main()
{
    vec4 modColor = vec4(varInColor.r * varInColor.a,
                         varInColor.g * varInColor.a,
                         varInColor.b * varInColor.a,
                         varInColor.a);
    vec4 color = mix(varInColor,modColor,float(u_opacityModifyRGB==1));
    gl_FragColor = color;
    vec2 pos = vec2((varPos.x+1.0)/2.0*1000.0,(varPos.y+1.0)/2.0*1000.0);
    vec2 uv = vec2(floor(pos.x/30.0),floor(pos.y/30.0));
    vec4 color2 = vec4(vec3(mod(uv.x + uv.y, 2.0)), 0);
    gl_FragColor = mix(color,color2,float(createDash==1));
}