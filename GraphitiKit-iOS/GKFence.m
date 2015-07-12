//
//  GKFence.m
//  Pods
//
//  Created by apple on 4/7/15.
//
//

#import "GKFence.h"
#import <OpenGLES/ES2/glext.h>

@implementation GKFence {
    GLsync _fence;
    BOOL _invalidated;
}

-(instancetype)init {
    self = [super init];
    if(self) {
        _handlers = [NSMutableArray array];
    }
    return self;
}

-(void)insertFence {
    if(self.isReady) {
        _fence = glFenceSyncAPPLE(GL_SYNC_GPU_COMMANDS_COMPLETE_APPLE, 0);
    }
}

-(BOOL)isReady {
    return !_fence;
}

-(BOOL)isCompleted {
    if(_fence){
        if(glClientWaitSyncAPPLE(_fence, GL_SYNC_FLUSH_COMMANDS_BIT_APPLE, 0) == GL_ALREADY_SIGNALED_APPLE){
            glDeleteSyncAPPLE(_fence);
            _fence = NULL;
            return YES;
        } else {
            // Fence is still waiting
            return NO;
        }
    } else {
        // Fence has completed previously.
        return YES;
    }
}

@end