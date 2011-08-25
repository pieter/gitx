//
//  OpenRecentController.m
//  GitX
//
//  Created by Hajo Nils Krabbenhöft on 07.10.10.
//  Copyright 2010 spratpix GmbH & Co. KG. All rights reserved.
//

#import "OpenRecentController.h"
#import "PBGitDefaults.h"
#import "PBRepositoryDocumentController.h"


@implementation OpenRecentController


+ (bool)run 
{
	OpenRecentController* new = [[OpenRecentController alloc] init];
	new->currentResults = [NSMutableArray array];
	[new->currentResults retain]; //FIXME: why ???
	new->possibleResults = [NSMutableArray array];
	[new->possibleResults retain]; //FIXME: why ???

	for (NSURL *url in [[NSDocumentController sharedDocumentController] recentDocumentURLs]) {
		[new->possibleResults addObject: url];
	}

	[NSBundle loadNibNamed: @"OpenRecentPopup" owner: new ];
	
	return [new->possibleResults count] > 0;
}

+ (void)openUrl:(NSURL*)url 
{
	NSError *error = nil;
	[[PBRepositoryDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error];
}


- (IBAction)doSearch: sender
{
	NSString *searchString = [searchField stringValue];
	
	while( [currentResults count] > 0 ) [currentResults removeLastObject];
	
    for(NSURL* url in possibleResults){
		NSString* label = [url lastPathComponent];
		if([searchString length] > 0) {
			NSRange aRange = [label rangeOfString: searchString options: NSCaseInsensitiveSearch];
			if (aRange.location == NSNotFound) continue;
		}
		[currentResults addObject: url];
    }   
	
	if( [currentResults count] > 0 )
		selectedResult = [currentResults objectAtIndex:0];
	else
		selectedResult = nil;
	
	[resultViewer reloadData];
}

- (void)awakeFromNib
{
    [resultViewer setTarget:self];
    [resultViewer setDoubleAction:@selector(tableDoubleClick:)];

	[searchWindow makeKeyAndOrderFront: nil];
	[self doSearch: nil];
}


- (void) tableDoubleClick:(id)sender 
{
	[self changeSelection:nil];
	if(selectedResult != nil) {
		[OpenRecentController openUrl:selectedResult];
	}
	[searchWindow orderOut:nil];
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;
    if (commandSelector == @selector(insertNewline:)) {
		if(selectedResult != nil) {
			[OpenRecentController openUrl:selectedResult];
		}
		[searchWindow orderOut:nil];
//		[searchWindow makeKeyAndOrderFront: nil];
		result = YES;
    }
	else if(commandSelector == @selector(cancelOperation:)) {
		[searchWindow orderOut:nil];
		result = YES;
	}
	else if(commandSelector == @selector(moveUp:)) {
		if(selectedResult != nil) {
			int index = [currentResults indexOfObject: selectedResult]-1;
			if(index < 0) index = 0;
			selectedResult = [currentResults objectAtIndex:index];
			[resultViewer selectRow:index byExtendingSelection:FALSE];
			[resultViewer scrollRowToVisible:index];
		}
		result = YES;
	}
	else if(commandSelector == @selector(moveDown:)) {
		if(selectedResult != nil) {
			int index = [currentResults indexOfObject: selectedResult]+1;
			if(index >= [currentResults count]) index = [currentResults count] - 1;
			selectedResult = [currentResults objectAtIndex:index];
			[resultViewer selectRow:index byExtendingSelection:FALSE];
			[resultViewer scrollRowToVisible:index];
		}
		result = YES;
	}
    return result;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{	
    id theValue = nil;
    NSParameterAssert(rowIndex >= 0 && rowIndex < [currentResults count]);
	
    NSURL* row = [currentResults objectAtIndex:rowIndex];
	if( [[aTableColumn identifier] isEqualToString: @"icon"] ) {
		id icon;
		NSError* error;
		[row getResourceValue:&icon forKey:NSURLEffectiveIconKey error:&error];
		return icon;
	} else if( [[aTableColumn identifier] isEqualToString: @"label"] ) {
		return [row lastPathComponent];
	}
    return theValue;
	
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView

{
	
    return [currentResults count];
	
}

- (IBAction)changeSelection: sender {
	int i = [resultViewer selectedRow];
	if(i >= 0 && i < [currentResults count])
		selectedResult = [currentResults objectAtIndex: i];
	else 
		selectedResult = nil;
}


@end
