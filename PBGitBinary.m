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

static NSString* gitPath;

+ (void) initialize
{
	gitPath = nil;

	// Try to find the path of the Git binary
	char* path = getenv("GIT_PATH");
	if (path != nil) {
		gitPath = [NSString stringWithCString:path];
		return;
	}

	// No explicit path. Try it with "which"
	gitPath = [PBEasyPipe outputForCommand:@"/usr/bin/which" withArgs:[NSArray arrayWithObject:@"git"]];
	if (gitPath.length > 0)
		return;

	// Still no path. Let's try some default locations.
	for (NSString* location in [PBGitBinary searchLocations]) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:location]) {
			gitPath = location;
			return;
		}
	}

	NSLog(@"Could not find a git binary!");
}

+ (NSString *) path;
{
	return gitPath;
}

+ (NSArray *) searchLocations
{
	NSArray* locations = [NSArray arrayWithObjects:@"/opt/local/bin/git",
						  @"/sw/bin/git",
						  @"/opt/git/bin/git",
						  @"/usr/local/bin/git",
						  nil];
	return locations;
}

+ (NSString *) notFoundError
{
	NSMutableString *error = [NSMutableString stringWithString:
							  @"Could not find a git binary\n"
							  "Please make sure there is a git binary in one of the following locations:\n\n"];
	for (NSString *location in [PBGitBinary searchLocations]) {
		[error appendFormat:@"\t%@\n", location];
	}
	return error;
}

@end
