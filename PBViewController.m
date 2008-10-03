//
//  PBViewController.m
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBViewController.h"


@implementation PBViewController

@synthesize repository, viewToolbar;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	NSString *nibName = [[[self class] description] stringByReplacingOccurrencesOfString:@"Controller"
																			  withString:@"View"];
	if(self = [self initWithNibName:nibName bundle:nil]) {
		repository = theRepository;
		superController = controller;
	}
	
	return self;
}

- (void) removeView
{
	[[self view] removeFromSuperview];	// remove the current view
}

- (void) awakeFromNib
{
	if (viewToolbar)
		[superController useToolbar:viewToolbar];
	else
		[superController useToolbar:[[NSToolbar alloc] initWithIdentifier:@"EmptyBar"]];
}
@end
