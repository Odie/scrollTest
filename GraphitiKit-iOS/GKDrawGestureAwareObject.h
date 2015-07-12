//
//  GKDrawAwareObject.h
//  Pods
//
//  Created by apple on 2/12/15.
//
//

#import "GKObject.h"
#import "GPGestureHandlerDelegate.h"
#import "GPPointTracker.h"

@class GestureController;

@interface GKDrawGestureAwareObject : GKObject <GPGestureHandlerDelegate,GPPointTrackerObserver>

- (instancetype) initWithGestureController:(GestureController *)controller NS_DESIGNATED_INITIALIZER;

@end
