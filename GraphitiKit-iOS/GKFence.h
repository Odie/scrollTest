//
//  GKFence.h
//  Pods
//
//  Created by apple on 4/7/15.
//
//

#import <Foundation/Foundation.h>

@interface GKFence : NSObject
@property(nonatomic, readonly) BOOL isReady;
@property(nonatomic, readonly) BOOL isCompleted;

@property(nonatomic, readonly, strong) NSMutableArray *handlers;

-(void)insertFence;
@end
