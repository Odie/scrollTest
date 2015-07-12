//
//  GKRenderDispatcher+Private.h
//  Pods
//
//  Created by apple on 4/13/15.
//
//

#ifndef Pods_GKRenderDispatcher_Private_h
#define Pods_GKRenderDispatcher_Private_h

#import "GKRenderDispatcher.h"

BOOL GKRenderDispatchBeginFrame(void);
void GKRenderDispatchCommitFrame(BOOL async, dispatch_block_t block);
EAGLContext *GKRenderDispatchSetupGL(EAGLRenderingAPI api, EAGLSharegroup *sharegroup);

#endif
