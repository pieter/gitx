//
//  GitRepoFinder.m
//  GitX
//
//  Created by Rowan James on 13/11/2012.
//
//

#import "GitRepoFinder.h"

@implementation GitRepoFinder

// For a given path inside a repository, return either the .git dir
// (for a bare repo) or the directory above the .git dir otherwise
+ (NSURL*)baseDirForURL:(NSURL*)fileURL;
{
	GTRepository* repo = [[GTRepository alloc] initWithURL:[self gitDirForURL:fileURL]
													 error:nil];
	NSURL* result = repo.fileURL;
	return result;
}

+ (NSURL *)gitDirForURL:(NSURL *)fileURL
{
	if (!fileURL.isFileURL)
	{
		return nil;
	}
	NSMutableData* repoPathBuffer = [NSMutableData dataWithLength:GIT_PATH_MAX];
	
	int gitResult = git_repository_discover(repoPathBuffer.mutableBytes,
											repoPathBuffer.length,
											[fileURL.path UTF8String],
											GIT_REPOSITORY_OPEN_CROSS_FS,
											nil);
	
	if (gitResult == GIT_OK)
	{
		NSString* repoPath = [NSString stringWithUTF8String:repoPathBuffer.bytes];
		BOOL isDirectory;
		if ([[NSFileManager defaultManager] fileExistsAtPath:repoPath
												 isDirectory:&isDirectory] && isDirectory)
		{
			NSURL* result = [NSURL fileURLWithPath:repoPath
									   isDirectory:isDirectory];
			return result;
		}
	}
	return nil;}

@end
