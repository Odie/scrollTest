//
//  GKTransformableObject.h
//  Pods
//
//  Created by apple on 2/12/15.
//
//

#import "GKObject.h"
#import "GPGestureHandlerDelegate.h"
#import "GestureController.h"

typedef struct {
    GLfloat tl;
    GLfloat tr;
    GLfloat bl;
    GLfloat br;
} QuadWeight;

@class GestureController;

@interface GKTransformableObject : GKObject <GKTransformComponent,GPGestureHandlerDelegate,GKDetectionStrategyDelegate>

@property (nonatomic) CGSize objectInitialSize;
@property (nonatomic) float localScale;
@property (nonatomic) float localRotationInRadian;
@property (readonly) BOOL gestureControlActive;
@property (nonatomic) BOOL visible;

@property (nonatomic) BOOL allowMovement;
@property (nonatomic) BOOL allowZoom;
@property (nonatomic) BOOL allowRotate;

- (instancetype) initWithGestureController:(GestureController *)controller size:(CGSize)size NS_DESIGNATED_INITIALIZER;

- (void) updateModelMatrix;
- (BOOL) containsPoint:(CGPoint)point;
//- (void) weightedMoveToPosition:(GLKVector3)position;
//- (void) removeAnimation;
//- (void) animatGlowColor:(GLKVector4)color duration:(CGFloat)duration;

@end
