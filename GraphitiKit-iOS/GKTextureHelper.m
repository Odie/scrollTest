//
//  GKTextureHelper.m
//  Pods
//
//  Created by apple on 1/21/15.
//
//

#import "GKTextureHelper.h"
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import <ImageIO/ImageIO.h>
#import "GKSnapShotEngine.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "GKLog.h"
#import "GKRenderDispatcher.h"

@interface GKTextureWrapper : NSObject
@property (strong,nonatomic) GKTexture *textureInfo;
@property (nonatomic) NSInteger textureRetainCount;
@end

@interface GKTexture ()
@property (weak,nonatomic) GKTextureWrapper *wrapper;
@end

@interface GKTextureOperation : NSOperation
@property (copy,nonatomic) textureLoadBlock callbackBlock;
@property (copy,nonatomic) NSString *textureFilePath;
@property (nonatomic) BOOL flipY;
+(instancetype) operationWithTextureFilePath:(NSString *)filePath flipY:(BOOL)flipY completionBlock:(textureLoadBlock)block;
-(instancetype) initWithTextureFilePath:(NSString *)filePath flipY:(BOOL)flipY completionBlock:(textureLoadBlock)block NS_DESIGNATED_INITIALIZER;
@end

@interface GKTextureHelper () {
@public
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    dispatch_queue_t workerQueue;
    dispatch_queue_t textureLoaderQueue;
    EAGLContext *textureLoaderContext;
    GKTexture *_placeHolderTexture;
    NSOperationQueue *_textureOperationQueue;
}
@property (nonatomic) NSUInteger glTextureCacheLimit;
@property (nonatomic) NSUInteger glTextureCacheSize;
@end

@implementation GKTextureHelper

- (instancetype) init {
    self = [super init];
    if(self) {
        _pendingSavginTextureCount = 0;
        _textureOperationQueue = [[NSOperationQueue alloc] init];
        _textureOperationQueue.name = @"TextureLoadingQueue";
        _textureOperationQueue.maxConcurrentOperationCount = 1;
        textureLoaderQueue = dispatch_queue_create("com.graphiti.graphitikit.texture.loader", NULL);
        workerQueue = dispatch_queue_create("com.graphiti.graphitikit.imagetask", NULL);
    }
    return self;
}

+ (instancetype) sharedTextureHelper {
    static GKTextureHelper *_helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = [GKTextureHelper new];
    });
    return _helper;
}

+ (void) setupBackgroundContextWithAPI:(EAGLRenderingAPI) api shareGroup:(EAGLSharegroup *)shareGroup {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api sharegroup:shareGroup];
    [GKTextureHelper sharedTextureHelper]->textureLoaderContext = context;
}

+ (void) setGLTextureCacheSize:(NSUInteger)cacheSize {
    [GKTextureHelper sharedTextureHelper].glTextureCacheLimit = cacheSize;
}

+ (dispatch_queue_t) textureWorkerQueue {
    return [GKTextureHelper sharedTextureHelper]->workerQueue;
}

- (NSMutableDictionary *) glTextureCache {
    static NSMutableDictionary *__textureCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __textureCache = [NSMutableDictionary dictionary];
    });
    return __textureCache;
}

+ (CVOpenGLESTextureCacheRef) coreVideoTextureCacheFromContext:(EAGLContext *)context {
    if([self supportsFastTextureUpload]) {
        CVOpenGLESTextureCacheRef *coreVideoTextureCache = &[GKTextureHelper sharedTextureHelper]->coreVideoTextureCache;
        if(!*coreVideoTextureCache) {
            if(context) {
                CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &[GKTextureHelper sharedTextureHelper]->coreVideoTextureCache);
                if (err) {
                    GKLogError(@"error creating CVOpenGLESTextureCache %d",err);
                }
            } else {
                GKLogError(@"creating texturecache without context");
            }
        }
        return *coreVideoTextureCache;
    }
    return nil;
}

+ (BOOL)supportsFastTextureUpload;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (&CVOpenGLESTextureCacheCreate != NULL);
#endif
}

//#define PROFILEGK

+ (void) saveBytes:(GLubyte *)data length:(NSUInteger) length textureSize:(CGSize)size toPath:(NSString *)path completed:(void(^)(NSString *))completedBlock {
    [GKTextureHelper sharedTextureHelper].pendingSavginTextureCount++;
    // TODO: HUGE performance hit with this data copyping, solve it with some kind of memory pool
    GLubyte *rawImageDataBuffer = (GLubyte *) malloc(length);
    memcpy(rawImageDataBuffer, data, length);
    dispatch_queue_t workerQueue = [GKTextureHelper textureWorkerQueue];
    dispatch_async(workerQueue, ^{
#ifdef PROFILEGK
        NSTimeInterval startT = [[NSDate date] timeIntervalSince1970];
#endif

        // prep the ingredients
        int nrOfColorComponents = 4; //BGRA
        int bitsPerComponent = 8;
        int bitsPerPixel = nrOfColorComponents*bitsPerComponent;
        int bytesPerRow = 4 * size.width;
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
        // save back as RGBA format
        for(int i = 0; i < length/nrOfColorComponents; i++) {
            Byte b = rawImageDataBuffer[i*4];
            Byte r = rawImageDataBuffer[i*4+2];
            rawImageDataBuffer[i*4] = r;
            rawImageDataBuffer[i*4+2] = b;
        }
//            bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
        
        CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGDataProviderRef provider = CGDataProviderCreateWithData(&bitmapInfo, rawImageDataBuffer, length, NULL);
        CGImageRef imageRef = CGImageCreate((size_t)size.width, (size_t)size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, defaultRGBColorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
        if(imageRef && WriteCGImageToFile(imageRef, path)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completedBlock) {
                    completedBlock(path);
                }
            });
        }
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(defaultRGBColorSpace);
        free(rawImageDataBuffer);
        [GKTextureHelper sharedTextureHelper].pendingSavginTextureCount--;
#ifdef PROFILEGK
        NSTimeInterval endT = [[NSDate date] timeIntervalSince1970];
        GKLogInfo(@"saved texture data %f",endT-startT);
#endif
    });
}

+ (void) releaseCachedResources {
    [[GKTextureHelper sharedTextureHelper]->_textureOperationQueue cancelAllOperations];
    [GKTextureHelper sharedTextureHelper]->_placeHolderTexture = nil;
    [GKTextureHelper sharedTextureHelper].pendingSavginTextureCount = 0;
    
    NSMutableDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
    @synchronized(cache) {
        [cache enumerateKeysAndObjectsUsingBlock:^(id key, GKTextureWrapper *obj, BOOL *stop) {
            GLuint textureName = obj.textureInfo->textureName;
            if(textureName > 0) {
                GKRenderDispatch(YES, ^{
                    glDeleteTextures(1, &textureName);
                });
            }
        }];
        [cache removeAllObjects];
    }
    
    if([self supportsFastTextureUpload]) {
        CVOpenGLESTextureCacheRef *coreVideoTextureCache = &[GKTextureHelper sharedTextureHelper]->coreVideoTextureCache;
        if(*coreVideoTextureCache) {
            CFRelease(*coreVideoTextureCache);
            [GKTextureHelper sharedTextureHelper]->coreVideoTextureCache = nil;
        }
    }
    [GKTextureHelper sharedTextureHelper]->textureLoaderContext = nil;
}

+ (GKTexture *) createTextureWithSize:(CGSize) textureSize context:(EAGLContext *)context {
    BOOL hasPixelBuffer = [self supportsFastTextureUpload];
    GKTexture *texture = [GKTexture new];
    if(hasPixelBuffer) {
        CVOpenGLESTextureCacheFlush([GKTextureHelper coreVideoTextureCacheFromContext:context], 0);
        [self createPixelBuffer:&(texture->pixelBuffer) withSize:textureSize];
        [self createCVOpenGLTextureRef:&(texture->cvOpenGLESTexture) withSize:textureSize imageBuffer:texture->pixelBuffer context:context];
        texture->textureName = CVOpenGLESTextureGetName(texture->cvOpenGLESTexture);
    } else {
        glGenTextures(1, &(texture->textureName));
    }
    
    if(texture->textureName > 0) {
        // create the texture
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture->textureName);
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
        if(!hasPixelBuffer) {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize.width, textureSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        }
    }
    return texture;
}

+ (void) createPixelBuffer:(CVPixelBufferRef *) pixelBufferPtr withSize:(CGSize)size {
    // create cvpixelbuffer
//    CVPixelBufferRef pixelBuffer = *pixelBufferPtr;
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (size_t)size.width, (size_t)size.height, kCVPixelFormatType_32BGRA, attrs, pixelBufferPtr);
    if (err) {
        GKLogError(@"Error at CVPixelBufferCreate %d FBO size: %f, %f", err, size.width, size.height);
    }
    CFRelease(attrs);
    CFRelease(empty);
}

+ (void) createCVOpenGLTextureRef:(CVOpenGLESTextureRef *)textureRefPtr withSize:(CGSize)size imageBuffer:(CVPixelBufferRef)buffer context:(EAGLContext *)context {
    CVOpenGLESTextureCacheRef coreVideoTextureCache = [self coreVideoTextureCacheFromContext:context];
    if(!coreVideoTextureCache) {
        return;
    }
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, buffer,
                                                                 NULL, // texture attributes
                                                                 GL_TEXTURE_2D,
                                                                 GL_RGBA, // opengl format
                                                                 (GLsizei)size.width,
                                                                 (GLsizei)size.height,
                                                                 GL_BGRA, // native iOS format
                                                                 GL_UNSIGNED_BYTE,
                                                                 0,
                                                                 textureRefPtr);
    if (err) {
        GKLogError(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d",err);
    }
}

BOOL WriteCGImageToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        GKLogError(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    CGImageDestinationAddImage(destination, image, nil);
    if (!CGImageDestinationFinalize(destination)) {
        GKLogError(@"Failed to write image to %@", path);
    }
    CFRelease(destination);
    return YES;
}

+ (void) linkTexture:(GKTexture *)texture withName:(NSString *)name {
    GKTextureWrapper *textureWrapper = nil;
    NSMutableDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
    @synchronized(cache) {
        textureWrapper = cache[name];
    }
    if(textureWrapper) {
        return;
    }
    
    textureWrapper = [GKTextureWrapper new];
    textureWrapper.textureInfo = texture;
    textureWrapper.textureRetainCount = 1;
    @synchronized(cache) {
        cache[name] = textureWrapper;
    }
}

+ (GKTexture *) loadTextureFromFilePath:(NSString *)filePath flipY:(BOOL) flipY error:(NSError **)error {
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    return [self loadTextureFromUIImage:image name:filePath flipY:flipY error:error];
}

+ (GKTexture *) loadTextureFromFilePath:(NSString *)filePath error:(NSError **)error {
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    if(image) {
        return [self loadTextureFromUIImage:image name:filePath flipY:YES error:error];
    }
    return nil;
}

+ (GKTexture *) loadTextureFromUIImage:(UIImage *)image name:(NSString *)name error:(NSError **)error {
    return [self loadTextureFromUIImage:image name:name flipY:YES error:error];
}

+ (GKTexture *) loadTextureWithData:(NSData *) data name:(NSString *)name error:(NSError **)error {
    if(!data) {
        return nil;
    }
    UIImage *image = [UIImage imageWithData:data];
    return [self loadTextureFromUIImage:image name:name error:error];
}

+ (GKTexture *) loadTextureFromUIImage:(UIImage *)image name:(NSString *)name flipY:(BOOL)flipY error:(NSError **)error {
    if(!name.length) {
        return nil;
    }
    GKTextureWrapper *textureWrapper = nil;
    NSMutableDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
    @synchronized(cache) {
        textureWrapper = cache[name];
    }
    
    if(textureWrapper) {
        textureWrapper.textureRetainCount++;
        return textureWrapper.textureInfo;
    }
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
    
    // Detect if the image contains alpha data
    BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) ||
                     (info == kCGImageAlphaPremultipliedFirst) ||
                     (info == kCGImageAlphaLast) ||
                     (info == kCGImageAlphaFirst) ? YES : NO);
    BOOL isPremultiplied = ((info == kCGImageAlphaPremultipliedLast) ||
                            (info == kCGImageAlphaPremultipliedFirst) ? YES : NO);
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    GLuint textureName;
    glGenTextures(1, &textureName);
    // create the texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureName);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    // This is necessary for non-power-of-two textures
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    
    void *imageData = malloc( height * width * 4 );
    CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
    if(flipY) {
        CGContextTranslateCTM(context, 0, height);
        CGContextScaleCTM(context, 1.0, -1.0);
    }
    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    CGContextRelease(context);
    free(imageData);
    
    // check error ?
    //    GLenum status = glGetError();
    //    if(status != GL_NO_ERROR) {
    //        *error = [NSError errorWithDomain:@"OPENGL" code:status userInfo:nil];
    //        return nil;
    //    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    GKTexture *textureInfo = [GKTexture new];
    textureInfo->textureName = textureName;
    textureInfo->width = (GLsizei)width;
    textureInfo->height = (GLsizei)height;
    textureInfo->hasAlpha = hasAlpha;
    textureInfo->premultiplied = isPremultiplied;
    
    textureWrapper = [GKTextureWrapper new];
    textureWrapper.textureInfo = textureInfo;
    textureWrapper.textureRetainCount = 1;
    @synchronized(cache) {
        cache[name] = textureWrapper;
    }
    return textureWrapper.textureInfo;
}

+ (void) deleteTextureFromFilePath:(NSString *)path {
    [self deleteTextureWithName:path];
}

+ (void) deleteTextureWithName:(NSString *)name {
    if(!name.length) {
        return;
    }
    NSMutableDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
    @synchronized(cache) {
        GKTextureWrapper *textureWrapper = cache[name];
        if(textureWrapper) {
            textureWrapper.textureRetainCount--;
            if(textureWrapper.textureRetainCount <= 0) {
                GKLogDebug(@"deleting texture %zd withName %@",textureWrapper.textureInfo->textureName,name);
                GLuint textureName = textureWrapper.textureInfo->textureName;
                if(textureName > 0) {
                    GKRenderDispatch(YES, ^{
                        glDeleteTextures(1, &textureName);
                    });
                }
                [cache removeObjectForKey:name];
            }
        }
    }
}

+ (void) deleteTexture:(GKTexture *)textureInfo {
    if(!textureInfo) {
        return;
    }
    __block NSString *nameToDelete = nil;
    NSDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
    @synchronized(cache) {
        [cache enumerateKeysAndObjectsUsingBlock:^(NSString *key, GKTextureWrapper *obj, BOOL *stop) {
            if([obj isKindOfClass:[GKTextureWrapper class]] && textureInfo == obj.textureInfo) {
                obj.textureRetainCount--;
                if(obj.textureRetainCount <= 0) {
                    nameToDelete = key;
                }
                *stop = YES;
            }
        }];
    }
    [self deleteTextureWithName:nameToDelete];
}

+ (GKTexture *) createTextureWithSize:(CGSize)size filePath:(NSString **)textureFilePath {
    NSString *fileName = [GKSnapShotEngine randomSnapShotNameWithName:@"background"];
    NSString *filePath = [GKSnapShotEngine tempTextureFilePathWithFileName:fileName];
    
    @autoreleasepool {
        //kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
        UIGraphicsBeginImageContextWithOptions(size, NO, 2.0);
//        UIColor *color = [UIColor colorWithRed:0 green:0.0 blue:1.0 alpha:1.0];
//        CGRect rect = CGRectMake(0, 0, size.width, size.height);        
//        [color setFill];
//        UIRectFill(rect);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [UIImagePNGRepresentation(blank) writeToFile:filePath atomically:YES];
    }
    GKLogInfo(@"saving texture into %@",filePath);
    *textureFilePath = filePath;
    GKTexture *texture = [self loadTextureFromFilePath:filePath error:nil];
    texture->width = size.width;
    texture->height = size.height;
    return texture;
}

+ (void) queueDeleteTexture:(GKTexture *)textureInfo {
    if(textureInfo && [textureInfo isKindOfClass:[GKTexture class]]) {
        [[GKTextureHelper sharedTextureHelper]->_textureOperationQueue addOperationWithBlock:^{
            [GKTextureHelper deleteTexture:textureInfo];
        }];
    }
}

+ (void) queueLoadTextureFromFilePath:(NSString *)filePath flipY:(BOOL)flipY completed:(textureLoadBlock)block {
    if(block) {
        GKTextureOperation *operation = [GKTextureOperation operationWithTextureFilePath:filePath flipY:flipY completionBlock:block];
        [[GKTextureHelper sharedTextureHelper]->_textureOperationQueue addOperation:operation];
    }
}

+ (GKTexture *) placeholderTexture {
    GKTexture *textureInfo = [GKTextureHelper sharedTextureHelper]->_placeHolderTexture;
    if(!textureInfo) {
        UIColor *color = [UIColor colorWithRed:0 green:1.0 blue:0 alpha:0.01];
        CGRect rect = CGRectMake(0, 0, 1, 1);
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2.0);
        [color setFill];
        UIRectFill(rect);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        textureInfo = [GKTextureHelper loadTextureFromUIImage:image name:@"GK_Placeholder_Texture" error:nil];
        [GKTextureHelper sharedTextureHelper]->_placeHolderTexture = textureInfo;
    }
    return textureInfo;
}

@end

@implementation GKTexture

- (void) dealloc {
    if(cvOpenGLESTexture) {
        CVOpenGLESTextureRef ref = cvOpenGLESTexture;
        GKRenderDispatch(YES, ^{
            CFRelease(ref);
        });
        cvOpenGLESTexture = nil;
        textureName = 0;
    } else {
        // mananaged by texture cache, do not delete
        //        if(textureName) {
        //            glDeleteTextures(1, &textureName);
        //            textureName = 0;
        //        }
    }
    if(pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
        pixelBuffer = nil;
    }    
}

- (void) updateDataWith:(GLbyte *)imageData rect:(CGRect)rect {
    if(!textureName) {
        return;
    }
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureName);
    glTexSubImage2D(GL_TEXTURE_2D,0,(GLint)rect.origin.x,(GLint)rect.origin.y,(GLsizei)rect.size.width, (GLsizei)rect.size.height,GL_RGBA,GL_UNSIGNED_BYTE, imageData);
    // check error ?
    //    GLenum status = glGetError();
    //    if(status != GL_NO_ERROR) {
    //        *error = [NSError errorWithDomain:@"OPENGL" code:status userInfo:nil];
    //        return nil;
    //    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void) updateDataWithData:(CFDataRef) dataRef rect:(CGRect)rect {
    if(!textureName) {
        return;
    }
    UInt8 const *imageData = CFDataGetBytePtr(dataRef);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureName);
    glTexSubImage2D(GL_TEXTURE_2D,0,(GLint)rect.origin.x,(GLint)rect.origin.y,(GLsizei)rect.size.width, (GLsizei)rect.size.height,GL_RGBA,GL_UNSIGNED_BYTE, imageData);
    // check error ?
    //    GLenum status = glGetError();
    //    if(status != GL_NO_ERROR) {
    //        *error = [NSError errorWithDomain:@"OPENGL" code:status userInfo:nil];
    //        return nil;
    //    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void) updateDataWith:(UIImage *)image bitmapInfo:(CGBitmapInfo)bitmapInfo {
    if(!textureName) {
        return;
    }
    // bitmapInfo not used
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    size_t imageWidth = CGImageGetWidth(image.CGImage);
    size_t imageHeight = CGImageGetHeight(image.CGImage);
    
    Byte *imageData = malloc( imageHeight * imageWidth * 4 );
    CGContextRef context = CGBitmapContextCreate( imageData, imageWidth, imageHeight, 8, 4 * imageWidth, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGContextClearRect( context, CGRectMake( 0, 0, imageWidth, imageHeight ) );
//    if(flipY) {
        CGContextTranslateCTM(context, 0, imageHeight);
        CGContextScaleCTM(context, 1.0, -1.0);
//    }
    CGContextDrawImage( context, CGRectMake( 0, 0, imageWidth, imageHeight ), image.CGImage);
    CGContextRelease(context);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureName);
    glTexSubImage2D(GL_TEXTURE_2D,0,0,0,(GLsizei)imageWidth, (GLsizei)imageHeight,GL_RGBA,GL_UNSIGNED_BYTE, imageData);
    free(imageData);
    
    // check error ?
    //    GLenum status = glGetError();
    //    if(status != GL_NO_ERROR) {
    //        *error = [NSError errorWithDomain:@"OPENGL" code:status userInfo:nil];
    //        return nil;
    //    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

@end

@implementation GKTextureWrapper
@end

@implementation GKTextureOperation

+(instancetype) operationWithTextureFilePath:(NSString *)filePath flipY:(BOOL)flipY completionBlock:(textureLoadBlock)block {
    return [[self alloc] initWithTextureFilePath:filePath flipY:flipY completionBlock:block];
}

-(instancetype) initWithTextureFilePath:(NSString *)filePath flipY:(BOOL)flipY completionBlock:(textureLoadBlock)block {
    self = [super init];
    if(self) {
        self.callbackBlock = block;
        self.textureFilePath = filePath;
        self.flipY = flipY;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if(!self.callbackBlock) {
            return;
        }
        textureLoadBlock block = self.callbackBlock;
        // TODO define error code for nil filepath
        if(!self.textureFilePath.length) {
            block(nil,[NSError errorWithDomain:@"GraphitiKit" code:404 userInfo:nil]);
            return;
        }
        NSString *name = self.textureFilePath;
        NSMutableDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
        __block GKTextureWrapper *textureWrapper;
        @synchronized(cache) {
            textureWrapper = cache[name];
        }
        if(textureWrapper) {
            textureWrapper.textureRetainCount++;
            GKRenderDispatch(YES, ^{
                block(textureWrapper.textureInfo,nil);
            });
            return;
        }
        UIImage *image = [UIImage imageWithContentsOfFile:name];
        
        // early exist if canceled
        if(self.cancelled) {
            return;
        }
        // TODO define error code for nil data
        if(image) {
            [EAGLContext setCurrentContext:[GKTextureHelper sharedTextureHelper]->textureLoaderContext];
            CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
            CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
            
            // Detect if the image contains alpha data
            BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) ||
                             (info == kCGImageAlphaPremultipliedFirst) ||
                             (info == kCGImageAlphaLast) ||
                             (info == kCGImageAlphaFirst) ? YES : NO);
            BOOL isPremultiplied = ((info == kCGImageAlphaPremultipliedLast) ||
                                    (info == kCGImageAlphaPremultipliedFirst) ? YES : NO);
            size_t width = CGImageGetWidth(image.CGImage);
            size_t height = CGImageGetHeight(image.CGImage);
            
            Byte *imageData = malloc( height * width * 4 );
            
            // early exist if canceled
            if(self.cancelled) {
                free(imageData);
                return;
            }
            CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
            CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
            if(self.flipY) {
                CGContextTranslateCTM(context, 0, height);
                CGContextScaleCTM(context, 1.0, -1.0);
            }
            CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage);
            CGContextRelease(context);
            
            // early exist if canceled
            if(self.cancelled) {
                free(imageData);
                return;
            }
            
            GLuint textureName;
            glGenTextures(1, &textureName);
            // create the texture
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, textureName);
            
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
            // This is necessary for non-power-of-two textures
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
            free(imageData);
            glBindTexture(GL_TEXTURE_2D, 0);
            glFlush();
            
            // early exist if canceled
            if(self.cancelled) {
                glDeleteTextures(1, &textureName);
                return;
            }
            
            // check error ?
            //    GLenum status = glGetError();
            //    if(status != GL_NO_ERROR) {
            //        *error = [NSError errorWithDomain:@"OPENGL" code:status userInfo:nil];
            //        return nil;
            //    }
            
            GKTexture *textureInfo = [GKTexture new];
            textureInfo->textureName = textureName;
            textureInfo->width = (GLsizei)width;
            textureInfo->height = (GLsizei)height;
            textureInfo->hasAlpha = hasAlpha;
            textureInfo->premultiplied = isPremultiplied;
            
            textureWrapper = [GKTextureWrapper new];
            textureWrapper.textureInfo = textureInfo;
            textureWrapper.textureRetainCount = 1;
            
            NSMutableDictionary *cache = [[GKTextureHelper sharedTextureHelper] glTextureCache];
            @synchronized(cache) {
                cache[name] = textureWrapper;
            }
            GKRenderDispatch(YES, ^{
                block(textureWrapper.textureInfo,nil);
            });
        } else {
            block(nil,[NSError errorWithDomain:@"GraphitiKit" code:404 userInfo:nil]);
        }
    }
}

@end
