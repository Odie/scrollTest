#version 100
#ifdef GL_ES
precision lowp float;
#endif

// Color sent in from the vertex shader
varying     vec4        varInColor;
// Texture coordinate from the vertex shader
varying     vec2        varTexCoord;

// Texture to be sampled
uniform     sampler2D   uniTexture;
uniform     int         u_opacityModifyRGB;
uniform     float       visibilityModifier;

void main()
{
    vec4 modColor = vec4(varInColor.r * varInColor.a,
                         varInColor.g * varInColor.a,
                         varInColor.b * varInColor.a,
                         varInColor.a);
    // replace branching
    vec4 color = mix(varInColor,modColor,float(u_opacityModifyRGB==1));
//    color = color * texture2D(uniTexture, varTexCoord);
//    color.a = 0.5;
    gl_FragColor = color * texture2D(uniTexture, varTexCoord) * (1.0-visibilityModifier);
}