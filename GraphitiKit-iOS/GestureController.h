//
//  GestureSystem.h
//  Graphiti-Prototype
//
//  Created by apple on 11/6/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GKComponentSystem.h"
#import "GPGestureHandlerDelegate.h"

@class GPDrawGestureRecognizer;
@class GestureController;

@protocol GestureControllerDelegate <NSObject>
@optional
-(void) controllerDidEndGesture:(GestureController *)controller;
-(void) controllerDidBeginGesture:(GestureController *)controller;
-(void) getWorldOrigin:(CGPoint *)origin scale:(CGFloat *)scale pointPerWorldPoint:(CGFloat *)ppp;
@end

@protocol GKDetectionStrategyDelegate <NSObject>

- (BOOL) shouldRecongizeGestureAtLocation:(CGPoint)location;

@end

@interface GestureController : GKComponentSystem
@property (weak,nonatomic) id<GestureControllerDelegate> delegate;
@property (weak,nonatomic) id<GKDetectionStrategyDelegate> stratergyDelegate;

@property (strong,nonatomic) GPDrawGestureRecognizer *drawGesture;

@property (nonatomic) BOOL disabled;
@property (nonatomic) BOOL oneFingerOnly;
@property (nonatomic) BOOL drawOnPress;
@property (nonatomic) BOOL flipY;
//@property (nonatomic) CGPoint worldOrigin;
//@property (nonatomic) CGFloat worldScale;
//@property (nonatomic) CGFloat pointPerWorldPoint;
@property (weak,nonatomic) UIView *otherInteractionView;
@property (strong,nonatomic) NSArray *otherGestures;
- (instancetype) initWithView:(UIView *)view;

-(void) addGestureHandler:(id<GPGestureHandlerDelegate>)delegate;
-(void) removeGestureHandler:(id<GPGestureHandlerDelegate>)delegate;

- (CGPoint) glLocationFromGesture:(UIGestureRecognizer *)gesture;
- (CGPoint) glLocationFromViewLocation:(CGPoint)location;

@end
