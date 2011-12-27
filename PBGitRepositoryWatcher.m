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

#import <ObjectiveGit/ObjectiveGit.h>

NSString *PBGitRepositoryEventNotification = @"PBGitRepositoryModifiedNotification";
NSString *kPBGitRepositoryEventTypeUserInfoKey = @"kPBGitRepositoryEventTypeUserInfoKey";
NSString *kPBGitRepositoryEventPathsUserInfoKey = @"kPBGitRepositoryEventPathsUserInfoKey";

@interface PBGitRepositoryWatcher ()
- (void) _handleEventCallback:(NSArray *)eventPaths;
@end

void PBGitRepositoryWatcherCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, 
										size_t numEvents, void *eventPaths, 
										const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]){
    PBGitRepositoryWatcher *watcher = (__bridge PBGitRepositoryWatcher*)clientCallBackInfo;
	NSMutableArray *changePaths = [[NSMutableArray alloc] init];
	for (int i = 0; i < numEvents; ++i) {
//		NSLog(@"FSEvent Watcher: %@ Change %llu in %s, flags %lu", watcher, eventIds[i], paths[i], eventFlags[i]);

		PBGitRepositoryWatcherEventPath *ep = [[PBGitRepositoryWatcherEventPath alloc] init];
		ep.path = [(__bridge NSArray*)eventPaths objectAtIndex:i];
		ep.flag = eventFlags[i];
		[changePaths addObject:ep];
		
	}
    [watcher _handleEventCallback:changePaths];
}

@implementation PBGitRepositoryWatcher

@synthesize repository;

- (id) initWithRepository:(PBGitRepository *)theRepository {
    self = [super init];
    if (!self)
        return nil;

	repository = theRepository;
	FSEventStreamContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

	NSString *path = [repository isBareRepository] ? repository.fileURL.path : [repository workingDirectory];
	NSArray *paths = [NSArray arrayWithObject: path];

	// Create and activate event stream
	eventStream = FSEventStreamCreate(kCFAllocatorDefault, PBGitRepositoryWatcherCallback, &context, 
									  (__bridge CFArrayRef)paths,
									  kFSEventStreamEventIdSinceNow, 1.0,
									  kFSEventStreamCreateFlagUseCFTypes);
	if ([PBGitDefaults useRepositoryWatcher])
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

	for (NSURL* fileURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:repository.fileURL
														 includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey]
																			options:0
						
																			  error:nil])
	{
		BOOL isDirectory = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
		if (isDirectory) 
			continue;

		NSDate* modTime = nil;
		if (![fileURL getResourceValue:&modTime forKey:NSURLContentModificationDateKey error:nil])
			continue;
		
		if (gitDirTouchDate == nil || [modTime compare:gitDirTouchDate] == NSOrderedDescending)
		{
			NSDate* newModTime = [modTime laterDate:gitDirTouchDate];
			
			gitDirTouchDate = newModTime;
			return YES;
		}
	}
    return NO;
}

- (void) _handleEventCallback:(NSArray *)eventPaths {
	PBGitRepositoryWatcherEventType event = 0x0;
	
	if ([self _indexChanged])
		event |= PBGitRepositoryWatcherEventTypeIndex;
	
	NSString* ourRepo_ns = repository.fileURL.path;
	// libgit2 API results for directories end with a '/'
	if (![ourRepo_ns hasSuffix:@"/"])
		ourRepo_ns = [NSString stringWithFormat:@"%@/", ourRepo_ns];
	
	const char* ourRepoPath = [ourRepo_ns UTF8String];
	
	// We only use the event path buffer for testing equality to our own repo
	// so it's okay to consider failure due to buffer size as inequality.
	const int eventPathRepoBufferSize = strlen(ourRepoPath) + 2;
	char *eventPathRepoBuffer = malloc(eventPathRepoBufferSize);
	
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
			// check that the repo for the changed path is ours, otherwise
			// it's most likely a submodule, or a nested clone.  Either way,
			// we shouldn't be committing to it ourselves.

		
			int discoverStatus = git_repository_discover(eventPathRepoBuffer, eventPathRepoBufferSize,
														 [eventPath.path UTF8String],
														 1 /* cross filesystem boundaries, if necessary*/,
														 ourRepoPath);
			if (GIT_SUCCESS == discoverStatus &&
				strcmp(ourRepoPath, eventPathRepoBuffer) == 0)
				{
					event |= PBGitRepositoryWatcherEventTypeWorkingDirectory;
					[paths addObject:eventPath.path];
				}
//			}
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
	
	free(eventPathRepoBuffer);
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

@end
