//
//  QuadraticLineBuilderStratergy.m
//  Graphiti-Prototype
//
//  Created by apple on 10/7/14.
//
//

#import "QuadraticPointTessellationStratergy.h"
#import "CGPointExtension.h"
#import "GPPointTracker.h"
#import "GraphitiKitMacros.h"

#define  QUADRATIC_DISTANCE_TOLERANCE 1.0

@interface QuadraticPointTessellationStratergy () {
    CGPoint previousMidPoint;
    CGPoint previousMidSpeed;
    NSUInteger seemPoint;
    GKTrackedPoint *points;
    GKTrackedPoint teselleStartPoint;
    GKTrackedPoint lastSeemPoint;
    NSUInteger pointArraySize;
}

@end

static inline CGPoint QuadraticPointInCurve(CGPoint start, CGPoint end, CGPoint controlPoint, CGFloat percent) {
    CGFloat a = pow((1.0 - percent), 2.0);
    CGFloat b = 2.0 * percent * (1.0 - percent);
    CGFloat c = pow(percent, 2.0);
    
    return (CGPoint) {
        a * start.x + b * controlPoint.x + c * end.x,
        a * start.y + b * controlPoint.y + c * end.y
    };
}

@implementation QuadraticPointTessellationStratergy

- (void) clear {
    if(points) {
        free(points);
        points = nil;
    }
    pointArraySize = 0;
}

- (void) dealloc {
    [self clear];
}

- (GKTrackedPoint) tessellateBegin:(GKTrackedPoint)point {
    [self clear];
    seemPoint = 1;
    teselleStartPoint = point;
    return point;
}

- (GKTrackedPoint *) tessellateTo:(GKTrackedPoint)endPoint count:(NSUInteger *)count {
    *count = 0;
    seemPoint++;
    NSAssert(seemPoint > 1,@"less than 1? forget to call begin!?!?!");
    CGPoint midPoint,midSpeed;
    if(seemPoint == 2) {
        midPoint = ccpMidpoint(teselleStartPoint.location, endPoint.location);
        midSpeed = ccpMidpoint(teselleStartPoint.velocity, endPoint.velocity);
//        GKLog(@"first mid point %@, %@ ---- %@",NSStringFromCGPoint(midPoint),NSStringFromCGPoint(teselleStartPoint.location), NSStringFromCGPoint(endPoint.location));
        [self setupPointArray:*count];
        points[(*count)].location = midPoint;
        points[(*count)].velocity = midSpeed;
        (*count)++;
    } else {
        midPoint = ccpMidpoint(lastSeemPoint.location, endPoint.location);
        midSpeed = ccpMidpoint(lastSeemPoint.velocity, endPoint.velocity);
        CGFloat distance = ccpDistance(previousMidPoint, midPoint);
//        GKLog(@"%@ ----- %@, c = %@",NSStringFromCGPoint(previousMidPoint),NSStringFromCGPoint(midPoint), NSStringFromCGPoint(lastSeemPoint.location));
        if(distance > QUADRATIC_DISTANCE_TOLERANCE) {
            unsigned int i;
            int segments = ceilf(distance / 1.0);
            for (i = 1; i < segments; i++) {
                float ratio = i/(float)segments;
                CGPoint quadPoint = QuadraticPointInCurve(previousMidPoint,
                                                          midPoint,
                                                          lastSeemPoint.location,
                                                          ratio);
                [self setupPointArray:*count];
                points[(*count)].location = quadPoint;
                points[(*count)].velocity = ccpLerp(previousMidSpeed, midSpeed, ratio);
                (*count)++;
            }
        } else {
            [self setupPointArray:*count];
            points[(*count)].location = midPoint;
            points[(*count)].velocity = midSpeed;
            (*count)++;
        }
    }
    previousMidPoint = midPoint;
    previousMidSpeed = midSpeed;
    lastSeemPoint = endPoint;
    return points;
}

//- (GPTrackedPoint *) tessellateFrom:(GPTrackedPoint)beginPoint to:(GPTrackedPoint)endPoint count:(NSUInteger *)count {
//    *count = 0;
//    seemPoint++;
//    lastSeemPoint = endPoint;
////    GKLog(@"%@ to %@",NSStringFromCGPoint(beginPoint.location),NSStringFromCGPoint(endPoint.location));
//    if(seemPoint >= 2) {
//        CGPoint p1 = beginPoint.location;
//        CGPoint p2 = endPoint.location;
//        CGPoint midPoint = ccpMidpoint(p1, p2);
//        CGPoint midSpeed = ccpMidpoint(beginPoint.velocity, endPoint.velocity);
//        CGFloat distance = ccpDistance(p1, p2);
//        
//        CGPoint startSpeed = previousMidSpeed;
//        if(seemPoint == 2) {
//            startSpeed = beginPoint.velocity;
//        }
//        GKLog(@"%@ ----- %@, c = %@",NSStringFromCGPoint(previousMidPoint),NSStringFromCGPoint(midPoint), NSStringFromCGPoint(p1));
//        if(distance > QUADRATIC_DISTANCE_TOLERANCE && seemPoint > 2) {
//            unsigned int i;
//            int segments = (int) distance / 1.5;
//            if(segments >= 512) {
//                NSLog(@"NOSADNFOAFNWEFSADF");
//            }
//            for (i = 1; i <= segments; i++) {
//                float ratio = i/(float)segments;
//                CGPoint quadPoint = QuadraticPointInCurve(previousMidPoint,
//                                                          midPoint,
//                                                          p1,
//                                                          ratio);
//                [self setupPointArray:*count];
////                if(ratio > 0.8) {
////                    GKLog(@"%ld %@",*count,NSStringFromCGPoint(quadPoint));
////                }
//                points[(*count)].location = quadPoint;
//                points[(*count)].velocity = ccpLerp(startSpeed, midSpeed, ratio);
//                (*count)++;
//            }
//        } else {
//            GKLog(@"%ld %@",*count,NSStringFromCGPoint(midPoint));
//            [self setupPointArray:*count];
//            points[(*count)].location = midPoint;
//            points[(*count)].velocity = midSpeed;
//            (*count)++;
//            [self setupPointArray:*count];
//            points[(*count)].location = midPoint;
//            points[(*count)].velocity = midSpeed;
//        }
//        previousMidPoint = midPoint;
//        previousMidSpeed = midSpeed;
//    }
//    return points;
//}

- (GKTrackedPoint) tessellateEnd {
    seemPoint++;
    if(seemPoint < 2) { // impossible??
        return (GKTrackedPoint){CGPointZero,CGPointZero};
    }
    if(points) {
        free(points);
        points = nil;
    }
    return lastSeemPoint;
}

- (void) setupPointArray:(NSUInteger) count {
    if(count >= pointArraySize) {
        if(pointArraySize == 0) {
            pointArraySize = 512;
        }
        points = realloc(points, sizeof(GKTrackedPoint)*pointArraySize*2);
        pointArraySize = pointArraySize*2;
    }
}

@end
