//
//  GKLog.m
//  Pods
//
//  Created by apple on 2/4/15.
//  Reference from MWLogging at https://github.com/MikeWeller/MWLogging
//
//

// We need all the log functions visible so we set this to DEBUG
#ifdef GK_COMPILE_TIME_LOG_LEVEL
#undef GK_COMPILE_TIME_LOG_LEVEL
#define GK_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG
#endif

#define GK_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG

#import "GKLog.h"

static void AddStderrOnce()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        asl_add_log_file(NULL, STDERR_FILENO);
    });
}

#define __GK_MAKE_LOG_FUNCTION(LEVEL, NAME) \
void NAME (NSString *format, ...) \
{ \
AddStderrOnce(); \
va_list args; \
va_start(args, format); \
NSString *message = [[NSString alloc] initWithFormat:format arguments:args]; \
asl_log(NULL, NULL, (LEVEL), "%s", [message UTF8String]); \
va_end(args); \
}

__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_EMERG, GKLogEmergency)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_ALERT, GKLogAlert)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_CRIT, GKLogCritical)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_ERR, GKLogError)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_WARNING, GKLogWarning)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_NOTICE, GKLogNotice)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_INFO, GKLogInfo)
__GK_MAKE_LOG_FUNCTION(ASL_LEVEL_DEBUG, GKLogDebug)

#undef __GK_MAKE_LOG_FUNCTION

