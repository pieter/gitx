//
//  PBRemoteProgressSheetController.h
//  GitX
//
//  Created by Nathan Kinsinger on 12/6/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const kGitXProgressDescription;
extern NSString * const kGitXProgressSuccessDescription;
extern NSString * const kGitXProgressSuccessInfo;
extern NSString * const kGitXProgressErrorDescription;
extern NSString * const kGitXProgressErrorInfo;


@class PBGitRepository;

@interface PBRemoteProgressSheet : NSWindowController {
	NSWindowController *controller;

	NSArray  *arguments;
	NSString *title;
	NSString *description;
	bool hideSuccessScreen;

	NSTask    *gitTask;
	NSInteger  returnCode;

	NSTextField         *progressDescription;
	NSProgressIndicator *progressIndicator;

	NSTimer *taskTimer;
}

+ (void) beginRemoteProgressSheetForArguments:(NSArray *)args title:(NSString *)theTitle description:(NSString *)theDescription inDir:(NSString *)dir windowController:(NSWindowController *)windowController;
+ (void) beginRemoteProgressSheetForArguments:(NSArray *)args title:(NSString *)theTitle description:(NSString *)theDescription inDir:(NSString *)dir windowController:(NSWindowController *)windowController hideSuccessScreen:(bool)hideSucc;
+ (void) beginRemoteProgressSheetForArguments:(NSArray *)args title:(NSString *)theTitle description:(NSString *)theDescription inRepository:(PBGitRepository *)repo;
+ (void) beginRemoteProgressSheetForArguments:(NSArray *)args title:(NSString *)theTitle description:(NSString *)theDescription inRepository:(PBGitRepository *)repo hideSuccessScreen:(bool)hideSucc;


@property (assign) IBOutlet NSTextField         *progressDescription;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;


@end