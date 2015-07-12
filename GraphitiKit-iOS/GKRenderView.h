//
//  GKRenderView.h
//  Pods
//
//  Created by apple on 3/12/15.
//
//

#import <UIKit/UIKit.h>

@class GKRenderView;

@protocol GKRenderViewDelegate <NSObject>
@required
- (void) update:(NSTimeInterval)deltaTime;
- (void) view:(GKRenderView *)view drawInRect:(CGRect)rect;
- (void) frameBufferReady;

@end

@interface GKRenderView : UIView
@property (readonly,nonatomic) EAGLContext *renderContext;
@property (nonatomic) CGFloat desiredFramePerSecond;
@property (nonatomic) BOOL paused;
@property (nonatomic,readonly) GLuint framebuffer;
@property (weak,nonatomic) id<GKRenderViewDelegate> delegate;
- (void) tearDown;
@end
