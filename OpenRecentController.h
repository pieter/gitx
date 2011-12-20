//
//  OpenRecentController.h
//  GitX
//
//  Created by Hajo Nils Krabbenhöft on 07.10.10.
//  Copyright 2010 spratpix GmbH & Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface OpenRecentController : NSViewController<NSTableViewDataSource, NSTableViewDelegate> {
	IBOutlet NSSearchField* searchField;
	IBOutlet NSWindow* searchWindow;
	NSMutableArray* currentResults;
	NSMutableArray* possibleResults;
	NSURL* selectedResult;
	IBOutlet NSTableView* resultViewer;	
}

+ (bool)run;
+ (void)openUrl:(NSURL*)url;
- (IBAction)doSearch: sender;
- (IBAction)changeSelection: sender;
- (void) tableDoubleClick:(id)sender;


@end
