//
//  GKTextureHelper.h
//  Pods
//
//  Created by apple on 1/21/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <GLKit/GLKit.h>

@class GKTexture;

typedef void(^textureLoadBlock)(GKTexture *texture, NSError *error);

@interface GKTexture : NSObject {
@public
    GLuint textureName;
    CVPixelBufferRef pixelBuffer;
    CVOpenGLESTextureRef cvOpenGLESTexture;

    GLuint width;
    GLuint height;
    BOOL hasAlpha;
    BOOL premultiplied;
}

- (void) updateDataWith:(UIImage *)image bitmapInfo:(CGBitmapInfo)bitmapInfo;
- (void) updateDataWith:(GLbyte *)imageData rect:(CGRect)rect;
- (void) updateDataWithData:(CFDataRef) dataRef rect:(CGRect)rect;

@end

@interface GKTextureHelper : NSObject

@property (nonatomic) NSInteger pendingSavginTextureCount;

+ (instancetype) sharedTextureHelper;

+ (dispatch_queue_t) textureWorkerQueue;
+ (BOOL)supportsFastTextureUpload;
+ (void) releaseCachedResources;
+ (void) setupBackgroundContextWithAPI:(EAGLRenderingAPI) api shareGroup:(EAGLSharegroup *)shareGroup;
/*
 delete texture base on cache size used, not implemented
 */
+ (void) setGLTextureCacheSize:(NSUInteger)cacheSize;

+ (GKTexture *) createTextureWithSize:(CGSize) textureSize context:(EAGLContext *)context;
+ (GKTexture *) createTextureWithSize:(CGSize)size filePath:(NSString **)textureFilePath;

+ (void) saveBytes:(GLubyte *)data length:(NSUInteger) length textureSize:(CGSize)size toPath:(NSString *)path completed:(void(^)(NSString *))completedBlock;

// load texture

+ (GKTexture *) loadTextureFromFilePath:(NSString *)filePath error:(NSError **)error;
+ (GKTexture *) loadTextureFromFilePath:(NSString *)filePath flipY:(BOOL) flipY error:(NSError **)error;
+ (GKTexture *) loadTextureFromUIImage:(UIImage *)image name:(NSString *)name error:(NSError **)error;
+ (GKTexture *) loadTextureWithData:(NSData *) data name:(NSString *)name error:(NSError **)error;

+ (void) deleteTextureFromFilePath:(NSString *)name;
+ (void) deleteTextureWithName:(NSString *)name;
//+ (void) deleteTexture:(GKTexture *)textureInfo;

+ (void) linkTexture:(GKTexture *)texture withName:(NSString *)name;

+ (void) queueDeleteTexture:(GKTexture *)textureInfo;
+ (void) queueLoadTextureFromFilePath:(NSString *)filePath flipY:(BOOL)flipY completed:(textureLoadBlock)block;
+ (GKTexture *) placeholderTexture;

@end
