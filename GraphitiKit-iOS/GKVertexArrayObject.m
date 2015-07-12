//
//  GKVertexArrayObject.m
//  Pods
//
//  Created by apple on 2/6/15.
//
//

#import "GKVertexArrayObject.h"
#import "GKVertex.h"
#import <OpenGLES/ES2/glext.h>

@interface GKVertexArrayObject () 
@property (nonatomic) GLuint vaoName;
@property (nonatomic) GLuint vertexBufferName;
@property (nonatomic) GLuint indexBufferName;
@end

@implementation GKVertexArrayObject

- (void) tearDown {
    if(_vaoName) {
        glDeleteVertexArraysOES(1, &_vaoName);
        _vaoName = 0;
    }
    if(_vertexBufferName) {
        glDeleteBuffers(1, &_vertexBufferName);
        _vertexBufferName = 0;
    }
    if(_indexBufferName) {
        glDeleteBuffers(1, &_indexBufferName);
        _indexBufferName = 0;
    }
}

+ (void) releaseStaticResources {
    [[self vertexArrayObjects] enumerateKeysAndObjectsUsingBlock:^(id key, GKVertexArrayObject *obj, BOOL *stop) {
        [obj tearDown];
    }];
    [[self vertexArrayObjects] removeAllObjects];
}

+ (NSMutableDictionary *) vertexArrayObjects {
    static NSMutableDictionary *__vaoMaps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __vaoMaps = [NSMutableDictionary dictionary];
    });
    return __vaoMaps;
}

+ (GKVertexArrayObject *) textureVAOWithName:(NSString *)name vaoBlock:(void(^)())block {
    GKVertexArrayObject *vaoObject = [self vertexArrayObjects][name];
    if(!vaoObject) {
        vaoObject = [GKVertexArrayObject new];
        [self vertexArrayObjects][name] = vaoObject;
    }
    GLuint vaoName = vaoObject.vaoName;
    if(!vaoName) {
        GLushort indices[6] = {0,1,2,2,3,0};
        GKTexturedColoredVertex vertices[4] = {
            (GKTexturedColoredVertex){{1,-1,0},
                {1, 1, 1, 1}, {1,0}},
            (GKTexturedColoredVertex){{1,1,0},
                {1, 1, 1, 1}, {1,1}},
            (GKTexturedColoredVertex){{-1,1,0},
                {1, 1, 1, 1}, {0,1}},
            (GKTexturedColoredVertex){{-1,-1,0},
                {1, 1, 1, 1}, {0,0}},
        };
        
        GLuint vertexBuffer;
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GKTexturedColoredVertex)*4, vertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER,0);
        
        GLuint indexBuffer;
        glGenBuffers(1, &indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort)*6, indices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        glGenVertexArraysOES(1, &vaoName);
        glBindVertexArrayOES(vaoName);
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        
        if(block) {
            block();
        }
        
        glBindBuffer(GL_ARRAY_BUFFER,0);
        glBindVertexArrayOES(0);
        
        vaoObject.vaoName = vaoName;
        vaoObject.indexBufferName = indexBuffer;
        vaoObject.vertexBufferName = vertexBuffer;
    }
    return vaoObject;
}

+ (GKVertexArrayObject *) quadVAOWithName:(NSString *)name vaoBlock:(void(^)())block {
    
    GKVertexArrayObject *vaoObject = [self vertexArrayObjects][name];
    if(!vaoObject) {
        vaoObject = [GKVertexArrayObject new];
        [self vertexArrayObjects][name] = vaoObject;
    }
    GLuint vaoName = vaoObject.vaoName;
    if(!vaoName) {
        GLushort indices[6] = {0,1,2,2,3,0};
        GKTexturedColoredVertex vertices[4] = {
            (GKTexturedColoredVertex){{1,0,0},
                {1, 1, 1, 1}, {1,0}},
            (GKTexturedColoredVertex){{1,1,0},
                {1, 1, 1, 1}, {1,1}},
            (GKTexturedColoredVertex){{0,1,0},
                {1, 1, 1, 1}, {0,1}},
            (GKTexturedColoredVertex){{0,0,0},
                {1, 1, 1, 1}, {0,0}},
        };
        
        GLuint vertexBuffer;
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GKTexturedColoredVertex)*4, vertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER,0);
        
        GLuint indexBuffer;
        glGenBuffers(1, &indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort)*6, indices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        glGenVertexArraysOES(1, &vaoName);
        glBindVertexArrayOES(vaoName);
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        
        if(block) {
            block();
        }
        
        glBindBuffer(GL_ARRAY_BUFFER,0);
        glBindVertexArrayOES(0);
        
        vaoObject.vaoName = vaoName;
        vaoObject.indexBufferName = indexBuffer;
        vaoObject.vertexBufferName = vertexBuffer;
    }
    return vaoObject;
}

@end
