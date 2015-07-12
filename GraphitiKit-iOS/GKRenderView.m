//
//  GKRenderView.m
//  Pods
//
//  Created by apple on 3/12/15.
//
//

#import "GKRenderView.h"
#import "EAGLContext+GraphitiKit.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#import "UIScreen+GraphitiKit.h"
#import "GKFence.h"
#import "GKTextureHelper.h"
#import "GKRenderDispatcher+Private.h"

//#define GK_DISPATCH_IN_THREAD

@interface GKRenderView ()
@property (nonatomic, strong) CADisplayLink* displayLink;
@end

@implementation GKRenderView {
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    CFTimeInterval timeSinceLastUpdate;
    CFTimeInterval lastDisplayTime;
    EAGLContext *_renderContext;
#ifdef GK_DISPATCH_IN_THREAD
    NSThread *_runningThread;
    BOOL _killThread;
#endif
}

@synthesize renderContext = _renderContext;

- (GLuint) framebuffer {
    return _frameBuffer;
}

- (void) dealloc {
    [self tearDown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.delegate = nil;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setup];
    }
    return self;
}

- (void) tearDown {
    self.delegate = nil;
    [self stopRunLoop];
    [self tearDownGL];
}

- (void) setup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    _desiredFramePerSecond = 30.0;
    _renderContext = GKRenderDispatchSetupGL([EAGLContext highestSupportedAPI], nil);
    self.multipleTouchEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    CGFloat scale = [UIScreen kitHardwareScreenScale];
    CGSize size = self.bounds.size;
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    layer.frame = CGRectMake(0.0, 0.0, size.width, size.height);
    layer.opaque = NO;
    layer.contentsScale = scale;
    layer.drawableProperties = @{
                                 kEAGLDrawablePropertyRetainedBacking: @NO,
                                 kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
                                 };
    
    __weak typeof(self) weakSelf = self;
    GKRenderDispatch(YES, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        GKFence *fence = [[GKFence alloc] init];
        [fence insertFence];
        [fence.handlers addObject:^{
            [strongSelf.delegate frameBufferReady];
        }];
        GLuint colorRenderBuffer;
        glGenRenderbuffers(1, &colorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
        [strongSelf->_renderContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
        strongSelf->_frameBuffer = framebuffer;
        strongSelf->_colorRenderBuffer = colorRenderBuffer;
        glViewport(0, 0, size.width*scale, size.height*scale);
        if(fence.isCompleted) {
            for(dispatch_block_t handler in fence.handlers) handler();
            [fence.handlers removeAllObjects];
        }
    });
    [self startRunLoop];
}

- (void) layoutSubviews {
    [super layoutSubviews];
}

-(void)resizeFromLayer:(CAEAGLLayer *)layer
{
    [self stopRunLoop];
    CGFloat scale = [UIScreen kitHardwareScreenScale];
    CGSize size = layer.frame.size;
    __weak typeof(self) weakSelf = self;
    GKRenderDispatch(YES, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf tearDownGL];
        GKFence *fence = [[GKFence alloc] init];
        [fence insertFence];
        [fence.handlers addObject:^{
            [strongSelf.delegate frameBufferReady];
            [strongSelf startRunLoop];
        }];
        GLuint colorRenderBuffer;
        glGenRenderbuffers(1, &colorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
        [strongSelf->_renderContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
        strongSelf->_frameBuffer = framebuffer;
        strongSelf->_colorRenderBuffer = colorRenderBuffer;
        glViewport(0, 0, size.width*scale, size.height*scale);
        if(fence.isCompleted) {
            for(dispatch_block_t handler in fence.handlers) handler();
            [fence.handlers removeAllObjects];
        }
    });
}

- (void)runMainLoop:(CADisplayLink *)displayLink {
    if(_paused || _frameBuffer == 0 || _colorRenderBuffer == 0) {
        return;
    }
    if (!GKRenderDispatchBeginFrame()) {
        return;
    }
    if(lastDisplayTime == 0) {
        timeSinceLastUpdate = 0;
    } else {
        timeSinceLastUpdate = _displayLink.timestamp - lastDisplayTime;
        timeSinceLastUpdate = MAX(0,timeSinceLastUpdate);
    }
    lastDisplayTime = _displayLink.timestamp;
    __weak typeof(self) weakSelf = self;
    GKRenderDispatchCommitFrame(YES, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if(self->_paused) {
            return;
        }
        [self update:timeSinceLastUpdate];
        [self render];
        if(self->_paused) {
            return;
        }
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
        [_renderContext presentRenderbuffer:_colorRenderBuffer];
    });
}

- (void) update:(CFTimeInterval)deltaTime {
    [self.delegate update:deltaTime];
}

- (void) render {
    [self.delegate view:self drawInRect:self.bounds];
}

#pragma mark - render loop management

- (void) startRunLoop {
    [self stopRunLoop];
    NSInteger interval = floor(60.0/_desiredFramePerSecond);
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(runMainLoop:)];
    [displayLink setFrameInterval:interval];
    self.displayLink = displayLink;
#ifdef GK_DISPATCH_IN_THREAD
    _runningThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMainLoop:) object:displayLink];
    [_runningThread start];
#else
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
#endif
}

- (void) stopRunLoop {
    [_displayLink invalidate];
    _displayLink = nil;
#ifdef GK_DISPATCH_IN_THREAD
    [_runningThread cancel];
    _runningThread = nil;
#endif
}

#pragma mark - opengl lifecycle

- (void) tearDownGL {
    GLuint renderBuffer = _colorRenderBuffer;
    GLuint frameBuffer = _frameBuffer;
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
    GKRenderDispatch(YES, ^{
        if(renderBuffer) {
            glDeleteRenderbuffers(1, &renderBuffer);
        }
        if(frameBuffer) {
            glDeleteFramebuffers(1, &frameBuffer);
        }
    });
}

#pragma mark - threaded mode

- (void) threadMainLoop:(CADisplayLink *)displayLink {
    @autoreleasepool {
        if(displayLink) {
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            // start the run loop
            [[NSRunLoop currentRunLoop] run];
        }
    }
}

#pragma mark - application state observer

- (void) appWillBecomeActive:(NSNotification *)notification {
    _paused = NO;
    if(_renderContext != nil && _frameBuffer != 0) {
        [self startRunLoop];
    }
}

- (void) appWillResignActive:(NSNotification *)notification {
    _paused = YES;
    [self stopRunLoop];
}

@end
