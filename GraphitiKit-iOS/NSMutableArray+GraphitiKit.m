//
//  NSMutableArray+GraphitiKit.m
//  Pods
//
//  Created by apple on 3/6/15.
//
//

#import "NSMutableArray+GraphitiKit.h"

@implementation NSMutableArray (GraphitiKit)

- (id) objectOrNullAtIndex:(NSUInteger)index {
    if(self.count <= index) {
        NSInteger loopCount = (index+1)-self.count;
        while(loopCount > 0) {
            loopCount--;
            [self addObject:NSNull.null];
        }
    }
    return [self objectAtIndex:index];
}

@end
