//
//  PBChangedFile.m
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBChangedFile.h"
#import "PBEasyPipe.h"

@implementation PBChangedFile

@synthesize path, status;

- (id) initWithPath:(NSString *)p andRepository:(PBGitRepository *)r
{
	path = p;
	repository = r;
	return self;
}

- (NSString *) changes
{
	if (status == NEW)
		return [PBEasyPipe outputForCommand:@"/bin/cat" withArgs:[NSArray arrayWithObjects:@"cat-file", @"blob", path, nil] inDir:[repository workingDirectory]];
	else
		return [repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", @"HEAD", @"--", path, nil]];
}

- (NSImage *) icon
{
	NSString *filename;
	switch (status) {
		case NEW:
			filename = @"new_file";
			break;
		default:
			filename = @"empty_file";
			break;
	}
	NSString *p = [[NSBundle mainBundle] pathForResource:filename ofType:@"png"];
	return [[NSImage alloc] initByReferencingFile: p];
}
@end
