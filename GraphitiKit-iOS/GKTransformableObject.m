//
//  GKTransformableObject.m
//  Pods
//
//  Created by apple on 2/12/15.
//
//

#import "GKTransformableObject.h"

#import "GPDrawGestureRecognizer.h"
#import "GestureController.h"
#import "GraphitiKitMacros.h"

//static float normalizedTowardZero(float target, float delta) {
//    if(target > 0) {
//        target = (target-delta) < 0 ? 0 : (target-delta);
//    } else if(target < 0) {
//        target = (target+delta) > 0 ? 0 : (target+delta);
//    }
//    return target;
//}

@interface GKTransformableObject () {
//    GLKVector3 targetPosition;
//    GLKVector3 originalPosition;
//    float timeLerp;
//    BOOL lerpPosition;
//    BOOL lerpColor;
//    QuadWeight quadWeight;
//    GLKVector4 glowColor;
//    CGFloat lerpDuration;
//    CGFloat colorLerpTime;
//    GLKVector4 originalColor;
//    GLKVector4 targetColor;
//    CGFloat recoverTimer;
}
@property (nonatomic) CGPoint touchOffset;
@property (nonatomic) GLKVector3 localGesturePoint;
//@property (nonatomic) float localScale;
//@property (nonatomic) float localRotationInRadian;
@end

@implementation GKTransformableObject

@synthesize enabled = _enabled;
@synthesize scale = _scale;
@synthesize minimumScale = _minimumScale;
@synthesize position = _position;
@synthesize rotationInRadian = _rotationInRadian;
@synthesize modelMatrix = _modelMatrix;
@synthesize inverseModelMatrix = _inverseModelMatrix;

- (instancetype) initWithGestureController:(GestureController *)controller size:(CGSize)size {
    self = [super init];
    if (self) {
        self.visible = NO;
        self.gestureController = controller;
        self.objectInitialSize = size;
        _modelMatrix = GLKMatrix4Identity;
        _inverseModelMatrix = GLKMatrix4Identity;
        _scale = 1.0;
        _localScale = 1.0;
//        glowColor = (GLKVector4){0,1,0,0.2};
    }
    return self;
}

- (void) dealloc {
    self.enabled = NO;
}

- (GLKVector3) latestPosition {
    return [self calculateNewCenter];
}

- (GLfloat) latestScale {
    return _scale * _localScale;
}

- (GLfloat) latestRotation {
    return _rotationInRadian + _localRotationInRadian;
}

- (void) setScale:(GLfloat)scale {
    _scale = scale;
    _localScale = 1.0;
}

- (void) setRotationInRadian:(GLfloat)rotationInRadian {
    _rotationInRadian = rotationInRadian;
    _localRotationInRadian = 0;
}

- (void) updateModelMatrix {
    GLKMatrix4 matrix = GLKMatrix4Identity;
    // scale & rotate about an arbitary point define in model space
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(_localScale, _localScale, 1);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(_localRotationInRadian, 0, 0, 1);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-_localGesturePoint.x, -_localGesturePoint.y, 0),matrix);
    matrix = GLKMatrix4Multiply(scaleMatrix, matrix);
    matrix = GLKMatrix4Multiply(rotateMatrix, matrix);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(_localGesturePoint.x, _localGesturePoint.y, 0),matrix);
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

- (void) setEnabled:(BOOL)enabled {
    _enabled = enabled;
    self.gestureEnabled = enabled;
}

- (BOOL) gestureControlActive {
    return _enabled && _gestureEnabled && (_allowMovement || self.allowRotate || self.allowZoom);
}

#pragma mark <GPGestureHandlerDelegate>

@synthesize gestureEnabled = _gestureEnabled;
@synthesize gestureController;
@dynamic gestureActive;

- (BOOL) gestureActive {
    return self.allowMovement || self.allowRotate || self.allowZoom;
}

- (void) setGestureEnabled:(BOOL)gestureEnabled {
    _gestureEnabled = gestureEnabled;
    if(_gestureEnabled) {
        [self.gestureController addGestureHandler:self];
    } else {
        [self.gestureController removeGestureHandler:self];
    }
}

- (void) touchBecomePrimaryTouch:(UITouch *)touch location:(CGPoint)location center:(CGPoint)center {
    CGPoint offset = (CGPoint) {
        self.position.x-center.x,
        self.position.y-center.y,
    };
    self.touchOffset = offset;
}

- (void) handlePinchGesture:(UIPinchGestureRecognizer *)gesture location:(CGPoint)location {
    if(!self.gestureEnabled || !self.visible) {
        return;
    }
    switch(gesture.state) {
        case UIGestureRecognizerStateBegan:
            if([self containsPoint:location]) {
                self.allowZoom = YES;
                [self beginScaleRotateAtWorldLocation:location];
            }
            break;
        case UIGestureRecognizerStateChanged: {
            if(self.allowZoom) {
                [self scaleAtWorldLocation:location scale:[gesture scale]];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if(self.allowZoom) {
                [self stopScaleRotate];
                self.allowZoom = NO;
            }
            break;
        default:
            break;
    }
}

- (void) handleRotateGesture:(UIRotationGestureRecognizer *)gesture location:(CGPoint)location {
    if(!self.gestureEnabled || !self.visible) {
        return;
    }
    switch(gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if([self containsPoint:location]) {
                self.allowRotate = YES;
                [self beginScaleRotateAtWorldLocation:location];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if(self.allowRotate) {
                CGFloat rotation = -[gesture rotation];
                [self rotateAtWorldLocation:location angle:rotation];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if(self.allowRotate) {
                [self stopScaleRotate];
                self.allowRotate = NO;
            }
            break;
        default:
            break;
    }
}

- (BOOL) shouldRecongizeGestureAtLocation:(CGPoint)location {
    CGPoint glLocation = [self.gestureController glLocationFromViewLocation:location];
    if(self.visible && [self containsPoint:glLocation]) {
        return YES;
    }
    return NO;
}

- (void) handleDrawGesture:(GPDrawGestureRecognizer *)gesture location:(CGPoint)location center:(CGPoint)center {
    switch(gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if(!self.visible) {
                self.touchOffset = CGPointZero;
                GLKVector3 pos = (GLKVector3) {
                    center.x + self.touchOffset.x,
                    center.y + self.touchOffset.y,
                    self.position.z
                };
                _position = pos;
                self.touchOffset = CGPointZero;
//                NSLog(@"turned visible throught draw gesture");
                self.visible = YES;
                _allowMovement = YES;
            } else {
                if([self containsPoint:center]) {
                    _allowMovement = YES;
                    return;
                } else {
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if(_allowMovement) {
                GLKVector3 pos = (GLKVector3) {
                    center.x + self.touchOffset.x,
                    center.y + self.touchOffset.y,
                    self.position.z
                };
                [self weightedMoveToPosition:pos];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            _allowMovement = NO;
            break;
        }
        default:
            break;
    }
}

#pragma mark <private>

- (void) weightedMoveToPosition:(GLKVector3)position {
    // TODO , make delayed movement an option
    // OLD lerping experiemntal code
    //    originalPosition = _position;
    //    targetPosition = position;
    //    GLKVector2 direction = GLKVector2Make(targetPosition.x-originalPosition.x,
    //                                          targetPosition.y-originalPosition.y);
    //    if(!(direction.x == direction.y && direction.x == 0)) {
    //        direction = GLKVector2Normalize(direction);
    //    }
    //    direction = GLKVector2MultiplyScalar(direction, 0.5);
    //    [self applyWeightFromDirection:direction];
    _position = position;
    //    recoverTimer = 0.1;
}

- (BOOL) containsPoint:(CGPoint)point {
    GLKVector3 objectPoint = GLKMatrix4MultiplyAndProjectVector3(_inverseModelMatrix, (GLKVector3){point.x,point.y,0});
    CGFloat hw = _objectInitialSize.width/2;
    CGFloat hh = _objectInitialSize.height/2;
    return objectPoint.x >= -hw && objectPoint.x <= hw && objectPoint.y >= -hh && objectPoint.y <= hh;
}

- (void) beginScaleRotateAtWorldLocation:(CGPoint)location {
    if(GLKVector3AllEqualToVector3(_localGesturePoint, GLKVector3Make(0, 0, 0))) {
        _localGesturePoint = GLKMatrix4MultiplyVector3WithTranslation(_inverseModelMatrix, (GLKVector3){location.x,location.y,0});
    }
}

- (void) rotateAtWorldLocation:(CGPoint) location angle:(CGFloat)angle {
    _localRotationInRadian = angle;
}

- (void) scaleAtWorldLocation:(CGPoint) location scale:(CGFloat)scale {
    if(_minimumScale != 0) {
        if(_scale*scale >= _minimumScale) {
            _localScale = scale;
        } else {
            _localScale = _minimumScale/_scale;
        }
    } else {
        _localScale = scale;
    }
}

- (void) stopScaleRotate {
    _position = [self calculateNewCenter];
    _localGesturePoint = GLKVector3Make(0,0,0);
    _rotationInRadian += _localRotationInRadian;
    _localRotationInRadian = 0;
    _scale *= _localScale;
    _localScale = 1.0;
}

- (GLKVector3) calculateNewCenter {
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(_localScale, _localScale, 1);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(_localRotationInRadian, 0, 0, 1);
    GLKMatrix4 matrix = GLKMatrix4Identity;
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-_localGesturePoint.x, -_localGesturePoint.y, 0),matrix);
    matrix = GLKMatrix4Multiply(scaleMatrix,matrix);
    matrix = GLKMatrix4Multiply(rotateMatrix,matrix);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(_localGesturePoint.x, _localGesturePoint.y, 0),matrix);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(_scale,_scale,1),matrix);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(_rotationInRadian, 0, 0, 1),matrix);
    GLKVector3 translation = GLKMatrix4MultiplyVector3WithTranslation(matrix, GLKVector3Make(0,0,0));
    translation.x += _position.x;
    translation.y += _position.y;
    // _worldSpaceModelPosition not used
    return translation;
}

#pragma mark <animated move>

- (void) applyWeightFromDirection:(GLKVector2)direction {
//    quadWeight.tr += (direction.x + direction.y);
//    quadWeight.br += (direction.x - direction.y);
//    quadWeight.tl += (-direction.x + direction.y);
//    quadWeight.bl += (-direction.x - direction.y);
//    quadWeight.tr = CLAMP(quadWeight.tr, -10, 10);
//    quadWeight.br = CLAMP(quadWeight.br, -10, 10);
//    quadWeight.tl = CLAMP(quadWeight.tl, -10, 10);
//    quadWeight.bl = CLAMP(quadWeight.bl, -10, 10);
}

- (void) stablizeQuadWeight:(CGFloat)deltaTime {
//    recoverTimer -= deltaTime;
//    if(recoverTimer <= 0) {
//        deltaTime *= 30;
//        quadWeight.br = normalizedTowardZero(quadWeight.br, deltaTime);
//        quadWeight.bl = normalizedTowardZero(quadWeight.bl, deltaTime);
//        quadWeight.tr = normalizedTowardZero(quadWeight.tr, deltaTime);
//        quadWeight.tl = normalizedTowardZero(quadWeight.tl, deltaTime);
//    }
}

- (void) animatGlowColor:(GLKVector4)color duration:(CGFloat)duration {
//    lerpColor = YES;
//    colorLerpTime = 0;
//    lerpDuration = duration;
//    originalColor = glowColor;
//    targetColor = color;
}

- (void) removeAnimation {
//    recoverTimer = 0;
//    lerpColor = NO;
//    glowColor = (GLKVector4){0,1,0,0.2};
}

@end

/*
 //    if(_renderShadow) {
 //        mvp = GLKMatrix4Multiply(modelMatrix, GLKMatrix4MakeTranslation(-0.0, -0.0, -0.1));
 //        mvp = GLKMatrix4Multiply(projectionMatrix, mvp);
 //        GLKVector4 shadowColor = (GLKVector4){0,0,0,0.5};
 //
 //        shadowVertices[0].color = shadowColor;
 //        shadowVertices[1].color = shadowColor;
 //        shadowVertices[2].color = shadowColor;
 //        shadowVertices[3].color = shadowColor;
 //        glBindBuffer(GL_ARRAY_BUFFER, shadowVertexBuffer);
 //        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(TexturedColoredVertex)*4, shadowVertices);
 //        glBindBuffer(GL_ARRAY_BUFFER, 0);
 //
 //        [self drawShadow:textureInfo.textureName mvp:mvp];
 //    }
 //    if(_renderGlow) {
 //        GLKMatrix4 centerMatrix = GLKMatrix4MakeTranslation(-_imageScreenSize.width/2, -_imageScreenSize.height/2, 0);
 //        GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(_scale.x*1.1, _scale.y*1.1, 1);
 //        GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(_rotationInRadian, 0, 0, 1);
 //        GLKMatrix4 matrix = GLKMatrix4Multiply(rotateMatrix, centerMatrix);
 //        matrix = GLKMatrix4Multiply(scaleMatrix, matrix);
 //        matrix = GLKMatrix4Multiply(
 //                                         GLKMatrix4MakeTranslation(_position.x,
 //                                                                   _position.y, _position.z),matrix);
 //        mvp = GLKMatrix4Multiply(projectionMatrix, matrix);
 //
 //        shadowVertices[0].color = glowColor;
 //        shadowVertices[1].color = glowColor;
 //        shadowVertices[2].color = glowColor;
 //        shadowVertices[3].color = glowColor;
 //        glBindBuffer(GL_ARRAY_BUFFER, shadowVertexBuffer);
 //        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(TexturedColoredVertex)*4, shadowVertices);
 //        glBindBuffer(GL_ARRAY_BUFFER, 0);
 //
 //        [self drawShadow:textureInfo.textureName mvp:mvp];
 //    }
 
 */

/*
 debug use ... consider add a component!!!
 GLKMatrix4 matrix = GLKMatrix4Identity;
 GLKMatrix4 scaleMatrix = GLKMatrix4Identity;
 //    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(0.1, 0.1, 1);
 //    [self calculateNewCenter];
 //
 //    GLKMatrix4 matrix = GLKMatrix4Multiply(scaleMatrix,GLKMatrix4Identity);
 //    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(_worldSpaceModelPosition.x,_worldSpaceModelPosition.y, 0),matrix);
 //    mvp = GLKMatrix4Multiply(projectionMatrix, matrix);
 //    [self drawTexture:textureInfo.textureName mvp:mvp];
 
 
 scaleMatrix = GLKMatrix4MakeScale(0.1, 0.1, 1);
 GLKVector3 loc = GLKMatrix4MultiplyVector3WithTranslation(modelMatrix, temp);
 matrix = GLKMatrix4Multiply(scaleMatrix,GLKMatrix4Identity);
 matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(loc.x,loc.y, 0),matrix);
 mvp = GLKMatrix4Multiply(projectionMatrix, matrix);
 [self drawTexture:textureInfo.textureName mvp:mvp];
 */

/*
 lerp code in update
 
 //    if(lerpColor) {
 //        colorLerpTime += deltaTime;
 //        if(colorLerpTime >= lerpDuration) {
 //            colorLerpTime = lerpDuration;
 //            lerpColor = NO;
 //        }
 //        GLKVector4 color = GLKVector4Lerp(originalColor, targetColor, 1-(lerpDuration-colorLerpTime)/lerpDuration);
 ////        NSLog(@"%f %f %f %f",color.r,color.g,color.b,color.a);
 //        glowColor = color;
 //    }
 // weighted tilt
 //    vertices[0].vertex.z = (((10-quadWeight.br)/10)-1)*0.05;
 //    vertices[1].vertex.z = (((10-quadWeight.tr)/10)-1)*0.05;
 //    vertices[2].vertex.z = (((10-quadWeight.tl)/10)-1)*0.05;
 //    vertices[3].vertex.z = (((10-quadWeight.bl)/10)-1)*0.05;
 //    NSLog(@"%f %f %f %f",vertices[0].vertex.z,vertices[1].vertex.z,vertices[2].vertex.z,vertices[3].vertex.z);
 //    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
 //    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(TexturedColoredVertex)*4, vertices);
 //    glBindBuffer(GL_ARRAY_BUFFER, 0);
 
 //    [self stablizeQuadWeight:deltaTime];
 //    NSLog(@"%f %f %f %f",quadWeight.br,quadWeight.tr,quadWeight.tl,quadWeight.bl);
 
 */