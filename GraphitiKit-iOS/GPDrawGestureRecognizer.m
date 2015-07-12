//
//  GPDrawGestureRecognizer.m
//  Graphiti-Prototype
//
//  Created by apple on 11/6/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import "GPDrawGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "CGPointExtension.h"

@interface GPDrawGestureRecognizer ()
@property (strong,nonatomic) NSMutableArray *touches;
@property (strong,nonatomic) UITouch *firstTouch;
@property (strong,nonatomic) UITouch *possibleFirstTouch;
@property (nonatomic) NSTimeInterval possibleTimeStamp;
@property (nonatomic) CGPoint lastLocation;
@property (nonatomic) NSTimeInterval lastTime;
@property (nonatomic) NSTimeInterval touchTimeStamp;
@property (nonatomic) CGPoint velocity;
@property (strong,nonatomic) NSTimer *pressTouchTimer;
@end

static const CGFloat pressFireInterval = 1/30.0f;

@implementation GPDrawGestureRecognizer

- (NSMutableArray *)touches {
    if(!_touches) {
        _touches = [NSMutableArray array];
    }
    return _touches;
}

-(CGPoint)velocityInView:(UIView *)view {
    return _velocity;
}

-(CGPoint)diffInView:(UIView *)view {
    CGPoint prev = [self.firstTouch previousLocationInView:view];
    CGPoint now = [self.firstTouch locationInView:view];
    return (CGPoint) {
        prev.x - now.x,
        prev.y - now.y,
    };
}

-(CGPoint)locationInView:(UIView *)view {
    return [self.firstTouch locationInView:view];
}

-(CGPoint)touchesCenterInView:(UIView *)view {
    if(self.touches.count > 1) {
        CGPoint point1 = [self.touches[0] locationInView:view];
        CGPoint point2 = [self.touches[1] locationInView:view];
        return (CGPoint){
            point1.x+(point2.x-point1.x)/2,
            point1.y+(point2.y-point1.y)/2,
        };
    }
    return [self locationInView:view];
}

- (void)reset {
    [super reset];
    [self.touches removeAllObjects];
    self.firstTouch = nil;
    self.possibleFirstTouch = nil;
    [self.pressTouchTimer invalidate];
    self.pressTouchTimer = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [touches enumerateObjectsUsingBlock:^(UITouch *obj, BOOL *stop) {
        [self.touches addObject:obj];
    }];
    if(!self.possibleFirstTouch && self.state == UIGestureRecognizerStatePossible) {
        self.possibleFirstTouch = self.touches.firstObject;
        self.possibleTimeStamp = self.possibleFirstTouch.timestamp;
        if(self.touches.count > 1) {
            CGPoint location = [self.touches.firstObject locationInView:self.view];
            BOOL shouldFail = YES;
            if([self.strategyDelegate respondsToSelector:@selector(shouldRecongizeGestureAtLocation:)]) {
                if([self.strategyDelegate shouldRecongizeGestureAtLocation:location]) {
                    shouldFail = NO;
                }
            }
            if(shouldFail) {
                [self.touches removeAllObjects];
                self.state = UIGestureRecognizerStateFailed;
            } else {
                [self activateGesture];
            }
            return;
        }
        self.state = UIGestureRecognizerStatePossible;
        self.touchTimeStamp = [[NSDate date] timeIntervalSince1970];
        [self.pressTouchTimer invalidate];
        self.pressTouchTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(determineDrawState) userInfo:nil repeats:YES];
        return;
    }
    
    if(self.state != UIGestureRecognizerStatePossible) {
        if(self.touches.count == 2) {
            CGPoint location = [self locationInView:self.view];
            if(self.touchEventDelegate && [self.touchEventDelegate respondsToSelector:@selector(touchBecomePrimaryTouch:location:)]) {
                [self.touchEventDelegate touchBecomePrimaryTouch:self.firstTouch location:location];
            }
        }
    }
}

- (void) fireTouchPressed {
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    CGFloat deltaT = timeStamp - self.touchTimeStamp;
    if(deltaT > pressFireInterval) {
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.state == UIGestureRecognizerStatePossible) {
        NSTimeInterval timeDiff = event.timestamp - self.possibleTimeStamp;
        if(timeDiff > 0.05) {
            [self determineDrawState];
        }
        return;
    }
    if(_drawOnPress) {
        self.touchTimeStamp = [[NSDate date] timeIntervalSince1970];
    }
    if([touches containsObject:self.firstTouch]) {
        self.state = UIGestureRecognizerStateChanged;
        CGPoint location = [self locationInView:self.view];
        CGFloat deltaT = self.firstTouch.timestamp - self.lastTime;
        CGFloat dx = location.x - self.lastLocation.x;
        CGFloat dy = self.lastLocation.y - location.y;
        // smooth the speed curve
        float lamda = 0.8;
        self.velocity = (CGPoint) {
            _velocity.x * (1-lamda) + dx/deltaT * lamda,
            _velocity.y * (1-lamda) + dy/deltaT * lamda
        };
        
        self.lastLocation = location;
        self.lastTime = self.firstTouch.timestamp;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self removeTouches:touches withEvent:event state:UIGestureRecognizerStateEnded];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self removeTouches:touches withEvent:event state:UIGestureRecognizerStateCancelled];
}

- (void) removeTouches:(NSSet *)touches withEvent:(UIEvent *)event state:(UIGestureRecognizerState)state {
    if(_drawOnPress || self.pressTouchTimer != nil) {
        [self.pressTouchTimer invalidate];
        self.pressTouchTimer = nil;
    }
    [touches enumerateObjectsUsingBlock:^(UITouch *obj, BOOL *stop) {
        [self.touches removeObject:obj];
    }];
    if(self.touches.count > 0 && self.state != UIGestureRecognizerStatePossible) {
        if(![self.touches containsObject:self.firstTouch]) {
            if(_oneFingerOnly) {
                [self.touches removeAllObjects];
            } else {
                self.firstTouch = self.touches[0];
                CGPoint location = [self.firstTouch locationInView:self.view];
                if(self.touchEventDelegate && [self.touchEventDelegate respondsToSelector:@selector(touchBecomePrimaryTouch:location:)]) {
                    [self.touchEventDelegate touchBecomePrimaryTouch:self.firstTouch location:location];
                }
            }
        } else {
            CGPoint location = [self.firstTouch locationInView:self.view];
            if(self.touchEventDelegate && [self.touchEventDelegate respondsToSelector:@selector(touchBecomePrimaryTouch:location:)]) {
                [self.touchEventDelegate touchBecomePrimaryTouch:self.firstTouch location:location];
            }
        }
    } else {
        self.possibleFirstTouch = nil;
        self.possibleTimeStamp = 0;
        self.state = state;
    }
}

- (void) determineDrawState {
    if(self.state == UIGestureRecognizerStatePossible) {
        BOOL shouldFail = YES;
        if(self.touches.count < 2) {
            shouldFail = NO;
        } else {
            CGPoint location = [self.touches.firstObject locationInView:self.view];
            if([self.strategyDelegate respondsToSelector:@selector(shouldRecongizeGestureAtLocation:)]) {
                if([self.strategyDelegate shouldRecongizeGestureAtLocation:location]) {
                    shouldFail = NO;
                }
            }
        }
        if(shouldFail) {
            [self.pressTouchTimer invalidate];
            self.pressTouchTimer = nil;
            self.possibleFirstTouch = nil;
            self.state = UIGestureRecognizerStateFailed;
        } else {
            [self activateGesture];
        }
    }
}

- (void) activateGesture {
    self.state = UIGestureRecognizerStateBegan;
    self.firstTouch = self.possibleFirstTouch;
    CGPoint location = [self locationInView:self.view];
    self.lastLocation = location;
    self.lastTime = self.firstTouch.timestamp;
    self.velocity = CGPointZero;
    if(self.touchEventDelegate && [self.touchEventDelegate respondsToSelector:@selector(touchBecomePrimaryTouch:location:)]) {
        [self.touchEventDelegate touchBecomePrimaryTouch:self.firstTouch location:location];
    }
    if(_drawOnPress && self.firstTouch) {
        self.touchTimeStamp = [[NSDate date] timeIntervalSince1970];
        [self.pressTouchTimer invalidate];
        self.pressTouchTimer = [NSTimer scheduledTimerWithTimeInterval:pressFireInterval target:self selector:@selector(fireTouchPressed) userInfo:nil repeats:YES];
    }
    self.possibleFirstTouch = nil;
}

@end