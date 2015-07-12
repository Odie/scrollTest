//
//  GKDripManager.h
//  Pods
//
//  Created by apple on 3/4/15.
//
//

#import <Foundation/Foundation.h>
#import "GKTool.h"
#import <GLKit/GLKit.h>

@interface GKDripManager : NSObject

@property (nonatomic,readonly) NSUInteger dripsProduced;
@property (nonatomic) DripSetting setting;

- (void) reset;
- (void) addDripAt:(GLKVector2)point withMultiplier:(CGFloat)value;
- (void) dissipate:(CGFloat)deltaTime;

@end