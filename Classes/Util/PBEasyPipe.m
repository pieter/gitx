//
//  PBEasyPipe.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBEasyPipe.h"
#import <objc/runtime.h>

NSString *const PBEasyPipeErrorDomain = @"PBEasyPipeErrorDomain";
NSString *const PBEasyPipeUnderlyingExceptionKey = @"PBEasyPipeUnderlyingExceptionKey";

#pragma mark - NSPipe category

/* Some NSTask's generate a lot of output. Using a regular pipe with these tasks causes the pipe to fill up before the
 task completes; it will basically fail silently. To fix this, the pipe must occasionally be read into a
 cache, but because this can occur at the end of a chain of async operations, it gets complicated. Instead, you can set
 the .dataOutput property on this NSPipe category, and the intermittent results automatically will be read into
 that NSMutableData.
 */

@interface NSPipe (PBEasyPipe)

@property (nonatomic, strong) NSMutableData *dataOutput;

@end

@implementation NSPipe (PBEasyPipe)

- (void)setDataOutput:(nonnull NSMutableData *)dataOutput {
	objc_setAssociatedObject(self, @selector(dataOutput), dataOutput, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	NSFileHandle *fileHandle = self.fileHandleForReading;
	NSAssert(fileHandle != nil, @"should have file handle for reading");

	fileHandle.readabilityHandler = ^(NSFileHandle * _Nonnull fileHandle) {
		NSData *data = fileHandle.availableData;
		if (data.length) {
			[dataOutput appendData:data];
		} else {
			[fileHandle closeFile];
		}
	};
}

- (NSMutableData *)dataOutput {
	return objc_getAssociatedObject(self, @selector(dataOutput));
}

- (void)clear {
	self.fileHandleForReading.readabilityHandler = nil;
}

@end

#pragma mark - PBEasyPipe implementation

@implementation PBEasyPipe

+ (nullable NSTask *)performCommand:(NSString *)command arguments:(NSArray *)arguments inDirectory:(NSString *)directory terminationHandler:(void (^)(NSTask *, NSError *error))terminationHandler {
	NSParameterAssert(command != nil);

	NSTask *task = [self taskForCommand:command arguments:arguments inDirectory:directory];
	NSPipe *pipe = task.standardOutput;
	pipe.dataOutput = [NSMutableData data];

	task.terminationHandler = ^(NSTask *task) {
		dispatch_async(dispatch_get_main_queue(), ^{
			terminationHandler(task, nil);
		});
	};

	@try {
		[task launch];
	} @catch (NSException *exception) {
		NSString *desc = @"Exception raised while launching task";
		NSString *failureReason = [NSString stringWithFormat:@"The task \"%@\" failed to launch", command];
		NSDictionary *info = @{NSLocalizedDescriptionKey: desc,
													 NSLocalizedFailureReasonErrorKey: failureReason,
													 PBEasyPipeUnderlyingExceptionKey: exception};
		NSError *error = [NSError errorWithDomain:PBEasyPipeErrorDomain code:PBEasyPipeTaskLaunchError userInfo:info];
		terminationHandler(task, error);
	}

	return task;
}

+ (nullable NSTask *)performCommand:(NSString *)command arguments:(NSArray *)arguments inDirectory:(NSString *)directory completionHandler:(void (^)(NSTask *, NSData *readData, NSError *error))completionHandler {

	return [self performCommand:command arguments:arguments inDirectory:directory terminationHandler:^(NSTask *task, NSError *error) {
		NSPipe *pipe = task.standardOutput;

		if (error) {
			[pipe clear];
			completionHandler(task, nil, error);
			return;
		}

		[pipe clear];

		completionHandler(task, pipe.dataOutput, nil);
	}];
}

+ (NSTask *)taskForCommand:(NSString *)cmd arguments:(NSArray *)args inDirectory:(NSString *)directory
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:cmd];
	[task setArguments:args];

    // Prepare ourselves a nicer environment
    NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
    [env removeObjectsForKeys:@[@"MallocStackLogging",
								@"MallocStackLoggingNoCompact",
								@"DYLD_INSERT_LIBRARIES", // to avoid GuardMalloc logging
								@"NSZombieEnabled"]];
    [task setEnvironment:env];

	if (directory)
		[task setCurrentDirectoryPath:directory];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Debug Messages"])
		NSLog(@"Starting command `%@ %@` in dir %@", cmd, [args componentsJoinedByString:@" "], directory);
#ifdef CLI
	NSLog(@"Starting command `%@ %@` in dir %@", cmd, [args componentsJoinedByString:@" "], directory);
#endif

	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	[task setStandardError:pipe];
	return task;
}

+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
				      retValue:(int *)      ret
{
	return [self outputForCommand:cmd withArgs:args inDir:dir byExtendingEnvironment:nil inputString:nil retValue:ret];
}	

+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
				   inputString:(NSString *) input
				      retValue:(int *)      ret
{
	return [self outputForCommand:cmd withArgs:args inDir:dir byExtendingEnvironment:nil inputString:input retValue:ret];
}

+ (NSString*) outputForCommand:(NSString *)    cmd
					  withArgs:(NSArray *)     args
						 inDir:(NSString *)    dir
		byExtendingEnvironment:(NSDictionary *)dict
				   inputString:(NSString *)    input
					  retValue:(int *)         ret
{
	NSTask *task = [self taskForCommand:cmd arguments:args inDirectory:dir];

	if (dict) {
		NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
		[env addEntriesFromDictionary:dict];
		[task setEnvironment:env];
	}

	NSFileHandle* handle = [[task standardOutput] fileHandleForReading];
	NSFileHandle *inHandle = nil;

	if (input) {
		[task setStandardInput:[NSPipe pipe]];
		inHandle = [[task standardInput] fileHandleForWriting];
	}
	
	@try {
		[task launch];
	}
	@catch (NSException *exception) {
		if (ret) *ret = -1;
		return nil;
	}

	if (input && inHandle) {
		// A large write could wait for stdout buffer to be flushed by the task,
		// which may not happen until the task is run. The task may similarly wait
		// for its stdout to be read before reading its stdin, causing a deadlock.
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			[inHandle writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
			[inHandle closeFile];
		});
	}
	
	NSData* data = [handle readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!string)
		string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];
	
	[task waitUntilExit];
	if (ret)
		*ret = [task terminationStatus];
	return string;
}	

// We don't use the above function because then we'd have to wait until the program was finished
// with running

+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args  inDir: (NSString*) dir
{
	NSTask *task = [self taskForCommand:cmd arguments:args inDirectory:dir];
	NSFileHandle* handle = [[task standardOutput] fileHandleForReading];
	
	[task launch];
	// This can cause a "Bad file descriptor"... when?
	NSData *data = nil;
	@try {
		data = [handle readDataToEndOfFile];
	}
	@catch (NSException * e) {
		NSLog(@"Got a bad file descriptor in %@!", NSStringFromSelector(_cmd));
		if ([NSThread currentThread] != [NSThread mainThread])
			[task waitUntilExit];

		return nil;
	}
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!string)
		string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];

	if ([NSThread currentThread] != [NSThread mainThread])
		[task waitUntilExit];

	return string;
}

+ (NSString *)outputForCommand:(NSString *)cmd withArgs:(NSArray *)args
{
	return [self outputForCommand:cmd withArgs:args inDir:nil];
}

/* Deprecated */

+ (NSTask *)taskForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir {
	return [self taskForCommand:cmd arguments:args inDirectory:dir];
}

+ (NSFileHandle *)handleForCommand:(NSString *)cmd withArgs:(NSArray *)arguments
{
	return [self handleForCommand:cmd withArgs:arguments inDir:nil];
}

+ (NSFileHandle *)handleForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir
{
	NSTask *task = [self taskForCommand:cmd arguments:args inDirectory:dir];
	NSFileHandle* handle = [[task standardOutput] fileHandleForReading];

	[task launch];
	return handle;
}

@end
