//
//  UIColor+HexColor.m
//  GraphitiKit-iOS
//
//  Created by apple on 12/24/14.
//  Copyright (c) 2014 Jason Chang. All rights reserved.
//

#import "UIColor+HexColor.h"
#import "UIColor+GraphitiKit.h"

@implementation UIColor (HexColor)

+(UIColor *)colorFromHexString:(NSString *)hexString {
    return [UIColor colorWithHexString:hexString];
}

+(NSString *)hexStringFromUIColor:(UIColor *)color {
    if (!color) {
        // aarrggbb
        return @"#ff000000";
    }
    
    if (color == [UIColor whiteColor]) {
        // Special case, as white doesn't fall into the RGB color space
        return @"#ffffffff";
    }
    
    CGFloat red;
    CGFloat blue;
    CGFloat green;
    CGFloat alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int redDec = (int)(red * 255);
    int greenDec = (int)(green * 255);
    int blueDec = (int)(blue * 255);
    int alphaDec = (int)(alpha * 255);
    
    NSString *returnString = [NSString stringWithFormat:@"#%02x%02x%02x%02x",(unsigned int)alphaDec, (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
    
    return returnString;
}

@end
