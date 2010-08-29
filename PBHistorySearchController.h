//
//  PBHistorySearchController.h
//  GitX
//
//  Created by Nathan Kinsinger on 8/21/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PBGitHistoryController;


@interface PBHistorySearchController : NSObject {
	PBGitHistoryController *historyController;
	NSArrayController *commitController;

	NSIndexSet *results;

	NSSearchField *searchField;
	NSSegmentedControl *stepper;
	NSTextField *numberOfMatchesField;

	NSPanel *rewindPanel;
}

@property (assign) IBOutlet PBGitHistoryController *historyController;
@property (assign) IBOutlet NSArrayController *commitController;

@property (assign) IBOutlet NSSearchField *searchField;
@property (assign) IBOutlet NSSegmentedControl *stepper;
@property (assign) IBOutlet NSTextField *numberOfMatchesField;


- (BOOL)isRowInSearchResults:(NSInteger)rowIndex;
- (BOOL)hasSearchResults;

- (void)selectNextResult;
- (void)selectPreviousResult;
- (IBAction)stepperPressed:(id)sender;

- (void)clearSearch;
- (IBAction)updateSearch:(id)sender;

@end
