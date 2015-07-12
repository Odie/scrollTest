//
//  GPDrawGestureRecognizer.h
//  Graphiti-Prototype
//
//  Created by apple on 11/6/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GestureController.h"

@protocol GPDrawGestureRecognizerTouchEventDelegate <NSObject>
- (void) touchBecomePrimaryTouch:(UITouch *)touch location:(CGPoint)location;
@end

@interface GPDrawGestureRecognizer : UIGestureRecognizer

@property (weak,nonatomic) id<GKDetectionStrategyDelegate> strategyDelegate;
@property (nonatomic) BOOL oneFingerOnly;
@property (nonatomic) BOOL drawOnPress;
@property (weak,nonatomic) id<GPDrawGestureRecognizerTouchEventDelegate> touchEventDelegate;
-(CGPoint)velocityInView:(UIView *)view;
-(CGPoint)touchesCenterInView:(UIView *)view;
-(CGPoint)diffInView:(UIView *)view;
@end
