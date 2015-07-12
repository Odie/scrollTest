//
//  NSBundle+GraphitiKit.h
//  GraphitiKit
//
//  Created by apple on 11/17/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (GraphitiKit)

+ (NSString *)GKPathForResource:(NSString *)name ofType:(NSString *)ext;

@end
