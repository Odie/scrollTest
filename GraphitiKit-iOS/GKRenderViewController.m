//
//  GKRenderViewController.m
//  Pods
//
//  Created by apple on 3/13/15.
//
//

#import "GKRenderViewController.h"

#import <OpenGLES/ES2/glext.h>
#import <WebKit/WebKit.h>

#import "CGPointExtension.h"
#import "UIColor+GraphitiKit.h"
#import "NSString+GraphitiKit.h"
#import "UIScreen+GraphitiKit.h"
#import "EAGLContext+GraphitiKit.h"
#import "GraphitiKitMacros.h"
#import "GKLog.h"

#import "GLShaderProgram.h"
#import "GLSLProgram.h"
#import "GKTextureHelper.h"
#import "GKVertexArrayObject.h"
#import "GKComponent.h"

#import "GestureController.h"
#import "MotionController.h"
#import "GKSplatEngine.h"
#import "GKSnapShotEngine.h"

#import "GKGeometryObject.h"

#import "GKRenderDispatcher.h"
#import "UIScrollView+GKExtension.h"

#ifdef __ARM_NEON
#include <arm_neon.h>
#endif
#import <Accelerate/Accelerate.h>
#import <WebKit/WebKit.h>
#import "GPDrawGestureRecognizer.h"

@interface GKConcreteGestureHandler : NSObject <GPGestureHandlerDelegate>
@property (weak,nonatomic) GKRenderViewController *controller;
@end

@interface GKRenderViewController ()

@property (weak,nonatomic) UIScrollView *targetGestureScrollView;

@property (copy,nonatomic) void(^finalizedBlock)(NSArray *data,UIImage *snapshotImage);
@property (copy,nonatomic) void(^snapShotBlock)(UIImage *snapshotImage);
@property (strong,nonatomic) NSMutableArray *worldObjects;
@property (strong,nonatomic) NSMutableArray *renderTools;

// controllers
@property (strong,nonatomic) GestureController *gestureController;
// drawing realated
@property (weak,nonatomic) GKRenderView *renderView;
@property (strong,nonatomic) GPSurface *surface;
@property (nonatomic) GLKMatrix4 projectionMatrix;

// settings
@property (strong, nonatomic) UIColor *clearColor;

// internal
@property (weak,nonatomic) WKWebView *wkWebView;
@property (weak,nonatomic) UIWebView *uiWebView;

// mimic scrollview
@property (strong,nonatomic) GKGeometryObject *backgroundImageObject;
@property (strong,nonatomic) NSString *worldBackgroundImageFilePath;
@property (strong,nonatomic) GKConcreteGestureHandler *gestureHandler;

- (void) setupGL;
- (void) innerReset;
- (void) startScale;
- (void)changeScaleRatio:(CGFloat)scaleRatio atScreenPosiiton:(CGPoint)scalePosition;
- (void)accumulateOffset:(CGPoint)diff;
@end

@interface GKRenderViewController (Delegation) <GestureControllerDelegate>
@end

@implementation GKRenderViewController {
    GLKMatrix4 defaultProjectionMatrix;
    GLKMatrix4 cameraMatrix;
    BOOL hasDrag;
    BOOL hasZoom;
    CGPoint _viewportTopLeft;
    BOOL needFinalizeDrawing;
    BOOL _oneImageOnly;
    BOOL _requireSnapShot;
    dispatch_queue_t workerQueue;
    NSUInteger _worldObjectCount;
    NSUInteger _worldObjectStartIndex;
    
    CGPoint _cropOffset;
    CGFloat _cropScale;
    CGRect _cropRect;
    CGFloat _viewPortMultiplier;
    
    CGFloat _stencilDesiredScale;
    CGPoint _extraMargin;
    
    CGPoint _panOffset;
    CGFloat _startScale;
    CGFloat _scaleRatio;
    CGPoint _scaleScreenPosition;
    CGPoint _scaleOrigin;
}

#pragma mark - GKRenderView delegate

- (CGPoint)screenToWorldPosition:(CGPoint)pos {
    CGPoint worldPosition;
    worldPosition.x = _viewportTopLeft.x + pos.x/_worldScale;
    worldPosition.y = _viewportTopLeft.y - pos.y/_worldScale;
    NSLog(@"screen %@ world %@",NSStringFromCGPoint(pos),NSStringFromCGPoint(worldPosition));
    return worldPosition;
}

- (void)accumulateOffset:(CGPoint)diff {
    _panOffset = (CGPoint) {
        _panOffset.x + diff.x,
        _panOffset.y + diff.y,
    };
}

- (void)startScale {
    _startScale = self.worldScale;
    _scaleRatio = 1.0;
    _scaleOrigin = _viewportTopLeft;
}

- (void)changeScaleRatio:(CGFloat)scaleRatio atScreenPosiiton:(CGPoint)scalePosition {
    _scaleScreenPosition = scalePosition;
    _scaleRatio = scaleRatio;
}

- (void) updateOffset {
    CGFloat scale = _scaleRatio * _startScale;
    CGPoint test = CGPointZero;
    if(scale > 0) {
//        CGFloat scaleDiff = scale/_worldScale;
//        NSLog(@"scale %f diff %f",scale,scaleDiff);
//        CGSize screenSize = self.view.bounds.size;
//        _scaleScreenPosition = (CGPoint){CGRectGetWidth(self.view.bounds)*0.5,CGRectGetHeight(self.view.bounds)*0.5};
//        CGPoint worldPosition = [self screenToWorldPosition:_scaleScreenPosition];
//        CGFloat x = screenSize.width*0.5/scale-worldPosition.x;
//        CGFloat y = 0;
//        NSLog(@"new world size %f %f",x,y);
//        CGAffineTransform t1 = CGAffineTransformMakeTranslation(-worldPosition.x,-worldPosition.y);
//        CGAffineTransform s = CGAffineTransformMakeScale(scale, scale);
//        CGAffineTransform t2 = CGAffineTransformMakeTranslation(worldPosition.x,worldPosition.y);
//        CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformConcat(t1, s),t2);
//        test = CGPointApplyAffineTransform(_viewportTopLeft, transform);
//        [self setTopLeft:(CGPoint){_viewportTopLeft.x+x,_viewportTopLeft.y+y}];
//        NSLog(@"scaled origin %@",NSStringFromCGPoint(test));
        self.worldScale = scale;
    }
    CGPoint origin = _viewportTopLeft;
    CGPoint newOrigin = (CGPoint){
        origin.x + _panOffset.x/_worldScale,
        origin.y - _panOffset.y/_worldScale,
    };

    [self setTopLeft:newOrigin];
    
    [self updateTransform];
    _panOffset = CGPointZero;
    _scaleRatio = 0;
}

- (void) update:(NSTimeInterval)deltaTime {
    if(self.worldMode == GKWorldFinite) {
        [self updateOffset];
    }
    GLKMatrix4 projectionMatrix = GLKMatrix4Multiply(defaultProjectionMatrix, cameraMatrix);
    self.projectionMatrix = projectionMatrix;
}

- (void) view:(GKRenderView *)view drawInRect:(CGRect)rect {
    GLKMatrix4 projectionMatrix = self.projectionMatrix;
    glClear(GL_COLOR_BUFFER_BIT);
    [self.backgroundImageObject render:projectionMatrix];
}

#pragma mark <properties getter/setter>

- (GLKVector3) viewCenter {
    CGSize size = [self viewSize];
    return (GLKVector3){_viewportTopLeft.x+size.width*0.5,_viewportTopLeft.y-size.height*0.5,0};
}

- (void) setWorldOrigin:(CGPoint)worldOrigin {
    _worldOrigin = worldOrigin;
    _viewportTopLeft = worldOrigin;
    _viewportTopLeft.y = CGRectGetHeight(self.view.bounds) - worldOrigin.y;
//    NSLog(@"top left %@",NSStringFromCGPoint(_viewportTopLeft));
    [self.renderTools enumerateObjectsUsingBlock:^(GKObject *obj, NSUInteger idx, BOOL *stop) {
        obj.worldTopLeft = _viewportTopLeft;
    }];
}

- (void) setTopLeft:(CGPoint)topLeft {
    _viewportTopLeft = topLeft;
//    NSLog(@"top left %@",NSStringFromCGPoint(_viewportTopLeft));
    [self.renderTools enumerateObjectsUsingBlock:^(GKObject *obj, NSUInteger idx, BOOL *stop) {
        obj.worldTopLeft = _viewportTopLeft;
    }];
}

- (void) setWorldScale:(CGFloat)worldScale {
    _worldScale = worldScale;
    [self.renderTools enumerateObjectsUsingBlock:^(GKObject *obj, NSUInteger idx, BOOL *stop) {
        obj.worldScale = _worldScale;
        obj.viewPointPerPoint = _viewPortMultiplier;
    }];
}

- (void) setBaseScale:(CGFloat)baseScale {
    _baseScale = baseScale;
    [GKSplatEngine defaultEngine].worldBaseScale = _baseScale;
}

#pragma mark - helpers

#pragma mark - life cycle mamagement

- (void)dealloc {
    [self kill];
}

- (void) setDisableGesture:(BOOL)disableGesture {
    self.gestureController.disabled = disableGesture;
}

- (void) setWorldBackgroundImage:(UIImage *)image {
    NSString *filePath = [GKSnapShotEngine tempTextureFilePathWithFileName:[GKSnapShotEngine randomSnapShotName]];
    [UIImageJPEGRepresentation(image, 0.5) writeToFile:filePath atomically:YES];
    self.worldBackgroundImageFilePath = filePath;
    if(self.renderView) {
        [self.gestureController addGestureHandler:self.gestureHandler];
        GKRenderDispatch(YES, ^{
            GKTexture *texture = [GKTextureHelper loadTextureFromFilePath:self.worldBackgroundImageFilePath error:nil];
            GKGeometryObject *backgroundObject =
            [[GKGeometryObject alloc] initWithTexture:texture
                                            imagePath:self.worldBackgroundImageFilePath
                                             position:GLKVector3Make(
                                                                     texture->width*0.5,
                                                                     texture->height*0.5,0)
                                                scale:1
                                             rotation:0
                                           objectSize:(CGSize){texture->width,texture->height}];
            backgroundObject.skipAlphaBlend = YES;
            self.backgroundImageObject = backgroundObject;
        });
    }
}

- (void) setupZoomLogicOnScrollView:(UIScrollView *)scrollView {
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.gestureHandler = [GKConcreteGestureHandler new];
        self.gestureHandler.controller = self;
        self.gestureHandler.enabled = YES;
        _viewPortMultiplier = 1.0;
        _cropRect = CGRectZero;
        _cropOffset = CGPointZero;
        _cropScale = 1.0;
        _scrollContentOffsetRatio = 1.0;
        self.renderTools = [NSMutableArray array];
        self.worldObjects = [NSMutableArray array];
        self.baseScale = 1;
        self.worldScale = 1;
        workerQueue = dispatch_queue_create("com.graphiti.graphitikit.splattask", NULL);
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self setupControllers];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.visibleRect = self.view.bounds;
    [GKSplatEngine defaultEngine].screenHeight = CGRectGetHeight(self.view.bounds);
    [self setupGL];
    [self updateProjectionMatrix];
    self.projectionMatrix = GLKMatrix4Multiply(defaultProjectionMatrix, cameraMatrix);
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.renderView.paused = YES;
}

- (void) frameBufferReady {
    // init my surface here
}

- (void)setupGL {
    if(!self.renderView) {
        CGRect frameRect = self.view.bounds;
        GKRenderView *renderView = [[GKRenderView alloc] initWithFrame:frameRect];
        [self.view addSubview:renderView];
        renderView.delegate = self;
        self.renderView = renderView;
        [GKTextureHelper setupBackgroundContextWithAPI:renderView.renderContext.API shareGroup:renderView.renderContext.sharegroup];
        __weak typeof(self) weakSelf = self;
        GKRenderDispatch(YES, ^{
            __strong typeof(weakSelf) self = weakSelf;
            // setup fixed states
            glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
            self.clearColor = [UIColor colorWithWhite:0 alpha:0];
            if(self.worldBackgroundImageFilePath.length) {
                // setup background object
                GKTexture *texture = [GKTextureHelper loadTextureFromFilePath:self.worldBackgroundImageFilePath error:nil];
                CGFloat originY = (frameRect.size.height - texture->height)*0.5;
                if(texture->height > frameRect.size.height) {
                    originY = frameRect.size.height-texture->height;
                }
                GKGeometryObject *backgroundObject =
                [[GKGeometryObject alloc] initWithTexture:texture
                                                imagePath:self.worldBackgroundImageFilePath
                                                 position:GLKVector3Make(
                                                                         texture->width*0.5,
                                                                         texture->height*0.5+originY,0)
                                                    scale:1
                                                 rotation:0
                                               objectSize:(CGSize){texture->width,texture->height}];
                backgroundObject.skipAlphaBlend = YES;
                self.backgroundImageObject = backgroundObject;
                self.worldOrigin = (CGPoint){0,0};
                [self.gestureController addGestureHandler:self.gestureHandler];
            }
            [self updateTransform];
        });
    }
    self.renderView.paused = NO;
}

- (void) innerReset {
    [[MotionController sharedController] stopMotionDetection];
}

- (void) kill {
    if(self.targetGestureScrollView) {
        // restore scrollView gesture state
        self.targetGestureScrollView.panGestureRecognizer.enabled = YES;
        self.targetGestureScrollView.pinchGestureRecognizer.enabled = YES;
        self.targetGestureScrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
        [self.targetGestureScrollView.panGestureRecognizer removeTarget:self action:nil];
        [self.targetGestureScrollView.pinchGestureRecognizer removeTarget:self action:nil];
    }
    self.finalizedBlock = nil;
    self.snapShotBlock = nil;
    workerQueue = nil;
    [self.renderView tearDown];
    [[MotionController sharedController] stopMotionDetection];
    [self.renderTools removeAllObjects];
    [self.worldObjects removeAllObjects];
    self.surface = nil;
    self.gestureController = nil;
    GKRenderDispatch(YES, ^{
        [GKVertexArrayObject releaseStaticResources];
        [GKTextureHelper releaseCachedResources];
        [GLSLProgram releaseAllPrograms];
        [GLShaderProgram deleteAllShaderProgram];
    });
}

- (void) reset {
    [self.worldObjects removeAllObjects];
    [self innerReset];
    _worldObjectCount = 0;
    _worldObjectStartIndex = 0;
}

- (void) clear {}

#pragma mark <configurations>

- (void) setupControllers {
    if(!self.gestureController) {
        self.gestureController = [[GestureController alloc] initWithView:self.view];
        self.gestureController.flipY = YES;
        self.gestureController.delegate = self;
        if(self.worldBackgroundImageFilePath.length) {
            [self.gestureController addGestureHandler:self.gestureHandler];
        }
        [self deleteSavedTextures];
    }
}

- (void) deleteSavedTextures {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:GKTempTextureFolderName];
    if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void) updateProjectionMatrix {
    CGSize size = [self viewSize];
    GLKVector3 eye = self.viewCenter;
    defaultProjectionMatrix = GLKMatrix4MakeOrtho(-size.width/2, size.width/2, -size.height/2, size.height/2, 0.01, 100);
    cameraMatrix = GLKMatrix4MakeLookAt(eye.x,eye.y,1,eye.x,eye.y,0,0,1,0);
}

#pragma mark <transform updates>

- (void) setViewportOffset:(CGPoint)inOffset scale:(CGFloat)inScale {
    CGPoint offset = inOffset;
    CGFloat scale = inScale;
    CGFloat cropScaleModifier = 1.0/_cropScale*_viewPortMultiplier;
    offset.x = offset.x*cropScaleModifier+_cropOffset.x;
    offset.y = offset.y*cropScaleModifier+_cropOffset.y;
    scale *= _cropScale;
    self.worldOrigin = offset;
    self.worldScale = scale;
    __weak typeof(self) weakSelf = self;
    GKRenderDispatch(YES, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self updateTransform];
    });
}

- (CGSize) viewSize {
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    CGFloat newViewWidth = viewWidth/_worldScale*_viewPortMultiplier;
    CGFloat newViewHeigh = viewHeight/_worldScale*_viewPortMultiplier;
    return (CGSize){newViewWidth,newViewHeigh};
}

- (void) updateTransform {
    CGSize viewSize = [self viewSize];
    GLKVector3 eye = self.viewCenter;
    defaultProjectionMatrix = GLKMatrix4MakeOrtho(-viewSize.width/2, viewSize.width/2, -viewSize.height/2, viewSize.height/2, 0.01, 100);
    cameraMatrix = GLKMatrix4MakeLookAt(eye.x,eye.y,1,eye.x,eye.y,0,0,1,0);
    
    CGRect visibleRect;
    CGFloat minX = _viewportTopLeft.x-viewSize.width/2;
    CGFloat minY = _viewportTopLeft.y-viewSize.height-viewSize.height/2;
    CGFloat width = viewSize.width*2;
    CGFloat height = viewSize.height*2;
    visibleRect.origin = (CGPoint){minX,minY};
    visibleRect.size = (CGSize){width,height};
}

@end

@implementation GKRenderViewController (ScrollView)

- (void) transformScrollView:(UIScrollView *)scrollView intoOffset:(CGPoint *)outOffset scale:(CGFloat *)outScale {
    CGFloat scaleX = scrollView.contentSize.width/scrollView.bounds.size.width;
    CGFloat scaleY = scrollView.contentSize.height/scrollView.bounds.size.height;
    CGFloat scale = 1.0;
    switch(_worldMode) {
        case GKWorldFinite:
            scale = MIN(scaleX,scaleY);
            break;
        case GKWorldInfiniteHeight:
            scale = scaleX;
            break;
    }
    // prevent 0 or negative scale, incase that contentsize is zero
    if(scale <= 0) {
        scale = 1.0;
    }
    CGPoint offset = scrollView.contentOffset;
    offset.x *= _scrollContentOffsetRatio/scale;
    offset.y *= _scrollContentOffsetRatio/scale;
    *outOffset = offset;
    *outScale = scale;
}

- (void) updateViewportWithScrollView:(UIScrollView *)scrollView {
    CGPoint offset;
    CGFloat scale;
    [self transformScrollView:scrollView intoOffset:&offset scale:&scale];
    [self setViewportOffset:offset scale:scale];
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
    [self updateViewportWithScrollView:scrollView];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    hasZoom = YES;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    hasZoom = NO;
    if(!hasZoom && !hasDrag) {
        [self updateViewportWithScrollView:scrollView];
    }
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    hasDrag = YES;
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate) {
        hasDrag = NO;
        if(!hasZoom && !hasDrag) {
            [self updateViewportWithScrollView:scrollView];
        }
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    hasDrag = NO;
    if(!hasZoom && !hasDrag) {
        [self updateViewportWithScrollView:scrollView];
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateViewportWithScrollView:scrollView];
}

@end

@implementation GKRenderViewController (Delegation)

- (void) getWorldOrigin:(CGPoint *)origin scale:(CGFloat *)scale pointPerWorldPoint:(CGFloat *)ppp {
//    NSLog(@"viewport top left %@",NSStringFromCGPoint(_viewportTopLeft));
    *origin = _viewportTopLeft;
    *scale = _worldScale;
    *ppp = _viewPortMultiplier;
}

@end

@implementation GKConcreteGestureHandler {
    CGPoint _touchOffset;
    CGPoint _previousTouchPoint;
}

@synthesize worldScale;
@synthesize worldTopLeft;
@synthesize viewPointPerPoint;
@synthesize undoManager;

@synthesize gestureController;
@synthesize enabled;
@synthesize gestureEnabled;
@synthesize gestureActive;

- (void) handlePinchGesture:(UIPinchGestureRecognizer *)gesture location:(CGPoint)location {
    switch(gesture.state) {
        case UIGestureRecognizerStateBegan: {
            [self.controller startScale];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            //            NSLog(@"change scale %f",gesture.scale);
            //            NSLog(@"loc %@",NSStringFromCGPoint([gesture locationInView:self.controller.view]));
            [self.controller changeScaleRatio:gesture.scale atScreenPosiiton:[gesture locationInView:self.controller.view]];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            break;
        }
        default:
            break;
    }
    
}

- (void) handleDrawGesture:(GPDrawGestureRecognizer *)gesture location:(CGPoint)location center:(CGPoint)center {
    switch(gesture.state) {
        case UIGestureRecognizerStateBegan: {
            //            self.controller.worldOrigin = [self.controller screenToWorldOffset:[gesture locationInView:self.controller.view]];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            //            self.controller.worldOrigin = [self.controller screenToWorldOffset:[gesture locationInView:self.controller.view]];
            //            [self.controller screenToWorldOffset:[gesture locationInView:self.controller.view]];
            [self.controller accumulateOffset:[gesture diffInView:self.controller.view]];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            break;
        }
        default:
            break;
    }
}

- (void) longPressGestureRecognized:(UILongPressGestureRecognizer *)gesture location:(CGPoint)location {
    
}

- (void) touchBecomePrimaryTouch:(UITouch *)touch location:(CGPoint)location center:(CGPoint)center {
    CGPoint offset = CGPointZero;
    if(!CGPointEqualToPoint(CGPointZero, _previousTouchPoint)) {
        offset = (CGPoint) {
            _previousTouchPoint.x-center.x,
            _previousTouchPoint.y-center.y,
        };
    }
    _touchOffset = CGPointZero;
}

@end