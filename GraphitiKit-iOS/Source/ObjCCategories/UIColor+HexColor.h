//
//  UIColor+HexColor.h
//  GraphitiKit-iOS
//
//  Created by apple on 12/24/14.
//  Copyright (c) 2014 Jason Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexColor)

+(UIColor *)colorFromHexString:(NSString *)hexString;
+(NSString *)hexStringFromUIColor:(UIColor *)color;

@end
