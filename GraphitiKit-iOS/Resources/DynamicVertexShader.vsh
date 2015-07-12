#version 100
/**** Attributes ****/
// The position of the vertex being processed
attribute          vec4         inPosition;
// The color of the vertex being processes
attribute          vec4         inColor;
// Texture coordinate
attribute          vec2         inTexCoord;

/**** Varying ****/
#ifdef GL_ES
varying        lowp vec4        varInColor;
// Texture coordinate to the fragment shader
varying     mediump vec2        varTexCoord;
varying     mediump vec2        varPos;
#else
// The color to be passed to the fragment shader
varying             vec4        varInColor;
// Texture coordinate to the fragment shader
varying             vec2        varTexCoord;
varying             vec2        varPos;
#endif

/**** Uniforms ****/
// The projection matrix
uniform             mat4        MPMatrix;
//uniform             vec4        uniColor;
//uniform             int         useColor;

/**** Program ****/
void main() {
    // Pass on the vertex color
//    varInColor = mix(inColor,uniColor,float(useColor==1));
    varInColor = inColor;

    // Pass on the texture coordinate
    varTexCoord = inTexCoord;
    // Calculate the final position of the vertex using the projection matrix
    gl_Position = MPMatrix * inPosition;
    varPos = inPosition.xy;
}