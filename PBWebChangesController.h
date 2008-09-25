//
//  PBWebChangesController.h
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebKit/WebKit.h"
#import "PBGitCommitController.h"
#import "PBChangedFile.h"

@interface PBWebChangesController : NSObject {
	IBOutlet WebView *view;
	IBOutlet NSArrayController *unstagedFilesController;
	IBOutlet NSArrayController *cachedFilesController;
	IBOutlet PBGitCommitController *controller;
	
	id previousFile;
}

- (void) showDiff:(PBChangedFile *)file;
@end
