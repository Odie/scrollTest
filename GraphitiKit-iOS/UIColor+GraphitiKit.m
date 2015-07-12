//
//  UIColor+Utils.m
//  Graphiti-Prototype
//
//  Created by apple on 10/10/14.
//
//

#import "UIColor+GraphitiKit.h"

@implementation UIColor (GraphitiKit)

+(UIColor *) colorFromVector4:(GLKVector4) vec {
    return [UIColor colorWithRed:vec.r green:vec.g blue:vec.b alpha:vec.a];
}

- (GLKVector4) vector4Color {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return (GLKVector4){red,green,blue,alpha};
}

+ (UIColor *) colorWithHexString:(NSString *) colorString alpha:(CGFloat) alpha {
    UIColor *color = [UIColor colorWithHexString:colorString];
    GLKVector4 v4Color = [color vector4Color];
    v4Color.a = alpha;
    return [UIColor colorFromVector4:v4Color];
}

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

+ (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

@end
