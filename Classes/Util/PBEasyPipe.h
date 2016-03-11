//
//  PBEasyPipe.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PBEasyPipeErrorDomain;
extern NSString *const PBEasyPipeUnderlyingExceptionKey;

typedef NS_ENUM(NSUInteger, PBEasyPipeError) {
	PBEasyPipeTaskLaunchError = 1,
};


@interface PBEasyPipe: NSObject

/**
 * Execute a command in the shell.
 * 
 * This is a wrapper around NSTask that uses blocks to report when the
 * executable exits, and should be used whenever we need to shell out to git.
 *
 * @param command The absolute path to the executable that should be run.
 * @param arguments The arguments to pass to the executable.
 * @param directory The directory to use as the executable working directory.
 * @param terminationHandler A block that will be called when the executable exits.
 */
+ (void)performCommand:(NSString *)command arguments:(nullable NSArray *)arguments inDirectory:(nullable NSString *)directory terminationHandler:(void (^)(NSTask *task, NSError * __nullable error))terminationHandler;

/**
 * Execute a command in the shell, and process its output.
 *
 * @see -performCommand:arguments:inDirectory:terminationHandler:
 *
 * @param command The absolute path to the executable that should be run.
 * @param arguments The arguments to pass to the executable.
 * @param directory The directory to use as the executable working directory.
 * @param completionHandler A block that will be called when the executable exits.
 *							If readData is nil, it means an error occurred.
 */
+ (void)performCommand:(NSString *)command arguments:(nullable NSArray *)arguments inDirectory:(nullable NSString *)directory completionHandler:(void (^)(NSTask *task, NSData * __nullable readData, NSError * __nullable error))completionHandler;

/**
 * Setup a task for subsequent execution.
 *
 * @param command The absolute path to the executable that should be run.
 * @param arguments The arguments to pass to the executable. Can be nil.
 * @param directory The directory to use as the executable working directory. Can be nil.
 */
+ (NSTask *)taskForCommand:(NSString *)command arguments:(nullable NSArray *)arguments inDirectory:(nullable NSString *)directory;

/* The following methods are kept for backward-compatibility.
 * Newly-written code should use the block-based methods above.
 */
+ (NSTask *)taskForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir GITX_DEPRECATED;
+ (NSString *)outputForCommand:(NSString *)cmd withArgs:(NSArray *)args GITX_DEPRECATED;
+ (NSString *)outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir GITX_DEPRECATED;
+ (NSString *)outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir retValue:(int *)ret GITX_DEPRECATED;
+ (NSString *)outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir inputString:(NSString *)input retValue:(int *)ret GITX_DEPRECATED;
+ (NSString *)outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir byExtendingEnvironment:(NSDictionary *)dict inputString:(NSString *)input retValue:(int *)ret GITX_DEPRECATED;

/*
 * The following methods are deprecated because they're inherently racy:
 * They are launched at the end of the method, but you might not be able to
 * register for the NSFileHandle notification before they are done running.
 */
+ (NSFileHandle *)handleForCommand:(NSString *)cmd withArgs:(NSArray *)args GITX_DEPRECATED;
+ (NSFileHandle *)handleForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir GITX_DEPRECATED;

@end

NS_ASSUME_NONNULL_END