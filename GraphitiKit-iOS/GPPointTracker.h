#import <Foundation/Foundation.h>
#import "GKComponent.h"

typedef struct {
    CGPoint location;
    CGPoint velocity;
} GKTrackedPoint;

@class GPPointTracker;

@protocol GPPointTrackerObserver <NSObject>
- (void)didBeginTrackingOnTracker:(GPPointTracker *)tracker;
- (void)tracker:(GPPointTracker *)tracker didAddedPoint:(CGPoint)point velocity:(CGPoint)velocity index:(NSUInteger) index;
- (void)didEndTrackingOnTracker:(GPPointTracker *)tracker;
@end

@protocol PointTessellationStrategy <NSObject>
- (GKTrackedPoint) tessellateBegin:(GKTrackedPoint)point;
- (GKTrackedPoint *) tessellateTo:(GKTrackedPoint)endPoint count:(NSUInteger *)count;
- (GKTrackedPoint) tessellateEnd;
@end

@interface GPPointTracker : NSObject

@property (strong,nonatomic) id<PointTessellationStrategy> tessellationStrategy;
@property (nonatomic) CGFloat velocitySmoothRatio; // 0 = none, // 1 = always previous velocity
@property (weak,nonatomic) id<GPPointTrackerObserver> weakObserver;

- (id) initWithStrategy:(id<PointTessellationStrategy>)strategy;

- (void) addObserver:(id<GPPointTrackerObserver>)observer;
- (void) removeObserver:(id<GPPointTrackerObserver>)observer;

- (void) clear;

- (void) begin;
- (void) addPoint:(CGPoint)point velocity:(CGPoint)velocity;
- (void) end;

@end