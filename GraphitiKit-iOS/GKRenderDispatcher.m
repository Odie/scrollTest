//
//  GKRenderDispatcher.m
//  Pods
//
//  Created by apple on 4/13/15.
//
//

#import "GKRenderDispatcher.h"
#import "GKRenderDispatcher+Private.h"
#import <OpenGLES/EAGL.h>

/// dispatch queue for all rendering task
static dispatch_queue_t GKRenderDispatchQueue = nil;
/// Semaphore to control the number of in-progress frames being rendered.
static dispatch_semaphore_t GKRenderDispatchSemaphore = nil;
/// EAGLContext used by the queue
static EAGLContext *GKRenderContext = nil;
static BOOL renderDispatchPaused = NO;

/// Maximum number of frames that can be queued at once.
#define GK_RENDER_DISPATCH_MAX_FRAMES 1

EAGLContext *GKRenderDispatchSetupGL(EAGLRenderingAPI api, EAGLSharegroup *sharegroup) {
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        GKRenderContext = [[EAGLContext alloc] initWithAPI:api sharegroup:sharegroup];
        GKRenderDispatchQueue = dispatch_queue_create("GKRenderQueue", DISPATCH_QUEUE_SERIAL);
        GKRenderDispatchSemaphore = dispatch_semaphore_create(GK_RENDER_DISPATCH_MAX_FRAMES);
    });
    return GKRenderContext;
}

static void GKRenderDispatchExecute(BOOL async, BOOL frame, dispatch_block_t block) {
    if(!GKRenderDispatchQueue || renderDispatchPaused) {
        return;
    }
    (async ? dispatch_async : dispatch_sync)(GKRenderDispatchQueue, ^{
        [EAGLContext setCurrentContext:GKRenderContext];
        block();
        [EAGLContext setCurrentContext:nil];
        if(frame) dispatch_semaphore_signal(GKRenderDispatchSemaphore);
    });
}

void GKRenderDispatchPause() {
    renderDispatchPaused = YES;
}
void GKRenderDispatchResume() {
    renderDispatchPaused = NO;
}

BOOL GKRenderDispatchBeginFrame(void) {
    return !dispatch_semaphore_wait(GKRenderDispatchSemaphore, 0);
}

void GKRenderDispatchCommitFrame(BOOL async, dispatch_block_t block) {
    GKRenderDispatchExecute(async, YES, block);
}

void GKRenderDispatch(BOOL async, dispatch_block_t block) {
    GKRenderDispatchExecute(async, NO, block);
}
