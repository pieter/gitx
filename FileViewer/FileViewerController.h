//
//  FileViewerController.h
//  GitX
//
//  Created by German Laullon on 11/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MGScopeBar.h"
#import "PBGitRepository.h"

@interface FileViewerController : NSViewController <MGScopeBarDelegate> {
	IBOutlet NSSegmentedCell *displayControl;
	IBOutlet MGScopeBar *scopeBar;
	IBOutlet WebView *webViewFileViwer;

	NSMutableArray *groups;
	NSString *file;
	NSString *sha;

	PBGitRepository *repository;
	id controller;
	bool commit;
}

- (id)initWithRepository:(PBGitRepository *)theRepository andController:(id)theController;
- (void)showFile:(NSString *)file sha:(NSString *)sha;
- (NSString*)refSpec;

-(NSString *)parseLog:(NSString *)string;
-(NSString *)parseBlame:(NSString *)string;

@property(retain) NSMutableArray *groups;
@property(readwrite) bool commit;

@end
