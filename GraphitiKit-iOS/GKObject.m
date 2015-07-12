//
//  GLDrawable.m
//  Graphiti-Prototype
//
//  Created by apple on 10/21/14.
//
//

#import "GKObject.h"

@implementation GKObject
@synthesize enabled;
@synthesize worldTopLeft;
@synthesize worldScale;
@synthesize undoManager;
@synthesize viewPointPerPoint;
- (void) update:(NSTimeInterval)deltaTime {}
- (void) reset {}
@end
