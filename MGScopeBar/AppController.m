//
//  AppController.m
//  MGScopeBar
//
//  Created by Matt Gemmell on 16/03/2008.
//

#import "AppController.h"
#import "MGScopeBar.h"


// Keys for our sample data.
#define GROUP_LABEL				@"Label"			// string
#define GROUP_SEPARATOR			@"HasSeparator"		// BOOL as NSNumber
#define GROUP_SELECTION_MODE	@"SelectionMode"	// MGScopeBarGroupSelectionMode (int) as NSNumber
#define GROUP_ITEMS				@"Items"			// array of dictionaries, each containing the following keys:
#define ITEM_IDENTIFIER			@"Identifier"		// string
#define ITEM_NAME				@"Name"				// string


@implementation AppController


#pragma mark Setup and teardown


- (void)awakeFromNib
{
	// In this method we basically just set up some sample data for the scope bar, 
	// so that we can respond to the MGScopeBarDelegate methods easily.
	
	self.groups = [NSMutableArray arrayWithCapacity:0];
	scopeBar.delegate = self;
	
	// Add first group of items.
	NSArray *items = [NSArray arrayWithObjects:
					  [NSDictionary dictionaryWithObjectsAndKeys:
					   @"HereItem", ITEM_IDENTIFIER, 
					   @"Here", ITEM_NAME, 
					   nil], 
					  [NSDictionary dictionaryWithObjectsAndKeys:
					   @"ThereItem", ITEM_IDENTIFIER, 
					   @"There", ITEM_NAME, 
					   nil], 
					  nil];
	
	[self.groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							@"Search:", GROUP_LABEL, 
							[NSNumber numberWithBool:NO], GROUP_SEPARATOR, 
							[NSNumber numberWithInt:MGRadioSelectionMode], GROUP_SELECTION_MODE, // single selection group.
							items, GROUP_ITEMS, 
							nil]];
	
	// Add second group of items.
	items = [NSArray arrayWithObjects:
			 [NSDictionary dictionaryWithObjectsAndKeys:
			  @"ContentsItem", ITEM_IDENTIFIER, 
			  @"Contents", ITEM_NAME, 
			  nil], 
			 [NSDictionary dictionaryWithObjectsAndKeys:
			  @"FileNamesItem", ITEM_IDENTIFIER, 
			  @"File Names", ITEM_NAME, 
			  nil], 
			 [NSDictionary dictionaryWithObjectsAndKeys:
			  @"MetadataItem", ITEM_IDENTIFIER, 
			  @"Metadata", ITEM_NAME, 
			  nil], 
			 nil];
	
	[self.groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							// deliberately not specifying a label
							[NSNumber numberWithBool:YES], GROUP_SEPARATOR, 
							[NSNumber numberWithInt:MGMultipleSelectionMode], GROUP_SELECTION_MODE, // multiple selection group.
							items, GROUP_ITEMS, 
							nil]];
	
	// Add third group of items.
	items = [NSArray arrayWithObjects:
			 [NSDictionary dictionaryWithObjectsAndKeys:
			  @"AllFilesItem", ITEM_IDENTIFIER, 
			  @"All Files", ITEM_NAME, 
			  nil], 
			 [NSDictionary dictionaryWithObjectsAndKeys:
			  @"ImagesOnlyItem", ITEM_IDENTIFIER, 
			  @"Images Only", ITEM_NAME, 
			  nil], 
			 nil];
	
	[self.groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							@"Kind:", GROUP_LABEL, 
							[NSNumber numberWithBool:YES], GROUP_SEPARATOR, 
							[NSNumber numberWithInt:MGRadioSelectionMode], GROUP_SELECTION_MODE, // single selection group.
							items, GROUP_ITEMS, 
							nil]];
	
	// Tell the scope bar to ask us for data (since we're the scope-bar's delegate).
	[scopeBar reloadData];
	
	// Since our first group is a radio-mode group, the scope bar will automatically select its first item.
	// The scope bar will take care of deselecting other items when you select a new item in a radio-mode group.
	
	// We'll also select the first item in our second group, which is a multiple-selection group.
	// You can (and must) use this method to programmatically select/deselect items in the bar.
	[scopeBar setSelected:YES forItem:@"ContentsItem" inGroup:1]; // remember that group-numbers are zero-based.
	
	// Clear out the label field below the scope bar.
	[labelField setStringValue:@""];
}


- (void)dealloc
{
	self.groups = nil;
	[super dealloc];
}


#pragma mark MGScopeBarDelegate methods


- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar
{
	return [self.groups count];
}


- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(int)groupNumber
{
	NSString *res=[[self.groups objectAtIndex:groupNumber] valueForKeyPath:[NSString stringWithFormat:@"%@.%@", GROUP_ITEMS, ITEM_IDENTIFIER]];
	NSLog(@"-itemIdentifiersForGroup- %@",res);
	return res;
}


- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber
{
	NSString *res= [[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_LABEL]; // might be nil, which is fine (nil means no label).
	NSLog(@"-labelForGroup- %@",res);
	return res;
}


- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(NSString *)identifier inGroup:(int)groupNumber
{
	NSArray *items = [[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_ITEMS];
	if (items) {
		// We'll iterate here, since this is just a demo. This avoids having to keep an NSDictionary of identifiers 
		// for each group as well as an array for ordering. In a more realistic scenario, you'd probably want to be 
		// able to look-up an item by its identifier in constant time.
		for (NSDictionary *item in items) {
			if ([[item objectForKey:ITEM_IDENTIFIER] isEqualToString:identifier]) {
				NSLog(@"-titleOfItem- %@=%@",identifier,[item objectForKey:ITEM_NAME]);
				return [item objectForKey:ITEM_NAME];
				break;
			}
		}
	}
	return nil;
}


- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(int)groupNumber
{
	return [[[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_SELECTION_MODE] intValue];
}


- (BOOL)scopeBar:(MGScopeBar *)theScopeBar showSeparatorBeforeGroup:(int)groupNumber
{
	// Optional method. If not implemented, all groups except the first will have a separator before them.
	return [[[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_SEPARATOR] boolValue];
}


- (NSImage *)scopeBar:(MGScopeBar *)scopeBar imageForItem:(NSString *)identifier inGroup:(int)groupNumber
{
	// Optional method. If not implemented (or if you return nil), items will not have an image.
	if (groupNumber == 0) {
		return [NSImage imageNamed:@"NSComputer"];
		
	} else if (groupNumber == 2) {
		if ([identifier isEqualToString:@"AllFilesItem"]) {
			return [NSImage imageNamed:@"NSGenericDocument"];
			
		} else if ([identifier isEqualToString:@"ImagesOnlyItem"]) {
			return [[NSWorkspace sharedWorkspace] iconForFileType:@"png"];
		}
	}
	
	return nil;
}


- (NSView *)accessoryViewForScopeBar:(MGScopeBar *)scopeBar
{
	// Optional method. If not implemented (or if you return nil), the scope-bar will not have an accessory view.
	return accessoryView;
}


- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected 
		 forItem:(NSString *)identifier inGroup:(int)groupNumber
{
	// Display some text showing what just happened.
	NSString *displayString = [NSString stringWithFormat:@"\"%@\" %@ in group %d.", 
							   identifier, 
							   (selected) ? @"selected" : @"deselected", 
							   groupNumber];
	[labelField setStringValue:displayString];
	//NSLog(@"%@", displayString);
}


#pragma mark Accessors and properties


@synthesize groups;


@end
