//
//  GKDripManager.m
//  Pods
//
//  Created by apple on 3/4/15.
//
//

#import "GKDripManager.h"
#import "GraphitiKitMacros.h"

@interface GKDripManager () {
    NSMutableDictionary *_drips;
    Byte *_grid;
    NSUInteger _dripColumns;
    NSUInteger _dripRows;
    NSUInteger _dripCounts;
}
@end

@implementation GKDripManager

@synthesize dripsProduced = _dripProduced;

- (instancetype) init {
    self = [super init];
    if(self) {
        self.setting = (DripSetting){
            60,
            2,
            10,
            1,
            1,
        };
    }
    return self;
}

- (void) dealloc {
    if(_grid) {
        free(_grid);
    }
}

- (void) addDripAt:(GLKVector2)point withMultiplier:(CGFloat)value {
    int x = floorf(point.x);
    NSAssert(x < 4096, @"view with impossibly wide width detected");
    NSInteger key = floorf(point.y)*4096+x;
    NSNumber *numb = _drips[@(key)];
    if(!numb || [numb floatValue] < 0) {
        numb = @(_setting.dripRate*value);
    } else {
        numb = @(_setting.dripRate*value + [numb floatValue]);
    }
    _drips[@(key)] = numb;
}

- (void) dissipate:(CGFloat)deltaTime {
    __block NSUInteger dripProduced = 0;
    [_drips enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        CGFloat value = [obj floatValue];
        if(value > _setting.dripThreshold) {
            CGFloat numberOfDrip = ceilf(_setting.minDripCount + RANDOM_0_TO_1()*_setting.dripCountVariance);
            dripProduced += numberOfDrip;
            value -= numberOfDrip;
        }
        value = value - _setting.dripDissipateRate * deltaTime;
        _drips[key] = @(value);
    }];
    _dripProduced = dripProduced;
}

- (void) reset {
    if(!_drips) {
        _drips = [[NSMutableDictionary alloc] initWithCapacity:512];
    } else {
        [_drips removeAllObjects];
    }
}

@end
