//
//  GKDrawAwareObject.m
//  Pods
//
//  Created by apple on 2/12/15.
//
//

#import "GKDrawGestureAwareObject.h"

#import "GPDrawGestureRecognizer.h"
#import "GPPointTracker.h"
#import "QuadraticPointTessellationStratergy.h"
#import "GestureController.h"

@interface GKDrawGestureAwareObject ()
@property (nonatomic,strong) GPPointTracker *tracker;
@end

@implementation GKDrawGestureAwareObject

@synthesize enabled = _enabled;
@synthesize gestureActive;

- (instancetype) initWithGestureController:(GestureController *)controller {
    self = [super init];
    if (self) {
        self.tracker = [[GPPointTracker alloc] initWithStrategy:[QuadraticPointTessellationStratergy new]];
        self.gestureController = controller;
        self.tracker.weakObserver = self;
    }
    return self;
}

- (void) dealloc {
    self.enabled = NO;
}

- (void) setEnabled:(BOOL)enabled {
    if(_enabled != enabled) {
        _enabled = enabled;
    }
    self.gestureEnabled = enabled;
}

#pragma mark <GPGestureHandlerDelegate>

@synthesize gestureEnabled = _gestureEnabled;
@synthesize gestureController;

- (void) setGestureEnabled:(BOOL)gestureEnabled {
    if(_gestureEnabled != gestureEnabled) {
        _gestureEnabled = gestureEnabled;
        if(_gestureEnabled) {
            [self.gestureController addGestureHandler:self];
        } else {
            [self.gestureController removeGestureHandler:self];
        }
    }
}

- (void) handleDrawGesture:(GPDrawGestureRecognizer *)gesture location:(CGPoint)location center:(CGPoint)center {
    switch(gesture.state) {
        case UIGestureRecognizerStateBegan: {
            [self.tracker begin];
            [self.tracker addPoint:location velocity:CGPointZero];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint velocity = [gesture velocityInView:gesture.view];
            [self.tracker addPoint:location velocity:velocity];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            CGPoint velocity = [gesture velocityInView:gesture.view];
            [self.tracker addPoint:location velocity:velocity];
            [self.tracker end];
            break;
        }
        default:
            break;
    }
}

#pragma mark <GPPointTrackerObserver>

- (void)didBeginTrackingOnTracker:(GPPointTracker *)tracker {}
- (void)tracker:(GPPointTracker *)tracker didAddedPoint:(CGPoint)point velocity:(CGPoint)velocity index:(NSUInteger) index {}
- (void)didEndTrackingOnTracker:(GPPointTracker *)tracker {}

@end
