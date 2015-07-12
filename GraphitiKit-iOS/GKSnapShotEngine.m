//
//  SnapShotEngine.m
//  Pods
//
//  Created by apple on 2/19/15.
//
//

#import "GKSnapShotEngine.h"

NSString * GKStencilSnapShotFolderName = @"stencils";
NSString * GKSnapShotFolderName = @"snapshots";
NSString * GKTempTextureFolderName = @"tempTextures";
NSString * GKSplatTextureFolderName = @"splatTextures";

@implementation GKSnapShotEngine

+ (NSString *) randomSnapShotName {
    return [NSString stringWithFormat:@"snapshot_%@.png",[[NSUUID UUID] UUIDString]];
}

+ (NSString *) randomSnapShotNameWithName:(NSString *)stencilName {
    NSString *name = [stencilName stringByDeletingPathExtension];
    return [NSString stringWithFormat:@"%@_%@.png",name,[[NSUUID UUID] UUIDString]];
}

+ (NSString *) stencilSnapShotFilePathWithFileName:(NSString *)fileName {
    return [self tempPathWithFolderName:GKStencilSnapShotFolderName fileName:fileName];
}

+ (NSString *) snapShotFilePathWithFileName:(NSString *)fileName {
    return [self tempPathWithFolderName:GKSnapShotFolderName fileName:fileName];
}

+ (NSString *) tempTextureFilePathWithFileName:(NSString *)fileName {
    return [self tempPathWithFolderName:GKTempTextureFolderName fileName:fileName];
}

+ (NSString *) splatFilePathWithFileName:(NSString *)fileName {
    return [self tempPathWithFolderName:GKSplatTextureFolderName fileName:fileName];
}


+ (NSString *) tempPathWithFolderName:(NSString *)folderName fileName:(NSString *)fileName {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:folderName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [path stringByAppendingPathComponent:fileName];
}

@end
