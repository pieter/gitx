//
//  RJModalRepoSheet.h
//  GitX
//
//  Created by Rowan James on 1/7/12.
//  Copyright (c) 2012 Phere Development Pty. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBGitWindowController;

@interface RJModalRepoSheet : NSWindowController

@property (nonatomic, assign) PBGitWindowController* repoWindow;

- (id) initWithWindowNibName:(NSString *)windowNibName inRepoWindow:(PBGitWindowController*)parent;

- (void) show;
- (void) hide;

@end
