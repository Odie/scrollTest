//
//  UIView+Utils.h
//  Graphiti
//
//  Created by apple on 11/21/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Utils)

+ (UINib *) defaultNib;
+ (instancetype) viewFromNibWithName:(NSString *) nibName index:(NSUInteger) index;

@end
