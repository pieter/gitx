//
//  PBGitBinary.m
//  GitX
//
//  Created by Pieter de Bie on 04-10-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitBinary.h"
#import "PBEasyPipe.h"

@implementation PBGitBinary

static NSString* gitPath = nil;

+ (NSString *)versionForPath:(NSString *)path
{
	if (!path)
		return nil;

	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
		return nil;

	NSString *version = [PBEasyPipe outputForCommand:path withArgs:[NSArray arrayWithObject:@"--version"]];
	if ([version hasPrefix:@"git version "])
		return [version substringFromIndex:12];

	return nil;
}

+ (BOOL) acceptBinary:(NSString *)path
{
	if (!path)
		return NO;

	NSString *version = [self versionForPath:path];
	if (!version)
		return NO;

	int c = [version compare:@"1.5.4"];
	if (c == NSOrderedSame || c == NSOrderedDescending) {
		gitPath = path;
		return YES;
	}

	NSLog(@"Found a git binary at %@, but is only version %@", path, version);
	return NO;
}

+ (void) initialize
{
	// Check what we might have in user defaults
	// NOTE: Currently this should NOT have a registered default, or the searching bits below won't work
	gitPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"gitExecutable"];
	if (gitPath.length > 0)
		return;

	// Try to find the path of the Git binary
	char* path = getenv("GIT_PATH");
	if (path && [self acceptBinary:[NSString stringWithCString:path]])
		return;

	// No explicit path. Try it with "which"
	NSString *whichPath = [PBEasyPipe outputForCommand:@"/usr/bin/which" withArgs:[NSArray arrayWithObject:@"git"]];
	if ([self acceptBinary:whichPath])
		return;

	// Still no path. Let's try some default locations.
	for (NSString* location in [PBGitBinary searchLocations]) {
		if ([self acceptBinary:location])
			return;
	}

	NSLog(@"Could not find a git binary higher than version 1.5.4.");
}

+ (NSString *) path;
{
	return gitPath;
}

static NSMutableArray *locations = nil;

+ (NSArray *) searchLocations
{
	if (locations)
		return locations;

	locations = [NSMutableArray arrayWithObjects:@"/opt/local/bin/git",
						  @"/sw/bin/git",
						  @"/opt/git/bin/git",
						  @"/usr/local/bin/git",
						  @"/usr/local/git/bin/git",
						  nil];

	[locations addObject:[@"~/bin/git" stringByExpandingTildeInPath]];
	return locations;
}

+ (NSString *) notFoundError
{
	NSMutableString *error = [NSMutableString stringWithString:
							  @"Could not find a git binary version 1.5.4 or higher.\n"
							  "Please make sure there is a git binary in one of the following locations:\n\n"];
	for (NSString *location in [PBGitBinary searchLocations]) {
		[error appendFormat:@"\t%@\n", location];
	}
	return error;
}


+ (NSString *)version
{
	return [self versionForPath:gitPath];
}


@end
