//
//  GraphitiKitMacros.h
//  GraphitiKit
//
//  Created by apple on 11/17/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#ifndef GraphitiKit_GraphitiKitMacros_h
#define GraphitiKit_GraphitiKitMacros_h

#import <OpenGLES/ES2/glext.h>

//#ifdef DEBUG
//#define GKLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
//#else
//#define GKLog(...)
//#endif

#if DEBUG
#define GK_CHECK_GL_ERROR_DEBUG() __GK_CHECK_GL_ERROR_DEBUG(__FUNCTION__, __LINE__)
static inline void __GK_CHECK_GL_ERROR_DEBUG(const char *function, int line)
{
    NSCAssert([EAGLContext currentContext], @"GL context is not set.");
    
    GLenum error;
    while((error = glGetError())){
        switch(error){
            case GL_INVALID_ENUM: printf("OpenGL error GL_INVALID_ENUM detected at %s %d\n", function, line); break;
            case GL_INVALID_VALUE: printf("OpenGL error GL_INVALID_VALUE detected at %s %d\n", function, line); break;
            case GL_INVALID_OPERATION: printf("OpenGL error GL_INVALID_OPERATION detected at %s %d\n", function, line); break;
            case GL_INVALID_FRAMEBUFFER_OPERATION: printf("OpenGL error GL_INVALID_FRAMEBUFFER_OPERATION detected at %s %d\n", function, line); break;
            default: printf("OpenGL error 0x%04X detected at %s %d\n", error, function, line);
        }
    }
}
#else
#define GK_CHECK_GL_ERROR_DEBUG()
#endif

// Macro which returns a random value between -1 and 1
#define RANDOM_MINUS_1_TO_1() ((random() / (GLfloat)0x3fffffff )-1.0f)

// Macro which returns a random number between 0 and 1
#define RANDOM_0_TO_1() ((random() / (GLfloat)0x7fffffff ))

// Macro which converts degrees into radians
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

// Macro that allows you to clamp a value within the defined bounds
#define CLAMP(X, A, B) ((X < A) ? A : ((X > B) ? B : X))

// Macro converts hex to UIColor
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

static inline CGPoint ccpMin(CGPoint A, CGPoint B) {
    return (CGPoint){A.x > B.x ? B.x : A.x, A.y > B.y ? B.y : A.y};
}

static inline CGPoint ccpMax(CGPoint A, CGPoint B) {
    return (CGPoint){A.x < B.x ? B.x : A.x, A.y < B.y ? B.y : A.y};
}

static inline CGRect CGRectNormalizeWithMaxSize(CGRect rect,CGSize max) {
    CGRect newRect = rect;
    if(newRect.origin.x < 0) {
        newRect.size.width += newRect.origin.x;
        newRect.origin.x = 0;
    }
    if(newRect.origin.y < 0) {
        newRect.size.height += newRect.origin.y;
        newRect.origin.y = 0;
    }
    if(newRect.origin.y > max.height) {
        CGFloat diff = newRect.origin.y - max.height;
        newRect.size.height -= diff;
        newRect.origin.y = max.height;
    }
    if((newRect.origin.x + newRect.size.width) > max.width) {
        newRect.size.width = max.width - newRect.origin.x;
    }
    // flipped Y
    if(((max.height-newRect.origin.y) + newRect.size.height) > max.height) {
        newRect.size.height = max.height - (max.height-newRect.origin.y);
    }
    if(newRect.size.width < 0) {
        newRect.size.width = 0;
    } else if(newRect.size.width > max.width) {
        newRect.size.width = max.width;
    }
    if(newRect.size.height < 0) {
        newRect.size.height = 0;
    } else if(newRect.size.height > max.height) {
        newRect.size.height = max.height;
    }
    return newRect;
}

static inline void mergeRects(CGRect **rects,NSUInteger *count,NSUInteger maxSize) {
    if(*count <= 1) {
        return;
    }
    CGRect *bucket = malloc(sizeof(CGRect)*maxSize);
    NSUInteger bucketItemCount = 0;
    for(int i = 0; i < (*count); i++) {
        CGRect dripRect = (*rects)[i];
        if(i == 0) {
            bucket[bucketItemCount++] = dripRect;
        } else {
            NSUInteger bCount = bucketItemCount;
            bool addToBucket = true;
            for(int j = 0; j < bCount; j++) {
                CGRect target = bucket[j];
                if(CGRectIntersectsRect(dripRect, target)) {
                    target = CGRectUnion(target, dripRect);
                    bucket[j] = target;
                    addToBucket = false;
                }
            }
            if(addToBucket) {
                bucket[bucketItemCount++] = dripRect;
            }
        }
    }
    free(*rects);
    *rects = bucket;
    *count = bucketItemCount;
}

static inline NSMutableArray * mergeRectsArray(NSMutableArray *rects) {
    if(rects.count <= 1) {
        return rects;
    }
    NSMutableArray *bucket = [NSMutableArray array];
    for(int i = 0; i < rects.count; i++) {
        CGRect dripRect = [[rects objectAtIndex:i] CGRectValue];
        if(i == 0) {
            [bucket addObject:[NSValue valueWithCGRect:dripRect]];
        } else {
            NSUInteger bCount = bucket.count;
            BOOL addToBucket = YES;
            for(int j = 0; j < bCount; j++) {
                CGRect target = [[bucket objectAtIndex:j] CGRectValue];
                if(CGRectIntersectsRect(dripRect, target)) {
                    target = CGRectUnion(target, dripRect);
                    [bucket replaceObjectAtIndex:j withObject:[NSValue valueWithCGRect:target]];
                    addToBucket = NO;
                }
            }
            if(addToBucket) {
                [bucket addObject:[NSValue valueWithCGRect:dripRect]];
            }
        }
    }
    return bucket;
}


#endif
