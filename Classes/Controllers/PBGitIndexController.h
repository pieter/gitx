//
//  PBGitIndexController.h
//  GitX
//
//  Created by Pieter de Bie on 18-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBGitCommitController;
@class PBChangedFile;
@class GTSubmodule;

@interface PBGitIndexController : NSObject

@property (readonly) IBOutlet NSArrayController *stagedFilesController;
@property (readonly) IBOutlet NSArrayController *unstagedFilesController;

@property (readonly) IBOutlet NSTableView *unstagedTable;
@property (readonly) IBOutlet NSTableView *stagedTable;

- (IBAction) rowClicked:(NSCell *) sender;
- (IBAction) tableClicked:(NSTableView *)tableView;

- (NSMenu *) menuForTable:(NSTableView *)table;
- (NSView *) nextKeyViewFor:(NSView *)view;
- (NSView *) previousKeyViewFor:(NSView *)view;

@end
