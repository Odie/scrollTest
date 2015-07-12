//
//  EAGLContextStack.m
//  Pods
//
//  Created by apple on 3/12/15.
//
//

#import "EAGLContextStack.h"

@interface EAGLContextStack ()
@property (nonatomic, strong) NSMutableArray *contextStack;
@end

@implementation EAGLContextStack

- (instancetype)init {
    self = [super init];
    if(self != nil) {
        self.contextStack = [[NSMutableArray alloc] initWithCapacity:2];
    }
    return self;
}

- (BOOL)pushCurrentContext:(EAGLContext *)newContext {
    EAGLContext *context = EAGLContext.currentContext;
    if(context == nil) {
        context = (EAGLContext *)NSNull.null;
    }
    
    BOOL success = [EAGLContext setCurrentContext:newContext];
    if(!success) {
        return NO;
    }
    [self.contextStack addObject:context];
    return YES;
}

- (void)popCurrentContext {
    if(!self.contextStack.count) {
        return;
    }
    
    EAGLContext *context = self.contextStack.lastObject;
    [self.contextStack removeLastObject];
    if([NSNull.null isEqual:context]) {
        context = nil;
    }    
    [EAGLContext setCurrentContext:context];
}
@end
