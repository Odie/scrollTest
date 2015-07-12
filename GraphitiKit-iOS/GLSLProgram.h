@import Foundation;
@import GLKit;

@class GLShaderProgram;

@interface GLSLProgram : NSObject

+ (instancetype) programWithVertexShaderFile:(NSString *)vertexShaderFile fragmentShaderFile:(NSString *)fragmentShaderFile;
+ (void) releaseAllPrograms;
+ (void) releaseProgramWithVertexShaderFile:(NSString *)vertexShaderFile fragmentShaderFile:(NSString *)fragmentShaderFile;

//- (instancetype)initWithVertexShaderFilename:(NSString *)vShaderFilename fragmentShaderFilename:(NSString *)fShaderFilename;
//- (instancetype)initWithVertexShaderProgram:(GLShaderProgram *)vertShaderProgram fragmentShaderFilename:(GLShaderProgram *)fragShaderProgram;

- (void)addAttribute:(NSString *)attributeName;
- (GLint)attributeIndex:(NSString *)attributeName;
- (GLint)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;
- (void)unuse;
- (NSString *)vertexShaderLog;
- (NSString *)fragmentShaderLog;
- (NSString *)programLog;

- (GLuint) vertexProgram;
- (GLuint) fragmentProgram;

@end
