//
//  PBTask.m
//  GitX
//
//  Created by Etienne on 22/02/2017.
//
//

#import "PBTask.h"

NSString *const PBTaskErrorDomain = @"PBTaskErrorDomain";
NSString *const PBTaskUnderlyingExceptionKey = @"PBTaskUnderlyingExceptionKey";
NSString *const PBTaskTerminationStatusKey = @"PBTaskTerminationStatusKey";
NSString *const PBTaskTerminationOutputKey = @"PBTaskTerminationOutputKey";

@interface PBTask ()

@property (retain) NSTask *task;

@end

@implementation PBTask

+ (instancetype)taskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments inDirectory:(NSString *)directory {
	return [[self alloc] initWithLaunchPath:launchPath arguments:arguments inDirectory:directory];
}

- (instancetype)initWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)args inDirectory:(NSString *)directory
{
	self = [super init];
	if (!self) return nil;

	_task = [[NSTask alloc] init];
	[_task setLaunchPath:launchPath];
	[_task setArguments:args];

	// Prepare ourselves a nicer environment
	NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
	[env removeObjectsForKeys:@[@"MallocStackLogging", @"MallocStackLoggingNoCompact", @"NSZombieEnabled"]];
	if (self.additionalEnvironment) {
		[env addEntriesFromDictionary:self.additionalEnvironment];
	}
	[_task setEnvironment:env];

	if (directory)
		[_task setCurrentDirectoryPath:directory];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Debug Messages"])
		NSLog(@"Starting command `%@ %@` in dir %@", launchPath, [args componentsJoinedByString:@" "], directory);
#ifdef CLI
	NSLog(@"Starting command `%@ %@` in dir %@", launchPath, [args componentsJoinedByString:@" "], directory);
#endif

	NSPipe *pipe = [NSPipe pipe];
	[_task setStandardOutput:pipe];
	[_task setStandardError:pipe];

	return self;
}


- (void)performTaskWithTerminationHandler:(void (^)(NSError *error))terminationHandler {
	NSParameterAssert(terminationHandler != nil);

	self.task.terminationHandler = ^(NSTask *task) {
		NSError *error = nil;
		if (task.terminationReason == NSTaskTerminationReasonUncaughtSignal) {

			NSString *desc = @"Task killed";
			NSArray *taskArguments = [@[task.launchPath] arrayByAddingObjectsFromArray:task.arguments];
			NSString *failureReason = [NSString stringWithFormat:@"The task \"%@\" caught a termination signal", taskArguments];
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: desc,
									   NSLocalizedFailureReasonErrorKey: failureReason,
									   };
			error = [NSError errorWithDomain:PBTaskErrorDomain code:PBTaskCaughtSignalError userInfo:userInfo];

		} else if (task.terminationReason == NSTaskTerminationReasonExit && task.terminationStatus != 0) {

			NSString *desc = @"Task exited unsuccessfully";
			NSArray *taskArguments = [@[task.launchPath] arrayByAddingObjectsFromArray:task.arguments];
			NSString *failureReason = [NSString stringWithFormat:@"The task \"%@\" returned a non-zero return code", taskArguments];
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: desc,
									   NSLocalizedFailureReasonErrorKey: failureReason,
									   PBTaskTerminationStatusKey: @(task.terminationStatus),
									   };
			error = [NSError errorWithDomain:PBTaskErrorDomain code:PBTaskNonZeroExitCodeError userInfo:userInfo];

		}

		terminationHandler(error);
	};

	if (self.standardInputData) {
		NSPipe *inputPipe = [NSPipe pipe];

		self.task.standardInput = inputPipe;

		inputPipe.fileHandleForWriting.writeabilityHandler = ^(NSFileHandle *handle) {
			[handle writeData:self.standardInputData];
			[handle closeFile];
		};
	}

	@try {
		[self.task launch];
	}
	@catch (NSException *exception) {
		NSString *desc = @"Exception raised while launching task";
		NSString *failureReason = [NSString stringWithFormat:@"The task \"%@\" failed to launch", self.task.launchPath];
		NSDictionary *info = @{
							   NSLocalizedDescriptionKey: desc,
							   NSLocalizedFailureReasonErrorKey: failureReason,
							   PBTaskUnderlyingExceptionKey: exception,
							   };
		NSError *error = [NSError errorWithDomain:PBTaskErrorDomain
											 code:PBTaskLaunchError
										 userInfo:info];
		terminationHandler(error);
	}
}

- (void)performTaskWithCompletionHandler:(void (^)(NSData *readData, NSError *error))completionHandler {
	return [self performTaskWithTerminationHandler:^(NSError *error) {
		if (error) {
			completionHandler(nil, error);
			return;
		}

		NSData *data = [[self.task.standardOutput fileHandleForReading] readDataToEndOfFile];
		completionHandler(data, nil);
	}];
}

- (BOOL)launchTask:(NSError **)error {
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);

	__block NSError *taskError = nil;
	[self performTaskWithCompletionHandler:^(NSData *readData, NSError *error) {

		_standardOutputData = readData;
		taskError = error;

		dispatch_semaphore_signal(sem);
	}];

	dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC);
	if (dispatch_semaphore_wait(sem, timeout) != 0) {
		// Timeout !
		// Unset the termination handler before calling, so we don't trigger it
		self.task.terminationHandler = nil;
		[self terminate];

		if (error) {
			NSString *desc = @"Timeout while running task";
			NSArray *taskArguments = [@[self.task.launchPath] arrayByAddingObjectsFromArray:self.task.arguments];
			NSString *failureReason = [NSString stringWithFormat:@"The task \"%@\" failed to complete before its timeout", taskArguments];
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: desc,
									   NSLocalizedFailureReasonErrorKey: failureReason,
									   };
			*error = [NSError errorWithDomain:PBTaskErrorDomain code:PBTaskTimeoutError userInfo:userInfo];
		}

		return NO;
	}

	return YES;
}

- (void)terminate {
	[self.task terminate];
}

@end

@implementation PBTask (PBBellsAndWhistles)

+ (NSString *)outputForCommand:(NSString *)launchPath arguments:(NSArray *)arguments {
	PBTask *task = [self taskWithLaunchPath:launchPath arguments:arguments inDirectory:nil];
	BOOL success = [task launchTask:NULL];
	if (!success) return nil;

	return [[NSString alloc] initWithData:task.standardOutputData encoding:NSUTF8StringEncoding];
}

+ (void)launchTask:(NSString *)launchPath arguments:(NSArray *)arguments inDirectory:(NSString *)directory completionHandler:(void (^)(NSData *readData, NSError *error))completionHandler {
	PBTask *task = [self taskWithLaunchPath:launchPath arguments:arguments inDirectory:directory];
	[task performTaskWithCompletionHandler:completionHandler];
}


@end
