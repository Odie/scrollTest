//
//  GKVertexArrayObject.h
//  Pods
//
//  Created by apple on 2/6/15.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GKVertexArrayObject : NSObject 

@property (nonatomic,readonly) GLuint vaoName;
@property (nonatomic,readonly) GLuint vertexBufferName;
@property (nonatomic,readonly) GLuint indexBufferName;

+ (GKVertexArrayObject *) quadVAOWithName:(NSString *)name vaoBlock:(void(^)())block;
+ (GKVertexArrayObject *) textureVAOWithName:(NSString *)name vaoBlock:(void(^)())block;
+ (void) releaseStaticResources;

@end
