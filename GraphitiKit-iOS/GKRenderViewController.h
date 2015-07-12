//
//  GKRenderViewController.h
//  Pods
//
//  Created by apple on 3/13/15.
//
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "GKTool.h"
#import "GKSnapShotEngine.h"
#import "GKAudioControllerDelegate.h"
#import "GKRenderView.h"

#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, GKWorldMode) {
    GKWorldFinite,
    GKWorldInfiniteHeight,
};

@class GKRenderViewController;

@protocol GKRenderViewControllerDelegate <NSObject>
@end

@interface GKRenderViewController : UIViewController <GKRenderViewDelegate>

@property (weak,nonatomic) id<GKRenderViewControllerDelegate> delegate;

@property (nonatomic) BOOL disableGesture;
/*
 set world mode so we can calculate correct scale and aspect ratio
 */
@property (nonatomic) GKWorldMode worldMode;
/*
 set visible rect into the viewport when your visible area is not the same as the view's bound
 */
@property (nonatomic) CGRect visibleRect;
/*
 scale that are viewed as 1
 */
@property (nonatomic) CGFloat baseScale;
/*
 point per scrollView point
 */
@property (nonatomic) CGFloat scrollContentOffsetRatio;
/*
 Scale of the visible viewport base on GLKView's frame
 */
@property (nonatomic) CGFloat worldScale;
/*
 Origin of the visible viewport
 */
@property (nonatomic) CGPoint worldOrigin;
/*
 center of current visible surface in view's coordniate
 */
@property (readonly,nonatomic) GLKVector3 viewCenter;

@property (nonatomic) CGSize worldSize;

- (void) setWorldBackgroundImage:(UIImage *)image;

- (void) setupZoomLogicOnScrollView:(UIScrollView *)scrollView;

- (void) setViewportOffset:(CGPoint)offset scale:(CGFloat)scale;

- (void) clear; // clear will store command into the buffer
- (void) reset; // reset will not store anything and will wipe out undo/redo stack

- (void) kill; // kill off all resources on this viewcontroller

@end

@interface GKRenderViewController (ScrollView) <UIScrollViewDelegate>
- (void) updateViewportWithScrollView:(UIScrollView *)scrollView;
@end