//
//  GLShaderProgram.m
//  Pods
//
//  Created by apple on 1/13/15.
//
//

#import "GLShaderProgram.h"
#import "NSBundle+GraphitiKit.h"
#import <OpenGLES/ES2/glext.h>
#import "GKLog.h"

@interface GLShaderProgram () {
    GLuint shaderProgram;
}
@end

@implementation GLShaderProgram

+ (void) deleteAllShaderProgram {
    [[self shaderProgramMaps] enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *obj, BOOL *stop) {
        glDeleteProgram((GLuint)obj.unsignedIntValue);
    }];
    [[self shaderProgramMaps] removeAllObjects];
}

+ (NSMutableDictionary *) shaderProgramMaps {
    static NSMutableDictionary *__shaderProgramMaps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shaderProgramMaps = [NSMutableDictionary dictionary];
    });
    return __shaderProgramMaps;
}

+ (instancetype) programWithFilename:(NSString *)shaderFilename programType:(GLShaderProgramType) type {
    return [[GLShaderProgram alloc] initWithFilename:shaderFilename programType:type];
}
- (instancetype) initWithFilename:(NSString *)shaderFilename programType:(GLShaderProgramType) type {
    self = [super init];
    if(self) {
        NSString *shaderPathname;
        NSString *typeName = @"vsh";
        if(type == GLFragmentShaderProgram) {
            typeName = @"fsh";
        }
        
        shaderPathname = [NSBundle GKPathForResource:shaderFilename ofType:typeName];
        assert(shaderPathname);
        
        if (![self compileShaderProgram:&shaderProgram type:type file:shaderPathname]) {
            GKLogError(@"Failed to compile & link shader");
        }
    }
    return self;
}

- (BOOL)compileShaderProgram:(GLuint *)targetShaderProgram type:(GLenum)type file:(NSString *)file {
    GLint status;
    NSNumber *shaderProgramID = [GLShaderProgram shaderProgramMaps][file];
    if(shaderProgramID) {
        GKLogDebug(@"use existing shader program %@\n file named %@",shaderProgramID,file);
        *targetShaderProgram = shaderProgramID.unsignedIntValue;
    } else {
        const GLchar *source;
        source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
        if (!source) {
            GKLogError(@"Failed to load vertex shader");
            return NO;
        }
        
        // use this extension method to compile and link program with one shader, so we can reuse & mix match them
        *targetShaderProgram = glCreateShaderProgramvEXT(type, 1, &source);
        glProgramParameteriEXT(*targetShaderProgram, GL_PROGRAM_SEPARABLE_EXT, GL_TRUE);
        GKLogDebug(@"created shader program %@\n file named %@",@(*targetShaderProgram),file);
    }
    
    glGetProgramiv(*targetShaderProgram, GL_LINK_STATUS, &status);
    if(status == GL_TRUE) {
        [GLShaderProgram shaderProgramMaps][file] = @(*targetShaderProgram);
    }
    return status == GL_TRUE;
}

- (BOOL) linked {
    GLint status;
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &status);
    return status == GL_TRUE;
}

- (GLuint) shaderProgram {
    return shaderProgram;
}

- (GLint)attributeIndex:(NSString *)attributeName {
    return glGetAttribLocation(shaderProgram, [attributeName UTF8String]);
}

- (GLint)uniformIndex:(NSString *)uniformName {
    return glGetUniformLocation(shaderProgram, [uniformName UTF8String]);
}

@end
