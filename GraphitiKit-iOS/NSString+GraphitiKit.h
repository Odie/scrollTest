//
//  NSString+GraphitiKit.h
//  Graphiti-Prototype
//
//  Created by apple on 10/10/14.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NSString (GraphitiKit)

+ (NSString *) fullPathNameWithFileName:(NSString *)fileName inPathDirectory:(NSSearchPathDirectory)path;

@end
