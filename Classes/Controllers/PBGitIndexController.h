//
//  PBGitIndexController.h
//  GitX
//
//  Created by Pieter de Bie on 18-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBGitIndexController : NSObject

@property (readonly) IBOutlet NSArrayController *stagedFilesController;
@property (readonly) IBOutlet NSArrayController *unstagedFilesController;

- (NSView *) nextKeyViewFor:(NSView *)view;
- (NSView *) previousKeyViewFor:(NSView *)view;

@end
