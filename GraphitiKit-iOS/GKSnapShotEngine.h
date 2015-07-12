//
//  SnapShotEngine.h
//  Pods
//
//  Created by apple on 2/19/15.
//
//

#import <Foundation/Foundation.h>

extern NSString * GKStencilSnapShotFolderName;
extern NSString * GKSnapShotFolderName;
extern NSString * GKTempTextureFolderName;
extern NSString * GKSplatTextureFolderName;

@interface GKSnapShotEngine : NSObject

+ (NSString *) randomSnapShotName;
+ (NSString *) randomSnapShotNameWithName:(NSString *)stencilName;

+ (NSString *) stencilSnapShotFilePathWithFileName:(NSString *)fileName;
+ (NSString *) snapShotFilePathWithFileName:(NSString *)fileName;
+ (NSString *) tempTextureFilePathWithFileName:(NSString *)fileName;
+ (NSString *) splatFilePathWithFileName:(NSString *)fileName;

@end
