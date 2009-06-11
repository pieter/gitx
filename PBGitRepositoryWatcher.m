//
//  PBGitRepositoryWatcher.m
//  GitX
//
//  Created by Dave Grijalva on 1/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <CoreServices/CoreServices.h>
#import "PBGitRepositoryWatcher.h"
#import "PBEasyPipe.h"
#import "PBGitDefaults.h"
#import "PBGitRepositoryWatcherEventPath.h"

NSString *PBGitRepositoryEventNotification = @"PBGitRepositoryModifiedNotification";
NSString *kPBGitRepositoryEventTypeUserInfoKey = @"kPBGitRepositoryEventTypeUserInfoKey";
NSString *kPBGitRepositoryEventPathsUserInfoKey = @"kPBGitRepositoryEventPathsUserInfoKey";

@interface PBGitRepositoryWatcher ()
- (void) _handleEventCallback:(NSArray *)eventPaths;
@end

static void PBGitRepositoryWatcherCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, 
										size_t numEvents, void *eventPaths, 
										const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]){
    PBGitRepositoryWatcher *watcher = clientCallBackInfo;
	int i;
    char **paths = eventPaths;
	NSMutableArray *changePaths = [[NSMutableArray alloc] init];
	for (i = 0; i < numEvents; ++i) {
//		NSLog(@"FSEvent Watcher: %@ Change %llu in %s, flags %lu", watcher, eventIds[i], paths[i], eventFlags[i]);

		PBGitRepositoryWatcherEventPath *ep = [[PBGitRepositoryWatcherEventPath alloc] init];
		ep.path = [NSString stringWithFormat:@"%s", paths[i]];
		ep.flag = eventFlags[i];
		[changePaths addObject:ep];
		[ep release];
		
	}
    [watcher _handleEventCallback:changePaths];
	[changePaths release];
}

@implementation PBGitRepositoryWatcher

@synthesize repository;

- (id) initWithRepository:(PBGitRepository *)theRepository {
    if (self != [super init])
		return nil;

	repository = theRepository;
	FSEventStreamContext context = {0, self, NULL, NULL, NULL};

	NSString *path = [repository isBareRepository] ? repository.fileURL.path : [repository workingDirectory];
	NSArray *paths = [NSArray arrayWithObject: path];

	// Create and activate event stream
	eventStream = FSEventStreamCreate(kCFAllocatorDefault, &PBGitRepositoryWatcherCallback, &context, 
									  (CFArrayRef)paths,
									  kFSEventStreamEventIdSinceNow, 1.0, kFSEventStreamCreateFlagNone);
	[self start];
    return self;
}

- (NSDate *) _fileModificationDateAtPath:(NSString *)path {
    NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	return [attrs objectForKey:NSFileModificationDate];
}

- (BOOL) _indexChanged {
    NSDate *newTouchDate = [self _fileModificationDateAtPath:[repository.fileURL.path stringByAppendingPathComponent:@"index"]];
	if (![newTouchDate isEqual:indexTouchDate]) {
		indexTouchDate = newTouchDate;
		return YES;
	}

	return NO;
}

- (BOOL) _gitDirectoryChanged {
	BOOL isDirectory;
    NSDate *touchDate;

	for (NSString *filename in [[NSFileManager defaultManager] directoryContentsAtPath:repository.fileURL.path]) {
		NSString *filepath = [repository.fileURL.path stringByAppendingPathComponent:filename];
		[[NSFileManager defaultManager] fileExistsAtPath:filepath isDirectory:&isDirectory];
		if (isDirectory) 
			continue;

		touchDate = [self _fileModificationDateAtPath:filepath];
		if ([gitDirTouchDate isLessThan:touchDate]) {
			gitDirTouchDate = touchDate;
			return YES;
		}
	}
    return NO;
}

- (void) _handleEventCallback:(NSArray *)eventPaths {
	PBGitRepositoryWatcherEventType event = 0x0;

	if ([self _indexChanged])
		event |= PBGitRepositoryWatcherEventTypeIndex;
	
    NSMutableArray *paths = [NSMutableArray array];
    
	for (PBGitRepositoryWatcherEventPath *eventPath in eventPaths) {
		// .git dir
		if ([[eventPath.path stringByStandardizingPath] isEqual:[repository.fileURL.path stringByStandardizingPath]]) {
			if ([self _gitDirectoryChanged] || eventPath.flag != kFSEventStreamEventFlagNone) {
				event |= PBGitRepositoryWatcherEventTypeGitDirectory;
                [paths addObject:eventPath.path];
			}
		}

		// subdirs of .git dir
		else if ([eventPath.path rangeOfString:repository.fileURL.path].location != NSNotFound) {
			event |= PBGitRepositoryWatcherEventTypeGitDirectory;
            [paths addObject:eventPath.path];
		}

		// working dir
		else if([[eventPath.path stringByStandardizingPath] isEqual:[[repository workingDirectory] stringByStandardizingPath]]){
			if (eventPath.flag != kFSEventStreamEventFlagNone)
				event |= PBGitRepositoryWatcherEventTypeGitDirectory;

			event |= PBGitRepositoryWatcherEventTypeWorkingDirectory;
            [paths addObject:eventPath.path];
		}

		// subdirs of working dir
		else {
			event |= PBGitRepositoryWatcherEventTypeWorkingDirectory;
            [paths addObject:eventPath.path];
		}
	}
	
	if(event != 0x0){
//		NSLog(@"PBGitRepositoryWatcher firing notification for repository %@ with flag %lu", repository, event);
        NSDictionary *eventInfo = [NSDictionary dictionaryWithObjectsAndKeys: 
                                   [NSNumber numberWithUnsignedInt:event], kPBGitRepositoryEventTypeUserInfoKey,
                                   paths, kPBGitRepositoryEventPathsUserInfoKey,
                                   NULL];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:PBGitRepositoryEventNotification object:repository userInfo:eventInfo];
	}
}

- (void) start {
    if (_running)
		return;

	// set initial state
	[self _gitDirectoryChanged];
	[self _indexChanged];
	FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(eventStream);
	_running = YES;
}

- (void) stop {
    if (!_running)
		return;

	FSEventStreamStop(eventStream);
	FSEventStreamUnscheduleFromRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	_running = NO;
}

- (void) finalize {
    // cleanup 
    [self stop];
    FSEventStreamInvalidate(eventStream);
    FSEventStreamRelease(eventStream);
	
	[super finalize];
}

- (void) dealloc {
	[self finalize];
	
    [repository release];
    [super dealloc];
}

@end
