//
//  GPComponent.h
//  Graphiti-Prototype
//
//  Created by apple on 11/12/14.
//  Copyright (c) 2014 LiveRelay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GKAudioControllerDelegate.h"
#import "GKTool.h"

@class GestureController,GKUndoManager,GKGeometryObject,GPSurface;

@protocol GKComponent <NSObject>
@property (nonatomic) BOOL enabled;
/*
 object use world scale to adjust itself own scale
 */
@property (nonatomic) CGFloat worldScale;

@property (nonatomic) CGPoint worldTopLeft;

@property (nonatomic) CGFloat viewPointPerPoint;
/*
 allow component to have access to undo manager... probobly not a best place to put it
 but for developing speed, put it here for now
 */
@property (weak,nonatomic) GKUndoManager *undoManager;
@end

@protocol GKGestureComponent <GKComponent>
@property (nonatomic) BOOL gestureEnabled;
@property (weak,nonatomic) GestureController *gestureController;
@end

@protocol GKRendererComponent <GKComponent>
@property (nonatomic) BOOL renderOnMainSurface;

- (void) render:(GLKMatrix4)projectionMatrix;
- (void) renderOnSurface:(GLKMatrix4)projectionMatrix;
- (void) cleanupAfterRender;
- (void) setupGL;
- (void) teardownGL;
@end

@protocol GKStencilComponent <GKRendererComponent>
- (void) renderAsStencil:(GLKMatrix4)projectionMatrix;
- (void) renderOnStencilTexture:(GLKMatrix4)projectionMatrix;
@end

@protocol GKStickerComponent <GKRendererComponent>
@property (nonatomic) BOOL shouldStick;
@property (nonatomic) BOOL shouldStickOnStencil;
- (void) stickOnSurface:(GLKMatrix4)projectionMatrix stencilOn:(BOOL)stencilOn;
@end

@protocol GKGeometryCreatorComponent <GKComponent>
- (GKGeometryObject *) forkObject;
- (NSArray *) forkObjectsFromSurface;
- (void) finish;
@end

@protocol GKSurfaceRendererComponent <GKRendererComponent>
@property (weak,nonatomic) GPSurface *surface;
@end

@protocol GKRenderSurfaceComponent <GKComponent>
- (void) bind;
- (void) avoidLogicalBufferStore;
@property (nonatomic,readonly) CGSize surfaceSize;
@end

@protocol GKAudioComponent <GKComponent>
@property (weak,nonatomic) id <GKAudioControllerDelegate> audioComponent;
@property (strong,nonatomic) NSString *soundFilePath;
@end

@protocol GKTransformComponent <GKComponent>
@property (nonatomic) GLfloat minimumScale;
@property (nonatomic) GLfloat scale;
@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLfloat rotationInRadian;
@property (nonatomic,readonly) GLKVector3 latestPosition;
@property (nonatomic,readonly) GLfloat latestScale;
@property (nonatomic,readonly) GLfloat latestRotation;
@property (nonatomic,readonly) GLKMatrix4 modelMatrix;
@property (nonatomic,readonly) GLKMatrix4 inverseModelMatrix;
@end

@protocol GKConfigurableComponent <GKComponent>
@property (strong,nonatomic) id<GKTool> configuration;
- (void) configWithToolDefinition:(id<GKTool>)tool;
@end

@interface GKComponent : NSObject <GKComponent>

@end
