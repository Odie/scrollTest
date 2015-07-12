#version 100
/**** Attributes ****/
// The position of the vertex being processed
attribute          vec4         inPosition;
// The color of the vertex being processes
attribute          vec4         inColor;
// Texture coordinate
attribute          vec2         inMisc;

/**** Varying ****/
#ifdef GL_ES
varying        lowp vec4        varInColor;
#else
// The color to be passed to the fragment shader
varying             vec4        varInColor;
#endif

/**** Uniforms ****/
// The projection matrix
uniform             mat4        MPMatrix;
uniform             float       sizeModifier;

/**** Program ****/
void main() {
    
    // Pass on the vertex color
    varInColor = inColor;

    // Calculate the final position of the vertex using the projection matrix
    gl_Position = MPMatrix * inPosition;
    gl_PointSize = inMisc.x * sizeModifier;
}