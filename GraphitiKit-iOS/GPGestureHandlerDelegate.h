//
//  GPGestureHandlerDelegate.h
//  Graphiti-Prototype
//
//  Created by apple on 11/6/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#ifndef Graphiti_Prototype_GPGestureHandlerDelegate_h
#define Graphiti_Prototype_GPGestureHandlerDelegate_h

#import <UIKit/UIKit.h>
#import "GKComponent.h"

@class GPDrawGestureRecognizer;

@protocol GPGestureHandlerDelegate <GKGestureComponent>

@property (readonly, nonatomic) BOOL gestureActive;

@optional

- (void) handlePinchGesture:(UIPinchGestureRecognizer *)gesture location:(CGPoint)location;
- (void) handleRotateGesture:(UIRotationGestureRecognizer *)gesture location:(CGPoint)location;
- (void) handleDrawGesture:(GPDrawGestureRecognizer *)gesture location:(CGPoint)location center:(CGPoint)center;
- (void) longPressGestureRecognized:(UILongPressGestureRecognizer *)gesture location:(CGPoint)location;
- (void) touchBecomePrimaryTouch:(UITouch *)touch location:(CGPoint)location center:(CGPoint)center;
@end

#endif
