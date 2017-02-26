//
//  RJModalRepoSheet.h
//  GitX
//
//  Created by Rowan James on 1/7/12.
//  Copyright (c) 2012 Phere Development Pty. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBGitRepository;
@class PBGitWindowController;
@class PBGitRepositoryDocument;

NS_ASSUME_NONNULL_BEGIN

@interface RJModalRepoSheet : NSWindowController

@property (nonnull, strong) PBGitWindowController *windowController;
@property (nonnull, assign) PBGitRepositoryDocument *document;
@property (nonnull, readonly) PBGitRepository *repository;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName windowController:(PBGitWindowController *)windowController;

- (void) show;
- (void) hide;

@end

NS_ASSUME_NONNULL_END
