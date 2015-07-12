//
//  GLDrawable.h
//  Graphiti-Prototype
//
//  Created by apple on 10/21/14.
//
//

@import GLKit;
@import Foundation;
#import "GKAudioControllerDelegate.h"
#import "GKComponent.h"
#import "GKTool.h"

@interface GKObject : NSObject <GKComponent>
- (void) update:(NSTimeInterval)deltaTime;
- (void) reset;

@end
