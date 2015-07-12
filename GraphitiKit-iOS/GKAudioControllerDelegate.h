//
//  AudioControllerDelegate.h
//  GraphitiKit
//
//  Created by apple on 12/11/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#ifndef GraphitiKit_AudioControllerDelegate_h
#define GraphitiKit_AudioControllerDelegate_h

@class GKAudioData;

typedef NS_ENUM(NSInteger, GKAudioType) {
    GKAudioTypeNone,
    GKAudioTypeStickerCreate,
    GKAudioTypeStickerStick,
    GKAudioTypeMarker,
    GKAudioTypePaint,
    GKAudioTypeStencilCreate,
    GKAudioTypeStencilRemove,
};

@protocol GKAudioControllerDelegate <NSObject>

- (void) updateSound:(GKAudioType)soundType Pitch:(float)pitch;
- (void) stopSound:(GKAudioType)soundType;
- (void) playSound:(GKAudioData *)soundData;
- (void) startSound:(GKAudioData *)soundData;
- (void) stopAllSounds;

@end

#endif
