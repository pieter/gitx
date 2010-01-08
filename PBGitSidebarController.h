//
//  PBGitSidebar.h
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBViewController.h"

@class PBSourceViewItem;

@interface PBGitSidebarController : PBViewController {
	IBOutlet NSWindow *window;
	IBOutlet NSOutlineView *sourceView;

	NSMutableArray *items;

	/* Specific things */
	PBSourceViewItem *stage;

	PBSourceViewItem *branches, *remotes, *tags, *others;
}

@property(readonly) NSMutableArray *items;
@end
