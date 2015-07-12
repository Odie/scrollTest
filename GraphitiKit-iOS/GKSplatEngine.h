//
//  GKSplatEngine.h
//  Pods
//
//  Created by apple on 2/20/15.
//
//

#import <Foundation/Foundation.h>

@class GKGeometryObject;

@interface GKSplat : NSObject
@property (readonly,nonatomic) CGRect frame;
@property (nonatomic) CGRect rect;
@property (strong,nonatomic) NSString *imagePath;
@end

@interface GKSplatEngine : NSObject

@property (nonatomic) CGFloat worldBaseScale;
@property (nonatomic) CGFloat screenHeight;
@property (nonatomic) CGFloat splatImageScale;

+ (instancetype) defaultEngine;
+ (void) removeAllSplatFiles;

- (void) mergeSplat:(GKSplat *)splat withGeometryObject:(GKGeometryObject *)geoObject;
- (void) beginMergeSplat:(GKSplat *)splat;
- (void) addGeometryObject:(GKGeometryObject *)geoObject;
- (void) endMergeSplat:(GKSplat *)splat;

@end
