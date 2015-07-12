//
//  GLShaderProgram.h
//  Pods
//
//  Created by apple on 1/13/15.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef NS_ENUM(NSUInteger, GLShaderProgramType) {
    GLVertexShaderProgram = GL_VERTEX_SHADER,
    GLFragmentShaderProgram = GL_FRAGMENT_SHADER,
};

@interface GLShaderProgram : NSObject

@property (readonly,nonatomic) BOOL linked;

+ (instancetype) programWithFilename:(NSString *)shaderFilename programType:(GLShaderProgramType) type;

+ (void) deleteAllShaderProgram;

- (instancetype) initWithFilename:(NSString *)shaderFilename programType:(GLShaderProgramType) type NS_DESIGNATED_INITIALIZER;

- (GLuint) shaderProgram;
- (GLint)attributeIndex:(NSString *)attributeName;
- (GLint)uniformIndex:(NSString *)uniformName;

@end