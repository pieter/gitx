//
//  PBGitXMessageSheet.h
//  GitX
//
//  Created by BrotherBard on 7/4/10.
//  Copyright 2010 BrotherBard. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RJModalRepoSheet.h"

@interface PBGitXMessageSheet : RJModalRepoSheet
{
	NSImageView *iconView;
	NSTextField *messageField;
	NSTextView *infoView;
	NSScrollView *scrollView;
}

+ (void)beginSheetWithMessage:(NSString *)message
						 info:(NSString *)info
			 windowController:(PBGitWindowController *)windowController;

+ (void)beginSheetWithError:(NSError *)error
		   windowController:(PBGitWindowController *)windowController;

- (void)beginMessageSheetWithMessageText:(NSString *)message
								infoText:(NSString *)info;
- (IBAction)closeMessageSheet:(id)sender;


@property  IBOutlet NSImageView *iconView;
@property  IBOutlet NSTextField *messageField;
@property  IBOutlet NSTextView *infoView;
@property  IBOutlet NSScrollView *scrollView;

@end
