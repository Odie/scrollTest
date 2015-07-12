//
//  NSBundle+GraphitiKit.m
//  GraphitiKit
//
//  Created by apple on 11/17/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import "NSBundle+GraphitiKit.h"

@implementation NSBundle (GraphitiKit)

+ (NSString *)GKPathForResource:(NSString *)name ofType:(NSString *)ext {
    NSString *path;
    NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"GraphitiKit" ofType:@"framework"];
    NSBundle *bundle = [[NSBundle alloc] initWithPath:frameworkPath];
    if(bundle) {
        // try framework (if built as framework)
        path = [bundle pathForResource:name ofType:ext];
    } else {
        // try bundle (build through open source pod)
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"GraphitiKit-iOS" ofType:@"bundle"];
        bundle = [[NSBundle alloc] initWithPath:bundlePath];
        path = [bundle pathForResource:name ofType:ext];
    }
    if(!path) {
        // ttry the main bundle
        path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    }
    return path;
}

@end
