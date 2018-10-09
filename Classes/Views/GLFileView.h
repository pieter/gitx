//
//  GLFileView.h
//  GitX
//
//  Created by German Laullon on 14/09/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBWebController.h"

@class PBGitHistoryController;

@interface GLFileView : PBWebController {
	__weak IBOutlet PBGitHistoryController* historyController;
	__weak IBOutlet NSView *accessoryView;
	__weak IBOutlet NSSplitView *fileListSplitView;
}

- (void)showFile;
- (void)didLoad;
- (NSString *)parseBlame:(NSString *)txt;
- (NSString *)escapeHTML:(NSString *)txt;

@property NSMutableArray *groups;

@end
