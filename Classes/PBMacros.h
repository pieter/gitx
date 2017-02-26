//
//  PBMacros.h
//  GitX
//
//  Created by Etienne on 17/02/2017.
//
//

#import <Cocoa/Cocoa.h>

#if (GITX_NO_DEPRECATE || DEBUG)
#define GITX_DEPRECATED
#else
#define GITX_DEPRECATED __attribute__ ((deprecated))
#endif

#define PBLogFunction(x, ...) PBLogFunctionImpl(__FUNCTION__, x, ## __VA_ARGS__)

void PBLogFunctionImpl(const char *function, NSString *format, ...);