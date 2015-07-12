//
//  GLSLProgram.m
//  ParticleEmitterDemoES2+ARC
//
//  Created by Mike Daley on 05/06/2013.
//  Modified by Jason Chang on 01/13/2014.
//  Copyright (c) 2013 71Squared Ltd. All rights reserved.
//

#import "GLSLProgram.h"
#import "NSBundle+GraphitiKit.h"
#import <OpenGLES/ES2/glext.h>
#import "GLShaderProgram.h"
#import "GKLog.h"

#pragma mark Function Pointer Definitions
typedef void (*GLInfoFunction)(GLuint program,
                                GLenum pname,
                                GLint* params);

typedef void (*GLLogFunction) (GLuint program,
                                GLsizei bufsize,
                                GLsizei* length,
                                GLchar* infolog);

@interface GLSLProgramManager : NSObject
+ (instancetype) defaultManager;
@property (strong,nonatomic) NSMutableDictionary *programs;
@end

@implementation GLSLProgramManager

+ (instancetype) defaultManager {
    static GLSLProgramManager *_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [GLSLProgramManager new];
    });
    return _manager;
}

- (NSMutableDictionary *) programs {
    if(!_programs) {
        _programs = [NSMutableDictionary dictionary];
    }
    return _programs;
}

@end

#pragma mark -
#pragma mark Private Extension Method Declaration

@interface GLSLProgram()
{
    NSMutableArray  *attributes;
    GLuint          program,
                    vertShader,
                    fragShader;
    GLuint          programPipelineObject;
    BOOL            usePPO;
}

@property (strong,nonatomic) NSMutableDictionary *attributeMap;
@property (strong,nonatomic) NSMutableDictionary *uniformMap;
@property (strong,nonatomic) GLShaderProgram *vertShaderProgram;
@property (strong,nonatomic) GLShaderProgram *fragShaderProgram;

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (NSString *)logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunc logFunc:(GLLogFunction)logFunc;

@end
#pragma mark -

@implementation GLSLProgram

+ (void) releaseAllPrograms {
    [[GLSLProgramManager defaultManager].programs removeAllObjects];
    [GLShaderProgram deleteAllShaderProgram];
}

+ (void) releaseProgramWithVertexShaderFile:(NSString *)vertexShaderFile fragmentShaderFile:(NSString *)fragmentShaderFile {
    if(vertexShaderFile.length != 0 && fragmentShaderFile.length != 0) {
        NSString *lookupName = [vertexShaderFile stringByAppendingFormat:@"-%@",fragmentShaderFile];
        [[GLSLProgramManager defaultManager].programs removeObjectForKey:lookupName];
    }
}

+ (instancetype) programWithVertexShaderFile:(NSString *)vertexShaderFile fragmentShaderFile:(NSString *)fragmentShaderFile {
    if(vertexShaderFile.length != 0 && fragmentShaderFile.length != 0) {
        NSString *lookupName = [vertexShaderFile stringByAppendingFormat:@"-%@",fragmentShaderFile];
        GLSLProgram *program = [GLSLProgramManager defaultManager].programs[lookupName];
        if(program) {
            GKLogInfo(@"reusing program pipeline object %zd",program->programPipelineObject);
            return program;
        }
        GLShaderProgram *vertProgram = [GLShaderProgram programWithFilename:vertexShaderFile programType:GLVertexShaderProgram];
        GLShaderProgram *fragProgram = [GLShaderProgram programWithFilename:fragmentShaderFile programType:GLFragmentShaderProgram];
        if([vertProgram linked] && [fragProgram linked]) {
            program = [GLSLProgram new];
            program.vertShaderProgram = vertProgram;
            program.fragShaderProgram = fragProgram;
            glGenProgramPipelinesEXT(1, &program->programPipelineObject);
            glBindProgramPipelineEXT(program->programPipelineObject);
            glUseProgramStagesEXT(program->programPipelineObject, GL_VERTEX_SHADER_BIT_EXT, [vertProgram shaderProgram]);
            glUseProgramStagesEXT(program->programPipelineObject, GL_FRAGMENT_SHADER_BIT_EXT, [fragProgram shaderProgram]);
            program->usePPO = YES;
            [GLSLProgramManager defaultManager].programs[lookupName] = program;
            return program;
        }
    }
    return nil;
}

- (instancetype)initWithVertexShaderProgram:(GLShaderProgram *)vShaderProgram fragmentShaderFilename:(GLShaderProgram *)fShaderProgram {
    self = [super init];
    if(self) {
        self.fragShaderProgram = fShaderProgram;
        self.vertShaderProgram = vShaderProgram;
        glGenProgramPipelinesEXT(1, &programPipelineObject);
        glBindProgramPipelineEXT(programPipelineObject);
        glUseProgramStagesEXT(programPipelineObject, GL_VERTEX_SHADER_BIT_EXT, [vShaderProgram shaderProgram]);
        glUseProgramStagesEXT(programPipelineObject, GL_FRAGMENT_SHADER_BIT_EXT, [fShaderProgram shaderProgram]);
        usePPO = YES;
    }
    return self;
}

- (instancetype)initWithVertexShaderFilename:(NSString *)vShaderFilename fragmentShaderFilename:(NSString *)fShaderFilename
{
    if (self = [super init]) {
        attributes = [NSMutableArray new];
        NSString *vertShaderPathname, *fragShaderPathname;
        program = glCreateProgram();
        
        vertShaderPathname = [NSBundle GKPathForResource:vShaderFilename ofType:@"vsh"];
        assert(vertShaderPathname);
        
        if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
            GKLogError(@"Failed to compile vertex shader");
        
        // Create and compile fragment shader
        fragShaderPathname = [NSBundle GKPathForResource:fShaderFilename ofType:@"fsh"];
        assert(fragShaderPathname);
        
        if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
            GKLogError(@"Failed to compile fragment shader");
        }
        
        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);
    }
    
    return self;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source =
    (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        GKLogError(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    return status == GL_TRUE;
}

#pragma mark -

- (void)addAttribute:(NSString *)attributeName
{
    if(usePPO) {
        return;
    }
    if (![attributes containsObject:attributeName])
    {
        [attributes addObject:attributeName];
        glBindAttribLocation(program, (GLint)[attributes indexOfObject:attributeName], [attributeName UTF8String]);
    }
}

- (GLint)attributeIndex:(NSString *)attributeName {
    if(usePPO) {
        NSNumber *mappedValue = self.attributeMap[attributeName];
        if(mappedValue) {
            return (GLint)mappedValue.intValue;
        }
        GLint index = [self.vertShaderProgram attributeIndex:attributeName];
        if(index != -1) {
            self.attributeMap[attributeName] = @(index);
        }
        return index;
    } else {
        return (GLint)[attributes indexOfObject:attributeName];
    }
}

- (GLint)uniformIndex:(NSString *)uniformName {
    if(usePPO) {
        NSNumber *mappedValue = self.uniformMap[uniformName];
        if(mappedValue) {
            return (GLint)mappedValue.intValue;
        }
        GLint index = [self.vertShaderProgram uniformIndex:uniformName];
        if(index == -1) {
            index = [self.fragShaderProgram uniformIndex:uniformName];
        }
        if(index != -1) {
            self.uniformMap[uniformName] = @(index);
        }
        return index;
    } else {
        return glGetUniformLocation(program, [uniformName UTF8String]);
    }
}

#pragma mark -

- (BOOL)link {
    if(usePPO) {
        return YES;
    }
    GLint status;
    
    glLinkProgram(program);
    glValidateProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return YES;
}

- (void)use {
    if(usePPO) {
        glBindProgramPipelineEXT(programPipelineObject);
    } else {
        glUseProgram(program);
    }
}

- (void) unuse {
    if(usePPO) {
        glBindProgramPipelineEXT(0);
    } else {
        glUseProgram(0);
    }
}

#pragma mark <program pipeline method>

- (GLuint) vertexProgram {
    return [self.vertShaderProgram shaderProgram];
}

- (GLuint) fragmentProgram {
    return [self.fragShaderProgram shaderProgram];
}

#pragma mark -

- (NSString *)logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunc logFunc:(GLLogFunction)logFunc
{
    GLint logLength = 0, charsWritten = 0;
    
    infoFunc(object, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength < 1)
        return nil;
    
    char *logBytes = malloc(logLength);
    logFunc(object, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes length:logLength encoding:NSUTF8StringEncoding];
    free(logBytes);
    return log;
}

- (NSString *)vertexShaderLog
{
    return [self logForOpenGLObject:vertShader
                       infoCallback:(GLInfoFunction)&glGetProgramiv
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
    
}

- (NSString *)fragmentShaderLog
{
    return [self logForOpenGLObject:fragShader
                       infoCallback:(GLInfoFunction)&glGetProgramiv
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}

- (NSString *)programLog
{
    return [self logForOpenGLObject:program 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}

#pragma mark -

- (void)dealloc
{
    if (vertShader)
        glDeleteShader(vertShader);
    
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (program)
        glDeleteProgram(program);
    
    if(programPipelineObject) {
        glDeleteProgramPipelinesEXT(1, &programPipelineObject);
    }
}

@end
