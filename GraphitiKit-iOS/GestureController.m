//
//  GestureSystem.m
//  Graphiti-Prototype
//
//  Created by apple on 11/6/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import "GestureController.h"
#import <UIKit/UIKit.h>
#import "GPDrawGestureRecognizer.h"
#import "GPGestureHandlerDelegate.h"

@interface GestureController () <UIGestureRecognizerDelegate,GPDrawGestureRecognizerTouchEventDelegate>
@property (strong,nonatomic) UIRotationGestureRecognizer *rotationGesture;
@property (strong,nonatomic) UIPinchGestureRecognizer *pinchGesture;
@property (strong,nonatomic) NSMutableArray *components;

@property (weak,nonatomic) UIView *controllerView;

@end

@implementation GestureController

- (void) setStratergyDelegate:(id<GKDetectionStrategyDelegate>)stratergyDelegate {
    self.drawGesture.strategyDelegate = stratergyDelegate;
}

- (void) setDisabled:(BOOL)disabled {
    _disabled = disabled;
    self.rotationGesture.enabled = !_disabled;
    self.pinchGesture.enabled = !_disabled;
    self.drawGesture.enabled = !_disabled;
}

- (instancetype) initWithView:(UIView *)view {
    self = [super init];
    if(self) {
        self.controllerView = view;
        self.rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureRecognized)];
        self.rotationGesture.delegate  = self;
        self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognized)];
        self.pinchGesture.delegate = self;
        self.drawGesture = [[GPDrawGestureRecognizer alloc] initWithTarget:self action:@selector(drawGestureRecognized)];
        self.drawGesture.delegate = self;
        self.drawGesture.touchEventDelegate = self;
        self.drawGesture.cancelsTouchesInView = NO;
        self.rotationGesture.cancelsTouchesInView = NO;
        self.pinchGesture.cancelsTouchesInView = NO;
        
        [view addGestureRecognizer:self.rotationGesture];
        [view addGestureRecognizer:self.pinchGesture];
        [view addGestureRecognizer:self.drawGesture];
    }
    return self;
}

-(void) dealloc {
    self.otherGestures = nil;
    if(self.controllerView) {
        [self.controllerView removeGestureRecognizer:self.rotationGesture];
        [self.controllerView removeGestureRecognizer:self.pinchGesture];
        [self.controllerView removeGestureRecognizer:self.drawGesture];
    }
}

-(void) addGestureHandler:(id<GPGestureHandlerDelegate>)delegate {
    if(!self.components) {
        self.components = [NSMutableArray array];
    }
    if([self.components containsObject:delegate]) {
        return;
    }
    [self.components addObject:delegate];
}

-(void) removeGestureHandler:(id<GPGestureHandlerDelegate>)delegate {
    [self.components removeObject:delegate];
}

-(void)rotationGestureRecognized {
    CGPoint origin;
    CGFloat scale;
    CGFloat ppp;
    [self.delegate getWorldOrigin:&origin scale:&scale pointPerWorldPoint:&ppp];
    UIRotationGestureRecognizer *gesture = self.rotationGesture;
    CGPoint location = [gesture locationInView:self.controllerView];
    location = viewToWorldPoint(location, origin,ppp/scale,self.flipY);
    [self.components enumerateObjectsUsingBlock:^(id<GPGestureHandlerDelegate> obj, NSUInteger idx, BOOL *stop) {
        if(obj.enabled && [obj respondsToSelector:@selector(handleRotateGesture:location:)]) {
            [obj handleRotateGesture:gesture location:location];
            if(gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateEnded) {
                [self setOtherGesturesEnabled:!obj.gestureActive];
            }
        }
    }];
}

-(void)pinchGestureRecognized {
    CGPoint origin;
    CGFloat scale;
    CGFloat ppp;
    [self.delegate getWorldOrigin:&origin scale:&scale pointPerWorldPoint:&ppp];
    UIPinchGestureRecognizer *gesture = self.pinchGesture;
    CGPoint location = [gesture locationInView:self.controllerView];
    location = viewToWorldPoint(location, origin,ppp/scale,self.flipY);
    [self.components enumerateObjectsUsingBlock:^(id<GPGestureHandlerDelegate> obj, NSUInteger idx, BOOL *stop) {
        if(obj.enabled && [obj respondsToSelector:@selector(handlePinchGesture:location:)]) {
            [obj handlePinchGesture:gesture location:location];
            if(gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateEnded) {
                [self setOtherGesturesEnabled:!obj.gestureActive];
            }
        }
    }];
}

CGPoint viewToWorldPoint(CGPoint point,CGPoint worldOrigin,CGFloat scale,BOOL flipY) {
    CGPoint newPos;
    newPos.x = worldOrigin.x + point.x*scale;
    if(flipY) {
        newPos.y = worldOrigin.y - point.y*scale;
    }
    return newPos;
}

- (void) setOtherGesturesEnabled:(BOOL)enabled {
    if(self.otherInteractionView) {
        for(UIGestureRecognizer *recognizer in self.otherInteractionView.gestureRecognizers) {
            recognizer.enabled = enabled;
        }
    }
}

- (CGPoint) glLocationFromViewLocation:(CGPoint)location {
    CGPoint origin;
    CGFloat scale;
    CGFloat ppp;
    [self.delegate getWorldOrigin:&origin scale:&scale pointPerWorldPoint:&ppp];
    return viewToWorldPoint(location,origin,ppp/scale,self.flipY);
}

- (CGPoint) glLocationFromGesture:(UIGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.controllerView];
    CGPoint origin;
    CGFloat scale;
    CGFloat ppp;
    [self.delegate getWorldOrigin:&origin scale:&scale pointPerWorldPoint:&ppp];
    CGPoint GLLocation = viewToWorldPoint(location,origin,ppp/scale,self.flipY);
    return GLLocation;
}

-(void)drawGestureRecognized {
    CGPoint origin;
    CGFloat scale;
    CGFloat ppp;
    [self.delegate getWorldOrigin:&origin scale:&scale pointPerWorldPoint:&ppp];
    
    GPDrawGestureRecognizer *gesture = self.drawGesture;
    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self setOtherGesturesEnabled:YES];
        if([self.delegate respondsToSelector:@selector(controllerDidEndGesture:)]) {
            [self.delegate controllerDidEndGesture:self];
        }
    } else if(gesture.state == UIGestureRecognizerStateBegan) {
        [self setOtherGesturesEnabled:NO];
        if([self.delegate respondsToSelector:@selector(controllerDidBeginGesture:)]) {
            [self.delegate controllerDidBeginGesture:self];
        }
    }
    
    CGPoint location = [gesture locationInView:self.controllerView];
    CGPoint gestureCenter = [gesture touchesCenterInView:self.controllerView];
    CGPoint GLLocation = viewToWorldPoint(location,origin,ppp/scale,self.flipY);
//    NSLog(@"%@ %@",NSStringFromCGPoint(location),NSStringFromCGPoint(GLLocation));
    gestureCenter = viewToWorldPoint(gestureCenter,origin,ppp/scale,self.flipY);
    [self.components enumerateObjectsUsingBlock:^(id<GPGestureHandlerDelegate> obj, NSUInteger idx, BOOL *stop) {
        if(obj.enabled && [obj respondsToSelector:@selector(handleDrawGesture:location:center:)]) {
            [obj handleDrawGesture:gesture location:GLLocation center:gestureCenter];
        }
    }];
}

- (void) setOneFingerOnly:(BOOL)oneFingerOnly {
    self.drawGesture.oneFingerOnly = oneFingerOnly;
}

- (BOOL) oneFingerOnly {
    return self.drawGesture.oneFingerOnly;
}

- (void) setDrawOnPress:(BOOL)drawOnPress {
    self.drawGesture.drawOnPress = drawOnPress;
}

- (BOOL) drawOnPress {
    return self.drawGesture.drawOnPress;
}

#pragma mark - gesture delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - touch event delegate

- (void) touchBecomePrimaryTouch:(UITouch *)touch location:(CGPoint)location {
    CGPoint origin;
    CGFloat scale;
    CGFloat ppp;
    [self.delegate getWorldOrigin:&origin scale:&scale pointPerWorldPoint:&ppp];
    CGPoint gestureCenter = [self.drawGesture touchesCenterInView:self.controllerView];
    location = viewToWorldPoint(location,origin,ppp/scale,self.flipY);
    gestureCenter = viewToWorldPoint(gestureCenter,origin,ppp/scale,self.flipY);
    [self.components enumerateObjectsUsingBlock:^(id<GPGestureHandlerDelegate> obj, NSUInteger idx, BOOL *stop) {
        if(obj.enabled && [obj respondsToSelector:@selector(touchBecomePrimaryTouch:location:center:)]) {
            [obj touchBecomePrimaryTouch:touch location:location center:gestureCenter];
        }
    }];
}

@end
