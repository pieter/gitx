//
//  PBGitCommitController.m
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommitController.h"


@implementation PBGitCommitController

@synthesize repository;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	if(self = [self initWithNibName:@"PBGitCommitView" bundle:nil]) {
		self.repository = theRepository;
		superController = controller;
	}
	
	return self;
}

@end
