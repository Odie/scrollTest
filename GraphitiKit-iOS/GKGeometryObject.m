//
//  GKGeometryObject.m
//  Pods
//
//  Created by apple on 2/23/15.
//
//

#import "GKGeometryObject.h"
#import "GKTextureHelper.h"
#import "GKVertexArrayObject.h"
#import "GLSLProgram.h"
#import <OpenGLES/ES2/glext.h>
#import "GKVertex.h"
#import "GKLog.h"

#define TEXTUREDAFETIME 0.4f

@interface GKGeometryObject () {
    GKVertexArrayObject *_vao;
    NSString *_imagePath;
    GLSLProgram *_shaderProgram;
    GKTexture *_textureInfo;

    GLuint textureUniform,
    MPMtxUniform,
    opacityUniform,
    visibilityUniform;
    
    // shader attributes
    GLuint inPositionAttrib,
    inColorAttrib,
    inTexCoordAttrib;
    BOOL _active;
    GLfloat _timer;
}
@end

@implementation GKGeometryObject

@synthesize imagePath = _imagePath;
@synthesize worldRect = _worldRect;

- (instancetype) initWithShader:(GLSLProgram *)shaderProgram imagePath:(NSString *)imagePath vao:(GKVertexArrayObject *)vao position:(GLKVector3)position scale:(GLfloat)scale rotation:(GLfloat)rotation {
    self = [super init];
    if(self) {
        _worldRect = CGRectNull;
        _flipY = YES;
        _position = position;
        _scale = scale;
        _rotationInRadian = rotation;
        _shaderProgram = shaderProgram;
        _imagePath = imagePath;
        _vao = vao;
        _modelMatrix = GLKMatrix4Identity;
        _inverseModelMatrix = GLKMatrix4Identity;
        [self setupShaders];
        [self updateModelMatrix];
        [self setupGL];
        self.enabled = YES;
    }
    return self;
}

- (instancetype) initWithTexture:(GKTexture *)texture imagePath:(NSString *)imagePath position:(GLKVector3)position scale:(GLfloat)scale rotation:(GLfloat)rotation objectSize:(CGSize)objectSize {
    self = [super init];
    if(self) {
        _worldRect = CGRectNull;
        _flipY = NO;
        _position = position;
        _scale = scale;
        _imagePath = imagePath;
        _rotationInRadian = rotation;
        _shaderProgram = [GLSLProgram programWithVertexShaderFile:@"VertexShader" fragmentShaderFile:@"FragmentShader"];
        _textureInfo = texture;
        _modelMatrix = GLKMatrix4Identity;
        _inverseModelMatrix = GLKMatrix4Identity;
        [self updateModelMatrix];
        self.objectInitialSize = objectSize;
        [self setupShaders];
        _vao = [GKVertexArrayObject textureVAOWithName:@"sticker" vaoBlock:^{
            glEnableVertexAttribArray(inPositionAttrib);
            glEnableVertexAttribArray(inColorAttrib);
            glEnableVertexAttribArray(inTexCoordAttrib);
            
            glVertexAttribPointer(inPositionAttrib, 3, GL_FLOAT, GL_FALSE, sizeof(GKTexturedColoredVertex), 0);
            glVertexAttribPointer(inColorAttrib, 4, GL_FLOAT, GL_FALSE, sizeof(GKTexturedColoredVertex), (const GLvoid *) offsetof(GKTexturedColoredVertex, color));
            glVertexAttribPointer(inTexCoordAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(GKTexturedColoredVertex), (const GLvoid *) offsetof(GKTexturedColoredVertex, texCoord));
        }];
        _active = YES;
        self.enabled = YES;
    }
    return self;
}

- (void) dealloc {
    [self teardownGL];
}

- (void) updateTextureWithData:(CFDataRef)dataRef rect:(CGRect)rect {
    [_textureInfo updateDataWithData:dataRef rect:rect];
}

- (void) updateTextureDataWithBigmapInfo:(CGBitmapInfo)bitmapInfo {
    if(_textureInfo) {
        [_textureInfo updateDataWith:[UIImage imageWithContentsOfFile:self.imagePath] bitmapInfo:bitmapInfo];
    }
}

- (void) updateTextureWithObject:(GKGeometryObject *)object completed:(void(^)(CFDataRef data))block {
    if(self.imagePath.length && object.imagePath.length) {
        CGRect srcRect = object.worldRect;
        CGRect destRect = self.worldRect;
        NSString *imagePath = self.imagePath;
        
        // use nsoperation instead of this queue
        dispatch_queue_t textureWorkerQueue = [GKTextureHelper textureWorkerQueue];
        if(!textureWorkerQueue) {
            return;
        }
        dispatch_async(textureWorkerQueue, ^{
            @autoreleasepool {
//                GKLogDebug(@"working on merge %@ with %@",[imagePath lastPathComponent],[object.imagePath lastPathComponent]);
                UIImage *srcImage = [UIImage imageWithContentsOfFile:object.imagePath];
                UIImage *destImage = [UIImage imageWithContentsOfFile:imagePath];

                CGFloat offsetX = srcRect.origin.x - destRect.origin.x;
                CGFloat offsetY = srcRect.origin.y - destRect.origin.y;
                
                CGSize rotatedSize = srcImage.size;
                CGPoint offset = (CGPoint){offsetX,offsetY};
                if(object.flipY) {
                    CGRect testRect = (CGRect){0,0,rotatedSize};
                    CGAffineTransform t = CGAffineTransformRotate(CGAffineTransformMakeScale(object.scale, object.scale),object.rotationInRadian);
                    CGRect aaa = CGRectApplyAffineTransform(testRect, t);
                    rotatedSize = aaa.size;
                    offset.y = offset.y-(destRect.size.height-srcRect.size.height);
                    offset = CGPointApplyAffineTransform(offset, CGAffineTransformInvert(t));
                }
                UIGraphicsBeginImageContextWithOptions(destRect.size, NO, 2.0);
                
                if(destImage) {
                    [destImage drawInRect:(CGRect){CGPointZero,destRect.size}];
                    destImage = nil;
                }
                if(object.flipY) {
                    CGContextSaveGState(UIGraphicsGetCurrentContext());
                    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), rotatedSize.width/2, rotatedSize.height/2);
                    CGContextScaleCTM(UIGraphicsGetCurrentContext(), object.scale, object.scale);
                    CGContextRotateCTM(UIGraphicsGetCurrentContext(), -object.rotationInRadian);
                    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1, -1);
                    CGContextDrawImage(UIGraphicsGetCurrentContext(), (CGRect){{-srcImage.size.width/2+offset.x,-srcImage.size.height/2+offset.y},srcImage.size}, srcImage.CGImage);
                    CGContextRestoreGState(UIGraphicsGetCurrentContext());
                } else {
                    CGContextDrawImage(UIGraphicsGetCurrentContext(), (CGRect){{offsetX, destRect.size.height-srcRect.size.height-offsetY},srcRect.size}, srcImage.CGImage);
                }
                UIImage *current = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
//                CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(current.CGImage));
                NSData *data = UIImagePNGRepresentation(current);
                [data writeToFile:imagePath atomically:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(block) {
                        block(nil);
                    }
                });
            }
        });
    }
}

- (CGRect) worldRect {
    if(CGRectIsNull(_worldRect)) {
        if(_scale == 1 && _rotationInRadian == 0) {
            _worldRect = (CGRect){
                {_position.x-_objectInitialSize.width/2,_position.y-_objectInitialSize.height/2},
                {_objectInitialSize.width,_objectInitialSize.height}};
        } else {
            CGRect rect = CGRectMake(_position.x-_objectInitialSize.width/2*_scale,
                                         _position.y-_objectInitialSize.height/2*_scale,
                                         _objectInitialSize.width*_scale,
                                         _objectInitialSize.height*_scale
                                         );
            CGFloat midX = CGRectGetMidX(rect);
            CGFloat midY = CGRectGetMidY(rect);
            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformRotate(CGAffineTransformMakeTranslation(midX, midY),_rotationInRadian),-midX,-midY);
            _worldRect = CGRectApplyAffineTransform(rect, transform);
        }
    }
    return _worldRect;
}

- (void) updateModelMatrix {
    GLKMatrix4 matrix = GLKMatrix4Identity;
    // apply existing model scale in model space
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(_scale,_scale,1),matrix);
    // apply existing model rotation in model space
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(_rotationInRadian, 0, 0, 1),matrix);
    // apply translation to world space
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(_position.x,_position.y, 0),matrix);
    _modelMatrix = matrix;
    // calculate inverse matrix
    bool invertable;
    _inverseModelMatrix = GLKMatrix4Invert(_modelMatrix, &invertable);
}

- (void) loadTexture {
    if(_removed) {
        return;
    }
    _active = YES;
    if(!_textureInfo) {
        __weak typeof(self) weakSelf = self;
        [GKTextureHelper queueLoadTextureFromFilePath:_imagePath flipY:_flipY completed:^(GKTexture *texture, NSError *error) {
            if(weakSelf && texture) {
                __strong typeof(weakSelf) self = weakSelf;
                if(self->_shaderProgram) {
                    self->_textureInfo = texture;
                }
            }
        }];
    }
}

- (void) unloadTexture {
    _timer = TEXTUREDAFETIME;
    [GKTextureHelper queueDeleteTexture:_textureInfo];
    _textureInfo = nil;
    _active = NO;
}

- (BOOL) textureLoaded {
    return _active;
}

- (void) update:(NSTimeInterval)deltaTime {
    if(_textureInfo && _timer > 0.0f) {
        _timer -= deltaTime;
        if(_timer < 0.0f) {
            _timer = 0.0f;
        }
    }
}

#pragma mark <GKRendererComponent>

@synthesize renderOnMainSurface;

- (void) render:(GLKMatrix4)projectionMatrix {
    if(_active && self.enabled) {
        if(_vao.vaoName == 0 || _vao.indexBufferName == 0) {
            return;
        }
        GLKMatrix4 scaleM = GLKMatrix4ScaleWithVector3(GLKMatrix4Identity, GLKVector3Make(self.objectInitialSize.width/2, self.objectInitialSize.height/2, 1));
        GLKMatrix4 mvp = GLKMatrix4Multiply(projectionMatrix, GLKMatrix4Multiply(_modelMatrix,scaleM));
        [_shaderProgram use];
        glProgramUniformMatrix4fvEXT([_shaderProgram vertexProgram], MPMtxUniform, 1, GL_FALSE, mvp.m);
        glProgramUniform1iEXT([_shaderProgram fragmentProgram], opacityUniform, 0);
        
        glBindVertexArrayOES(_vao.vaoName);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vao.indexBufferName);
        if(!_textureInfo || _textureInfo->textureName == 0) {
            if([GKTextureHelper placeholderTexture]) {
                glBindTexture(GL_TEXTURE_2D, [GKTextureHelper placeholderTexture]->textureName);
            }
        } else {
            glProgramUniform1fEXT([_shaderProgram fragmentProgram], visibilityUniform, _timer);
            glBindTexture(GL_TEXTURE_2D, _textureInfo->textureName);
        }
        
        if(!_skipAlphaBlend) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        }
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindVertexArrayOES(0);
        glBindTexture(GL_TEXTURE_2D, 0);
        if(!_skipAlphaBlend) {
            glDisable(GL_BLEND);
        }
        glProgramUniform1fEXT([_shaderProgram fragmentProgram], visibilityUniform, 0);
        [_shaderProgram unuse];
    }
}
- (void) renderOnSurface:(GLKMatrix4)projectionMatrix {}
- (void) cleanupAfterRender {}
- (void) setupGL {
//    _active = YES;
    if(!_textureInfo) {
//        __weak typeof(self) weakSelf = self;
//        [GKTextureHelper queueLoadTextureFromFilePath:_imagePath flipY:YES completed:^(GKTexture *texture, NSError *error) {
//            if(weakSelf && texture) {
//                __strong typeof(weakSelf) self = weakSelf;
//                if(self->_shaderProgram) {
//                    self->_textureInfo = texture;
//                    self.objectInitialSize = (CGSize){_textureInfo->width,_textureInfo->height};
//                }
//            }
//        }];
        _textureInfo = [GKTextureHelper loadTextureFromFilePath:_imagePath error:nil];
        if(_textureInfo) {
            _timer = 0.0;
            self.objectInitialSize = (CGSize){_textureInfo->width,_textureInfo->height};
        }
    }
    if(_textureInfo) {
        _active = YES;
    }
}

- (void) teardownGL {
    _shaderProgram = nil;
    [GKTextureHelper queueDeleteTexture:_textureInfo];
//    [GKTextureHelper deleteTexture:_textureInfo];
    _active = NO;
}

#pragma mark <GKTransformComponent>

@synthesize scale = _scale;
@synthesize minimumScale = _minimumScale;
@synthesize position = _position;
@synthesize rotationInRadian = _rotationInRadian;
@synthesize modelMatrix = _modelMatrix;
@synthesize inverseModelMatrix = _inverseModelMatrix;

- (GLKVector3) latestPosition {
    return _position;
}

- (GLfloat) latestScale {
    return _scale;
}

- (GLfloat) latestRotation {
    return _rotationInRadian;
}

- (void) setupShaders {
    if(_shaderProgram) {
        inPositionAttrib = [_shaderProgram attributeIndex:@"inPosition"];
        inColorAttrib = [_shaderProgram attributeIndex:@"inColor"];
        inTexCoordAttrib = [_shaderProgram attributeIndex:@"inTexCoord"];
//        textureUniform = [_shaderProgram uniformIndex:@"uniTexture"];
        MPMtxUniform = [_shaderProgram uniformIndex:@"MPMatrix"];
        opacityUniform = [_shaderProgram uniformIndex:@"u_opacityModifyRGB"];
        visibilityUniform = [_shaderProgram uniformIndex:@"visibilityModifier"];
    }
}

@end
