//
//  UIColor+GraphitiKit.h
//  Graphiti-Prototype
//
//  Created by apple on 10/10/14.
//
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface UIColor (GraphitiKit)

+ (UIColor *) colorWithHexString:(NSString *) colorString alpha:(CGFloat) alpha;
+ (UIColor *) colorWithHexString:(NSString *) hexString;

+ (UIColor *) colorFromVector4:(GLKVector4) vec;
- (GLKVector4) vector4Color;

@end
