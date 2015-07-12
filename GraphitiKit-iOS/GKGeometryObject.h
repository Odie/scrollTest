//
//  GKGeometryObject.h
//  Pods
//
//  Created by apple on 2/23/15.
//
//

#import "GKObject.h"

@class GLSLProgram;
@class GKVertexArrayObject;
@class GKTexture;

@interface GKGeometryObject : GKObject <GKRendererComponent,GKTransformComponent>

@property (nonatomic) BOOL removed;
@property (nonatomic) BOOL flipY;
@property (nonatomic) CGSize objectInitialSize;
@property (nonatomic,readonly) CGRect worldRect;
@property (nonatomic,readonly) NSString *imagePath;
@property (nonatomic,readonly) BOOL textureLoaded;
@property (nonatomic) BOOL skipAlphaBlend;

- (instancetype) initWithShader:(GLSLProgram *)shaderProgram imagePath:(NSString *)imagePath vao:(GKVertexArrayObject *)vao position:(GLKVector3)position scale:(GLfloat)scale rotation:(GLfloat)rotation;

- (instancetype) initWithTexture:(GKTexture *)texture imagePath:(NSString *)imagePath position:(GLKVector3)position scale:(GLfloat)scale rotation:(GLfloat)rotation objectSize:(CGSize)objectSize;

- (void) loadTexture;
- (void) unloadTexture;
- (void) updateTextureDataWithBigmapInfo:(CGBitmapInfo)bitmapInfo;
- (void) updateTextureWithData:(CFDataRef)dataRef rect:(CGRect)rect;

- (void) updateTextureWithObject:(GKGeometryObject *)object completed:(void(^)(CFDataRef data))block;

@end
