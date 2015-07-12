//
//  Vertex.h
//  Graphiti-Prototype
//
//  Created by apple on 10/16/14.
//
//

#ifndef GraphitiKit_GKVertex_h
#define GraphitiKit_GKVertex_h

typedef struct {
    GLKVector2 vertex;
    GLKVector2 texCoord;
}  __attribute__((aligned(16))) GKTexturedVertex2;

typedef struct {
    GLKVector2 vertex;
    GLKVector2 texCoord;
    GLKVector4 color;
} __attribute__((aligned(32))) GKTexturedColoredVertex2;

typedef struct {
    GLKVector2 vertex;
    GLKVector2 misc;
    GLKVector4 color;
} __attribute__((aligned(32))) GKColoredPoint2;

typedef struct {
    GLKVector3 vertex;
    float misc;
    GLKVector4 color;
} __attribute__((aligned(32))) GKColoredPoint;

typedef struct {
    GLKVector3 vertex;
    GLKVector4 color;
    GLKVector2 texCoord;
} GKTexturedColoredVertex;

typedef struct {
    GKTexturedColoredVertex2 bl;
    GKTexturedColoredVertex2 br;
    GKTexturedColoredVertex2 tl;
    GKTexturedColoredVertex2 tr;
} __attribute__((aligned(128))) GKQuad2;

typedef struct {
    GKTexturedColoredVertex bl;
    GKTexturedColoredVertex br;
    GKTexturedColoredVertex tl;
    GKTexturedColoredVertex tr;
} GKQuad3;


// Structure used to hold particle specific information
typedef struct {
    GLKVector2 position;
    GLKVector2 direction;
    GLKVector2 startPos;
    GLKVector4 color;
    GLKVector4 deltaColor;
    GLfloat rotation;
    GLfloat rotationDelta;
    GLfloat radialAcceleration;
    GLfloat tangentialAcceleration;
    GLfloat radius;
    GLfloat radiusDelta;
    GLfloat angle;
    GLfloat degreesPerSecond;
    GLfloat particleSize;
    GLfloat particleSizeDelta;
    GLfloat timeToLive;
    GLfloat startSize;
    GLfloat finishSize;
} GKParticle2;

typedef struct {
    GLKVector3 position;
    GLKVector3 direction;
    GLKVector3 endPos;
    GLKVector4 color;
    GLKVector4 deltaColor;
    GLfloat rotation;
    GLfloat rotationDelta;
    GLfloat radialAcceleration;
    GLfloat tangentialAcceleration;
    GLfloat radius;
    GLfloat radiusDelta;
    GLfloat angle;
    GLfloat degreesPerSecond;
    GLfloat particleSize;
    GLfloat particleSizeDelta;
    GLfloat timeToLive;
    GLfloat startSize;
    GLfloat finishSize;
} GKParticle;

#endif