//
//  UIScreen+Utils.m
//  Graphiti-Prototype
//
//  Created by apple on 11/3/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import "UIScreen+GraphitiKit.h"

@implementation UIScreen (GraphitiKit)

+ (CGFloat) kitHardwareScreenScale {
    CGFloat scale = [UIScreen mainScreen].scale;
    if([[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)]) {
        scale = [UIScreen mainScreen].nativeScale;
    }
    return scale;
}

@end
