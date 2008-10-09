//
//  PBFileChangesTableView.m
//  GitX
//
//  Created by Pieter de Bie on 09-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBFileChangesTableView.h"
#import "PBGitCommitController.h"

@implementation PBFileChangesTableView

@synthesize controller;

#pragma mark NSTableView overrides
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if (controller)
		return [(PBGitCommitController *)controller menuForTable: self];

	return nil;
}
@end
