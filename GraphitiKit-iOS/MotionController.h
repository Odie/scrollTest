//
//  MotionController.h
//  GraphitiKit
//
//  Created by apple on 11/18/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

@interface MotionController : NSObject

@property (strong,nonatomic) CMAttitude *referenceAttribute;
@property (nonatomic) CGFloat pitch;
@property (nonatomic) CGFloat roll;
@property (nonatomic) CGFloat yaw;

+ (instancetype) sharedController;

- (void) restartMotionDetection;
- (BOOL) startMotionDetection;
- (void) stopMotionDetection;
- (void) resetReference;

@end
