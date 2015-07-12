#import "GPPointTracker.h"
#import "GPDrawGestureRecognizer.h"
#import "GraphitiKitMacros.h"

@interface GPPointTracker () {
    GKTrackedPoint previousTrackedPoint;
    NSUInteger pointIndex;
    NSTimeInterval previousEventTimestamp;
}
@property (strong, nonatomic) NSMutableArray *observers;
@end

@implementation GPPointTracker {
    BOOL _began;
}

- (id) initWithStrategy:(id<PointTessellationStrategy>)strategy {
    self = [super init];
    if (!self) {
        return nil;
    }
    _velocitySmoothRatio = 0.0;
    self.tessellationStrategy = strategy;
    return self;
}

- (instancetype) init {
    return [self initWithStrategy:nil];
}

- (void) clear {
    pointIndex = 0;
}

- (NSUInteger) count {
    return pointIndex;
}

- (NSMutableArray *) observers {
    if(!_observers) {
        _observers = [[NSMutableArray alloc] initWithCapacity:6];
    }
    return _observers;
}

- (void) addObserver:(id<GPPointTrackerObserver>)observer {
    if(observer && [observer conformsToProtocol:@protocol(GPPointTrackerObserver)]) {
        [self.observers addObject:observer];
    }
}

- (void) removeObserver:(id<GPPointTrackerObserver>)observer {
    if(observer) {
        [self.observers removeObject:observer];
    } else {
        [self.observers removeAllObjects];
    }
}

- (void) begin {
    _began = YES;
    [self clear];
    [self.weakObserver didBeginTrackingOnTracker:self];
    __weak typeof(self) weakSelf = self;
    [self.observers enumerateObjectsUsingBlock:^(id<GPPointTrackerObserver> observer, NSUInteger idx, BOOL *stop) {
        [observer didBeginTrackingOnTracker:weakSelf];
    }];
}

- (void) end {
    _began = NO;
    __weak typeof(self) weakSelf = self;
    [self.weakObserver didEndTrackingOnTracker:self];
    [self.observers enumerateObjectsUsingBlock:^(id<GPPointTrackerObserver> observer, NSUInteger idx, BOOL *stop) {
        [observer didEndTrackingOnTracker:weakSelf];
    }];
}

- (void) addPoint:(CGPoint)point velocity:(CGPoint)velocity {
    if(!_began) {
        return;
    }
    if(self.tessellationStrategy) {
        if(pointIndex == 0) { // starting tesellation
            GKTrackedPoint tesellatedPoint = [self.tessellationStrategy tessellateBegin:(GKTrackedPoint){point,velocity}];
            [self _addPoint:tesellatedPoint.location velocity:tesellatedPoint.velocity];
        } else { // have points in the array already
            NSUInteger tesellatedPointsCount = 0;
            GKTrackedPoint *tesellatedPoints;
            tesellatedPoints = [self.tessellationStrategy tessellateTo:(GKTrackedPoint){point,velocity} count:&tesellatedPointsCount];
            for(int i = 0; i < tesellatedPointsCount; i++) {
                [self _addPoint: tesellatedPoints[i].location velocity:tesellatedPoints[i].velocity];
            }
        }
    } else {
        [self _addPoint:point velocity:velocity];
    }
}

- (void) _addPoint:(CGPoint)point velocity:(CGPoint)velocity {
    __weak typeof(self) weakSelf = self;
    [self.weakObserver tracker:self didAddedPoint:point velocity:velocity index:pointIndex];
    [self.observers enumerateObjectsUsingBlock:^(id<GPPointTrackerObserver> observer, NSUInteger idx, BOOL *stop) {
        [observer tracker:weakSelf didAddedPoint:point velocity:velocity index:pointIndex];
    }];
    pointIndex++;
}

@end

