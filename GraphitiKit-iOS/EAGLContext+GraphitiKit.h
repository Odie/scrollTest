//
//  EAGLContext+Utils.h
//  Graphiti-Prototype
//
//  Created by apple on 11/6/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface EAGLContext (GraphitiKit)

+ (EAGLRenderingAPI) highestSupportedAPI;
- (BOOL) hasExtension:(NSString *)extensionName;
- (NSString *) supportedExtensionStrings;

@end
