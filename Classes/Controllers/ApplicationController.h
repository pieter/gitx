//
//  GitTest_AppDelegate.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@class PBCloneRepositoryPanel;

@interface ApplicationController : NSObject<NSApplicationDelegate>
{
	IBOutlet NSWindow *window;
	IBOutlet id firstResponder;

	PBCloneRepositoryPanel *cloneRepositoryPanel;
	bool started;
}

- (IBAction)showAboutPanel:(id)sender;

- (IBAction)showHelp:(id)sender;
- (IBAction)showChangeLog:(id)sender;
- (IBAction)reportAProblem:(id)sender;

- (IBAction)showCloneRepository:(id)sender;
@end
