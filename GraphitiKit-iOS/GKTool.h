//
//  GKTool.h
//  GraphitiKit
//
//  Created by apple on 12/18/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#ifndef GraphitiKit_GKTool_h
#define GraphitiKit_GKTool_h

typedef NS_ENUM(NSInteger, GKGestureType) {
    GKGestureTypeUnknown,
    GKGestureTypeMove,
    GKGestureTypeRotate,
    GKGestureTypeScale,
};

static NSString *const GKToolPropertyKeyType = @"type";
static NSString *const GKToolPropertyKeyColor = @"color";
static NSString *const GKToolPropertyKeySize = @"size";
static NSString *const GKToolPropertyKeySizeVarianceRatio = @"sizeVarianceRatio";
static NSString *const GKToolPropertyKeySoundFileName = @"soundFileName";
static NSString *const GKToolPropertyKeyCreateSoundFileName = @"createSoundFileName";
static NSString *const GKToolPropertyKeyStickSoundFileName = @"stickSoundFileName";
static NSString *const GKToolPropertyKeyImageName = @"imageName";
static NSString *const GKToolPropertyKeySpraySplatSize = @"splatSize";
static NSString *const GKToolPropertyKeySpraySplatSizeVarianceRatio = @"splatSizeVarianceRatio";
static NSString *const GKToolPropertyKeySpraySplatDensity = @"splatDensity";
static NSString *const GKToolPropertyKeyOverSpraySize = @"overspraysize";
static NSString *const GKToolPropertyKeyMaxSplatCount = @"maxSplatCount";
static NSString *const GKToolPropertyKeyDrippiness = @"drippiness";
static NSString *const GKToolPropertyKeyDripRate = @"dripRate";
static NSString *const GKToolPropertyKeyDripDissipateRate = @"dripDissipcateRate";
static NSString *const GKToolPropertyKeyDripThreshold = @"dripThreshold";
static NSString *const GKToolPropertyKeyMinDripCount = @"minDripCount";
static NSString *const GKToolPropertyKeyDripCountVariance = @"dripCountVariance";
static NSString *const GKToolPropertyKeyOpaque = @"opaque";
static NSString *const GKToolPropertyKeyDripSize = @"dripSize";
static NSString *const GKToolPropertyKeyDripSpeed = @"dripSpeed";
static NSString *const GKToolPropertyKeyDripSpeedVariance = @"dripSpeedVariance";
static NSString *const GKToolPropertyKeyDripLife = @"dripLife";
static NSString *const GKToolPropertyKeyDripLifeVariance = @"dripLife";
static NSString *const GKToolPropertyKeyAssetPath = @"assetPath";

static NSString *const GKToolTypeCommandString = @"command";
static NSString *const GKToolTypePaintString = @"paint";
static NSString *const GKToolTypeMarkerString = @"marker";
static NSString *const GKToolTypeStencilString = @"stencil";
static NSString *const GKToolTypeStickerString = @"sticker";

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GKToolType) {
    GKToolTypeCommand,
    GKToolTypePaint,
    GKToolTypeMarker,
    GKToolTypeStencil,
    GKToolTypeSticker,
};

typedef struct {
    CGFloat dripRate;
    CGFloat dripDissipateRate;
    CGFloat dripThreshold;
    CGFloat minDripCount;
    CGFloat dripCountVariance;
} DripSetting;

@protocol GKTool <NSObject>

@property (readonly,nonatomic) NSDictionary *toolKeyValues;
@property (nonatomic) GKToolType type;
@property (nonatomic) BOOL fromBundle;

- (id) toolValueFromKey:(NSString *)key;
- (void) setToolValue:(id)value withKey:(NSString *)key;

@end

#endif
