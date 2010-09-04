//
//  PBHistorySearchController.m
//  GitX
//
//  Created by Nathan Kinsinger on 8/21/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import "PBHistorySearchController.h"
#import "PBGitHistoryController.h"
#import "PBGitRepository.h"
#import <QuartzCore/CoreAnimation.h>


@interface PBHistorySearchController ()

- (void)selectNextResultInDirection:(NSInteger)direction;

- (void)updateUI;
- (void)setupSearchMenuTemplate;

- (void)startBasicSearch;

- (void)showSearchRewindPanelReverse:(BOOL)isReversed;

@end


#define kGitXSearchDirectionNext 1
#define kGitXSearchDirectionPrevious -1

#define kGitXBasicSearchLabel @"Subject, Author, SHA"

#define kGitXSearchArrangedObjectsContext @"GitXSearchArrangedObjectsContext"


@implementation PBHistorySearchController

@synthesize historyController;
@synthesize commitController;

@synthesize searchField;
@synthesize stepper;
@synthesize numberOfMatchesField;



#pragma mark -
#pragma mark Public methods

- (BOOL)isRowInSearchResults:(NSInteger)rowIndex
{
	return [results containsIndex:rowIndex];
}

- (BOOL)hasSearchResults
{
	return ([results count] > 0);
}

- (void)selectNextResult
{
	[self selectNextResultInDirection:kGitXSearchDirectionNext];
}

- (void)selectPreviousResult
{
	[self selectNextResultInDirection:kGitXSearchDirectionPrevious];
}

- (IBAction)stepperPressed:(id)sender
{
	NSInteger selectedSegment = [sender selectedSegment];

	if (selectedSegment == 0)
		[self selectPreviousResult];
	else
		[self selectNextResult];
}

- (void)clearSearch
{
	[searchField setStringValue:@""];
	if (results) {
		results = nil;
		[historyController.commitList reloadData];
	}
	[self updateUI];
}

- (IBAction)updateSearch:(id)sender
{
	[self startBasicSearch];
}

- (void)awakeFromNib
{
	[self setupSearchMenuTemplate];
	[[searchField cell] setPlaceholderString:@"Subject, Author, SHA"];

	[self updateUI];

	[commitController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:kGitXSearchArrangedObjectsContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(NSString *)context isEqualToString:kGitXSearchArrangedObjectsContext]) {
		// the objects in the commitlist changed so the result indexes are no longer valid
		[self clearSearch];
		return;
	}

	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



#pragma mark -
#pragma mark Private methods

- (void)selectIndex:(NSUInteger)index
{
	if ([[commitController arrangedObjects] count] > index) {
		PBGitCommit *commit = [[commitController arrangedObjects] objectAtIndex:index];
		[historyController selectCommit:[commit sha]];
	}
}

- (void)selectNextResultInDirection:(NSInteger)direction
{
	if (![results count])
		return;

	NSUInteger selectedRow = [historyController.commitList selectedRow];
	if (selectedRow == NSNotFound) {
		[self selectIndex:[results firstIndex]];
		return;
	}

	NSUInteger currentResult = NSNotFound;
	if (direction == kGitXSearchDirectionNext)
		currentResult = [results indexGreaterThanIndex:selectedRow];
	else
		currentResult = [results indexLessThanIndex:selectedRow];

	if (currentResult == NSNotFound) {
		if (direction == kGitXSearchDirectionNext)
			currentResult = [results firstIndex];
		else
			currentResult = [results lastIndex];

		[self showSearchRewindPanelReverse:(direction != kGitXSearchDirectionNext)];
	}

	[self selectIndex:currentResult];
}

- (NSString *)numberOfMatchesString
{
	NSUInteger numberOfMatches = [results count];

	if (numberOfMatches == 0)
		return @"Not found";

	if (numberOfMatches == 1)
		return @"1 match";

	return [NSString stringWithFormat:@"%d matches", numberOfMatches];
}

- (void)updateUI
{
	if ([[searchField stringValue] isEqualToString:@""]) {
		[numberOfMatchesField setHidden:YES];
		[stepper setHidden:YES];
	}
	else {
		[numberOfMatchesField setStringValue:[self numberOfMatchesString]];
		[numberOfMatchesField setHidden:NO];
		[stepper setHidden:NO];
		[historyController.commitList reloadData];
	}
}

// changes the selection to the next match after the current selected row unless the current row is already a match
- (void)updateSelectedResult
{
	NSString *searchString = [searchField stringValue];
	if ([searchString isEqualToString:@""]) {
		[self clearSearch];
		return;
	}

	if (![self isRowInSearchResults:[historyController.commitList selectedRow]])
		[self selectNextResult];

	[self updateUI];
}

- (void)setupSearchMenuTemplate
{
	NSMenu *searchMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
    NSMenuItem *item;

	item = [[NSMenuItem alloc] initWithTitle:@"Recent Searches" action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [searchMenu addItem:item];

    item = [[NSMenuItem alloc] initWithTitle:@"Recents" action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsMenuItemTag];
    [searchMenu addItem:item];

    item = [NSMenuItem separatorItem];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [searchMenu addItem:item];

	item = [[NSMenuItem alloc] initWithTitle:@"Clear Recent Searches" action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldClearRecentsMenuItemTag];
    [searchMenu addItem:item];

	item = [[NSMenuItem alloc] initWithTitle:@"No Recent Searches" action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldNoRecentsMenuItemTag];
    [searchMenu addItem:item];

    [[searchField cell] setSearchMenuTemplate:searchMenu];
}



#pragma mark Basic Search

- (void)startBasicSearch
{
	NSString *searchString = [searchField stringValue];
	if ([searchString isEqualToString:@""]) {
		[self clearSearch];
		return;
	}

	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"subject CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR realSha BEGINSWITH[c] %@", searchString, searchString, searchString];

	NSUInteger index = 0;
	for (PBGitCommit *commit in [commitController arrangedObjects]) {
		if ([searchPredicate evaluateWithObject:commit])
			[indexes addIndex:index];
		index++;
	}

	results = indexes;

	[self updateSelectedResult];
}



#pragma mark -
#pragma mark Rewind Panel

#define kRewindPanelSize 125.0f

- (void)closeRewindPanel
{
	[[[historyController view] window] removeChildWindow:rewindPanel];
	[rewindPanel close];
	rewindPanel = nil;
}

- (NSPanel *)rewindPanelReverse:(BOOL)isReversed
{
	NSRect windowFrame = [[[historyController view] window] frame];
	NSRect historyFrame = [[historyController view] convertRectToBase:[[historyController view] frame]];
	NSRect panelRect = NSMakeRect(0.0f, 0.0f, kRewindPanelSize, kRewindPanelSize);
	panelRect.origin.x = windowFrame.origin.x + historyFrame.origin.x + ((historyFrame.size.width - kRewindPanelSize) / 2.0f);
	panelRect.origin.y = windowFrame.origin.y + historyFrame.origin.y + ((historyFrame.size.height - kRewindPanelSize) / 2.0f);

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:panelRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered 
													defer:YES];
	[panel setIgnoresMouseEvents:YES];
	[panel setOneShot:YES];
	[panel setOpaque:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setHasShadow:NO];
	[panel useOptimizedDrawing:YES];
	[panel setAlphaValue:0.0f];

	NSBox *box = [[NSBox alloc] initWithFrame:[[panel contentView] frame]];
	[box setBoxType:NSBoxCustom];
	[box setBorderType:NSLineBorder];
	[box setFillColor:[NSColor colorWithCalibratedWhite:0.0f alpha:0.5f]];
	[box setBorderColor:[NSColor colorWithCalibratedWhite:0.5f alpha:0.5f]];
	[box setCornerRadius:12.0f];
	[[panel contentView] addSubview:box];

	NSImage *rewindImage = [[NSImage imageNamed:@"rewindImage"] copy];
	[rewindImage setFlipped:isReversed];
	NSSize imageSize = [rewindImage size];
	NSRect imageViewFrame = NSMakeRect(21.0f, 5.0f, imageSize.width, imageSize.height);
	NSImageView *rewindImageView = [[NSImageView alloc] initWithFrame:imageViewFrame];
	[rewindImageView setImage:rewindImage];
	[[box contentView] addSubview:rewindImageView];

	return panel;
}

- (CAKeyframeAnimation *)rewindPanelFadeOutAnimation
{
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
	animation.duration = 1.0f;
	animation.values = [NSArray arrayWithObjects:
						[NSNumber numberWithFloat:1.0f],
						[NSNumber numberWithFloat:1.0f],
						[NSNumber numberWithFloat:0.0f],
						[NSNumber numberWithFloat:0.0f], nil];
	animation.keyTimes = [NSArray arrayWithObjects:
						  [NSNumber numberWithFloat:0.1f],
						  [NSNumber numberWithFloat:0.3f],
						  [NSNumber numberWithFloat:0.7f],
						  [NSNumber numberWithFloat:animation.duration], nil];

	return animation;
}

- (void)showSearchRewindPanelReverse:(BOOL)isReversed
{
	if (rewindPanel)
		[self closeRewindPanel];

	rewindPanel = [self rewindPanelReverse:isReversed];

	[[[historyController view] window] addChildWindow:rewindPanel ordered:NSWindowAbove];

	CAKeyframeAnimation *alphaAnimation = [self rewindPanelFadeOutAnimation];
    [rewindPanel setAnimations:[NSDictionary dictionaryWithObject:alphaAnimation forKey:@"alphaValue"]];
	[[rewindPanel animator] setAlphaValue:0.0f];

	[self performSelector:@selector(closeRewindPanel) withObject:nil afterDelay:0.7f];
}

@end
