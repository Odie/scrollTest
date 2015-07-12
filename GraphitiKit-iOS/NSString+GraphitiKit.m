//
//  NSString+Utils.m
//  Graphiti-Prototype
//
//  Created by apple on 10/10/14.
//
//

#import "NSString+GraphitiKit.h"

#define VariableName(arg) (@""#arg)

@implementation NSString (GraphitiKit)

+ (NSString *)fullPathNameWithFileName:(NSString *)fileName inPathDirectory:(NSSearchPathDirectory)path {
    
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:path
                                                         inDomains:NSUserDomainMask] lastObject];
    NSString *documentsDirectory = url.path;
    NSString *documentsPath = [documentsDirectory
                               stringByAppendingPathComponent:fileName];
    return documentsPath;
}

+ (NSString *) stringFromFloat:(GLfloat) value {
    return [NSString stringWithFormat:@"%f",value];
}

+ (NSString *) stringFromInt:(int) value {
    return [NSString stringWithFormat:@"%i",value];
}

+ (NSString *) emitterNameFromValue:(int) value {
    NSString *emitterName = @"TypeGravity";
    if(value != 0) {
        emitterName = @"TypeRadial";
    }
    return emitterName;
}

+ (NSString *) stringFromBlendFunc:(int) value {
    switch(value) {
        case GL_ZERO:
            return VariableName(GL_ZERO);
        case GL_ONE:
            return VariableName(GL_ONE);
        case GL_SRC_COLOR:
            return VariableName(GL_SRC_COLOR);
        case GL_ONE_MINUS_SRC_COLOR:
            return VariableName(GL_ONE_MINUS_SRC_COLOR);
        case GL_SRC_ALPHA:
            return VariableName(GL_SRC_ALPHA);
        case GL_ONE_MINUS_SRC_ALPHA:
            return VariableName(GL_ONE_MINUS_SRC_ALPHA);
        case GL_DST_ALPHA:
            return VariableName(GL_DST_ALPHA);
        case GL_ONE_MINUS_DST_ALPHA:
            return VariableName(GL_ONE_MINUS_DST_ALPHA);
        case GL_DST_COLOR:
            return VariableName(GL_DST_COLOR);
        case GL_ONE_MINUS_DST_COLOR:
            return VariableName(GL_ONE_MINUS_DST_COLOR);
        case GL_SRC_ALPHA_SATURATE:
            return VariableName(GL_SRC_ALPHA_SATURATE);
        case GL_CONSTANT_COLOR:
            return VariableName(GL_CONSTANT_COLOR);
        case GL_ONE_MINUS_CONSTANT_COLOR:
            return VariableName(GL_ONE_MINUS_CONSTANT_COLOR);
        case GL_CONSTANT_ALPHA:
            return VariableName(GL_CONSTANT_ALPHA);
        case GL_ONE_MINUS_CONSTANT_ALPHA:
            return VariableName(GL_ONE_MINUS_CONSTANT_ALPHA);
        default:
            return @"UnKnown";
            
    }
}

@end
