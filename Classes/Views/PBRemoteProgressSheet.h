//
//  PBRemoteProgressSheetController.h
//  GitX
//
//  Created by Nathan Kinsinger on 12/6/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RJModalRepoSheet.h"

extern NSString * const kGitXProgressDescription;
extern NSString * const kGitXProgressSuccessDescription;
extern NSString * const kGitXProgressSuccessInfo;
extern NSString * const kGitXProgressErrorDescription;
extern NSString * const kGitXProgressErrorInfo;

@class PBGitWindowController;
@class PBGitRepository;

@interface PBRemoteProgressSheet : RJModalRepoSheet

+ (void) beginRemoteProgressSheetWithTitle:(NSString *)theTitle
							   description:(NSString *)theDescription
								 arguments:(NSArray *)args
									 inDir:(NSString *)dir
						  windowController:(PBGitWindowController *)windowController;

+ (void) beginRemoteProgressSheetWithTitle:(NSString *)theTitle
							   description:(NSString *)theDescription
								 arguments:(NSArray *)args
						  windowController:(PBGitWindowController *)windowController;

+ (void) beginRemoteProgressSheetWithTitle:(NSString *)theTitle
							   description:(NSString *)theDescription
								 arguments:(NSArray *)args
						 hideSuccessScreen:(BOOL)hideSucc
						  windowController:(PBGitWindowController *)windowController;

@property  IBOutlet NSTextField         *progressDescription;
@property  IBOutlet NSProgressIndicator *progressIndicator;

@end