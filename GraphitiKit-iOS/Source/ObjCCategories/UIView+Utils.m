//
//  UIView+Utils.m
//  Graphiti
//
//  Created by apple on 11/21/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import "UIView+Utils.h"

@implementation UIView (Utils)

+ (UINib *) defaultNib {
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
}

+ (instancetype) viewFromNibWithName:(NSString *) nibName index:(NSUInteger) index {
    if(!nibName) {
        nibName = NSStringFromClass([self class]);
    }
    return [[UINib nibWithNibName: nibName bundle:nil] instantiateWithOwner: nil options: nil][index];
}

@end
