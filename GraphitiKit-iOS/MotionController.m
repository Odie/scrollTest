//
//  MotionController.m
//  GraphitiKit
//
//  Created by apple on 11/18/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import "MotionController.h"

@interface MotionController ()
@property (strong,nonatomic) CMMotionManager *motionManager;
@property (strong,nonatomic) NSOperationQueue *motionQueue;
@end

@implementation MotionController

+ (instancetype) sharedController {
    static MotionController *_motionController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _motionController = [MotionController new];
    });
    return _motionController;
}

- (instancetype) init {
    self = [super init];
    if(self) {
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionQueue = [[NSOperationQueue alloc] init];
        self.motionQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void) restartMotionDetection {
    [self stopMotionDetection];
    [self startMotionDetection];
}

- (BOOL) startMotionDetection {
    if(!self.motionManager.isDeviceMotionAvailable) {
        return NO;
    }
    if(!self.motionManager.isDeviceMotionActive) {
        [self.motionManager setDeviceMotionUpdateInterval:0.5];
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:self.motionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(motion != nil && !strongSelf.referenceAttribute) {
                strongSelf.referenceAttribute = motion.attitude;
            }
            if(!strongSelf.referenceAttribute) {
                return;
            }
            CMAttitude *attitude = motion.attitude;
            if(strongSelf.referenceAttribute && attitude != strongSelf.referenceAttribute) {
                [attitude multiplyByInverseOfAttitude:strongSelf.referenceAttribute];
                strongSelf.pitch = attitude.pitch;
                strongSelf.roll = attitude.roll;
                strongSelf.yaw = attitude.yaw;
            }
        }];
    } else {
        self.referenceAttribute = nil;
    }
    return YES;
}

- (void) stopMotionDetection {
    [self.motionManager stopDeviceMotionUpdates];
    self.referenceAttribute = nil;
    self.pitch = 0;
    self.roll = 0;
    self.yaw = 0;
}

- (void) resetReference {
    if(self.motionManager.isDeviceMotionAvailable && self.motionManager.deviceMotion) {
        CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
        CMAttitude *attitude = deviceMotion.attitude;
        self.referenceAttribute = attitude;
    }
}

@end
