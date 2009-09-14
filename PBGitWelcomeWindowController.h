//
//  PBGitWelcomeWindowController.h
//  GitX
//
//  Created by Pieter de Bie on 9/14/09.
//  Copyright 2009 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBGitWelcomeWindowController : NSWindowController {
	NSArray *recentItems;
	IBOutlet NSTableView *tableView;
	IBOutlet NSArrayController *itemController;
}

@property(readonly) NSArray *recentItems;
- (id)init;

- (IBAction)cancel:(id)sender;
- (IBAction)openOther:(id)sender;
- (IBAction)open:(id)sender;

@end
