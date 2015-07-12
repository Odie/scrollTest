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
uniform     int        inverseDiscard;

void main()
{
    vec4 color = varInColor * texture2D(uniTexture, varTexCoord);
    // optimize to one condition
//    if(inverseDiscard == 1 && color.a > 0.0) {
//        discard;
//    }
//    if(inverseDiscard == 0 && color.a == 0.0) {
//        discard;
//    }
    if(float(inverseDiscard) == ceil(color.a)) {
        discard;
    }
    gl_FragColor =  color;
}