//
//  EAGLContextStack.h
//  Pods
//
//  Created by apple on 3/12/15.
//
//

#import <Foundation/Foundation.h>

@interface EAGLContextStack : NSObject
- (BOOL)pushCurrentContext:(EAGLContext *)context;
- (void)popCurrentContext;
@end
