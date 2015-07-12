//
//  GKSplatEngine.m
//  Pods
//
//  Created by apple on 2/20/15.
//
//

#import "GKSplatEngine.h"
#import "GKGeometryObject.h"
#import "GKSnapShotEngine.h"

@interface GKSplatEngine ()
@property (nonatomic,strong) GKSplat *currentSplat;
@end

@implementation GKSplatEngine

+ (instancetype) defaultEngine {
    static GKSplatEngine *__engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __engine = [GKSplatEngine new];
    });
    return __engine;
}

- (instancetype) init {
    self = [super init];
    if(self) {
        _splatImageScale = 2.0;
    }
    return self;
}

- (void) beginMergeSplat:(GKSplat *)splat {
    self.currentSplat = splat;
    CGRect rect = splat.rect;
    rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(_worldBaseScale, _worldBaseScale));
    UIImage *splatImage = [UIImage imageWithContentsOfFile:splat.imagePath];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, _splatImageScale);
    if(splatImage) {
        [splatImage drawInRect:(CGRect){CGPointZero,rect.size}];
    }
}

- (void) endMergeSplat:(GKSplat *)splat {
    NSCAssert(self.currentSplat==splat, @"need begin and end with the same splat");
    UIImage *current = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImagePNGRepresentation(current);
    NSString *path = splat.imagePath;
    if(!path) {
        path = [GKSnapShotEngine splatFilePathWithFileName:[GKSnapShotEngine randomSnapShotNameWithName:@"splat"]];
    }
    [data writeToFile:path atomically:YES];
    splat.imagePath = path;
    self.currentSplat = nil;
}

- (void) addGeometryObject:(GKGeometryObject *)geoObject {
    if(!self.currentSplat) {
        return;
    }
    CGRect rect = self.currentSplat.rect;
    CGRect objectRect = geoObject.worldRect;
    if(CGRectIntersectsRect(rect, objectRect)) {
        rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(_worldBaseScale, _worldBaseScale));
        objectRect = CGRectApplyAffineTransform(objectRect, CGAffineTransformMakeScale(_worldBaseScale, _worldBaseScale));
        CGFloat normalizedObjectScale = geoObject.scale * _worldBaseScale;
        UIImage *image = [UIImage imageWithContentsOfFile:geoObject.imagePath];
        
        CGFloat offsetX = objectRect.origin.x - rect.origin.x;
        CGFloat offsetY = objectRect.origin.y - rect.origin.y;
        
        CGSize rotatedSize = image.size;
        CGPoint offset = (CGPoint){offsetX,offsetY};
        if(geoObject.flipY) {
            //            UIView *rotatedViewBox = [[UIView alloc] initWithFrame:(CGRect){0,0,rotatedSize}];
            CGRect testRect = (CGRect){0,0,rotatedSize};
            CGAffineTransform t = CGAffineTransformRotate(CGAffineTransformMakeScale(normalizedObjectScale, normalizedObjectScale),geoObject.rotationInRadian);
            CGRect aaa = CGRectApplyAffineTransform(testRect, t);
            rotatedSize = aaa.size;
            //            rotatedViewBox.transform = t;
            //            rotatedSize = rotatedViewBox.frame.size;
            offset.y = offset.y-(rect.size.height-objectRect.size.height);
            offset = CGPointApplyAffineTransform(offset, CGAffineTransformInvert(t));
        }
        if(geoObject.flipY) {
            CGContextSaveGState(UIGraphicsGetCurrentContext());
            CGContextTranslateCTM(UIGraphicsGetCurrentContext(), rotatedSize.width/2, rotatedSize.height/2);
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), normalizedObjectScale, normalizedObjectScale);
            CGContextRotateCTM(UIGraphicsGetCurrentContext(), -geoObject.rotationInRadian);
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1, -1);
            CGContextDrawImage(UIGraphicsGetCurrentContext(), (CGRect){{-image.size.width/2+offset.x,-image.size.height/2+offset.y},image.size}, image.CGImage);
            CGContextRestoreGState(UIGraphicsGetCurrentContext());
        } else {
            CGContextDrawImage(UIGraphicsGetCurrentContext(), (CGRect){{offsetX, rect.size.height-objectRect.size.height-offsetY},objectRect.size}, image.CGImage);
        }
    }
}

- (void) mergeSplat:(GKSplat *)splat withGeometryObject:(GKGeometryObject *)geoObject {
    CGRect rect = splat.rect;//CGRectIntegral(splat.rect);
    CGRect objectRect = geoObject.worldRect;
    if(!CGRectIntersectsRect(rect, objectRect)) {
        return;
    }
    rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(_worldBaseScale, _worldBaseScale));
    objectRect = CGRectApplyAffineTransform(objectRect, CGAffineTransformMakeScale(_worldBaseScale, _worldBaseScale));
    CGFloat normalizedObjectScale = geoObject.scale * _worldBaseScale;
    @autoreleasepool {
        UIImage *splatImage = [UIImage imageWithContentsOfFile:splat.imagePath];
        UIImage *image = [UIImage imageWithContentsOfFile:geoObject.imagePath];
        
        CGFloat offsetX = objectRect.origin.x - rect.origin.x;
        CGFloat offsetY = objectRect.origin.y - rect.origin.y;
        
        CGSize rotatedSize = image.size;
        CGPoint offset = (CGPoint){offsetX,offsetY};
        if(geoObject.flipY) {
//            UIView *rotatedViewBox = [[UIView alloc] initWithFrame:(CGRect){0,0,rotatedSize}];
            CGRect testRect = (CGRect){0,0,rotatedSize};
            CGAffineTransform t = CGAffineTransformRotate(CGAffineTransformMakeScale(normalizedObjectScale, normalizedObjectScale),geoObject.rotationInRadian);
            CGRect aaa = CGRectApplyAffineTransform(testRect, t);
            rotatedSize = aaa.size;
//            rotatedViewBox.transform = t;
//            rotatedSize = rotatedViewBox.frame.size;
            offset.y = offset.y-(rect.size.height-objectRect.size.height);
            offset = CGPointApplyAffineTransform(offset, CGAffineTransformInvert(t));
        }
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, _splatImageScale);
        
        if(splatImage) {
            [splatImage drawInRect:(CGRect){CGPointZero,rect.size}];
        }
        if(geoObject.flipY) {
            CGContextSaveGState(UIGraphicsGetCurrentContext());
            CGContextTranslateCTM(UIGraphicsGetCurrentContext(), rotatedSize.width/2, rotatedSize.height/2);
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), normalizedObjectScale, normalizedObjectScale);
            CGContextRotateCTM(UIGraphicsGetCurrentContext(), -geoObject.rotationInRadian);
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1, -1);
            CGContextDrawImage(UIGraphicsGetCurrentContext(), (CGRect){{-image.size.width/2+offset.x,-image.size.height/2+offset.y},image.size}, image.CGImage);
            CGContextRestoreGState(UIGraphicsGetCurrentContext());
        } else {
            CGContextDrawImage(UIGraphicsGetCurrentContext(), (CGRect){{offsetX, rect.size.height-objectRect.size.height-offsetY},objectRect.size}, image.CGImage);
        }
        UIImage *current = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *data = UIImagePNGRepresentation(current);
        NSString *path = splat.imagePath;
        if(!path) {
            path = [GKSnapShotEngine splatFilePathWithFileName:[GKSnapShotEngine randomSnapShotNameWithName:@"splat"]];
        }
        // TODO always write/rewrite the same file per splat... not very effective
        // should fix this
        [data writeToFile:path atomically:YES];
        splat.imagePath = path;
    }
}

+ (void) removeAllSplatFiles {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:GKSplatTextureFolderName];
    if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

@end


@implementation GKSplat
- (CGRect) frame {
    CGFloat y = [GKSplatEngine defaultEngine].screenHeight-self.rect.size.height-self.rect.origin.y;
    return (CGRect){{self.rect.origin.x,y},self.rect.size};
}
@end