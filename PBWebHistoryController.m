//
//  PBWebGitController.m
//  GitTest
//
//  Created by Pieter de Bie on 14-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBWebHistoryController.h"
@interface RefMenuItem : NSMenuItem
{
	NSString *ref;
}
@property (copy) NSString *ref;
@end
@implementation RefMenuItem
@synthesize ref;
@end


@implementation PBWebHistoryController

@synthesize diff;

- (void) awakeFromNib
{
	startFile = @"commit";
	[super awakeFromNib];
	[historyController addObserver:self forKeyPath:@"webCommit" options:0 context:@"ChangedCommit"];
}

- (void) didLoad
{
	[self changeContentTo: historyController.webCommit];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(NSString *)context
{
    if ([context isEqualToString: @"ChangedCommit"])
		[self changeContentTo: historyController.webCommit];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) changeContentTo: (PBGitCommit *) content
{
	if (content == nil || !finishedLoading)
		return;

	id script = [view windowScriptObject];
	[script setValue: content forKey:@"CommitObject"];

	// The sha is the same, but refs may have changed.. reload it lazy
	if ([currentSha isEqualToString: content.sha])
	{
		[script callWebScriptMethod:@"reload" withArguments: nil];
		return;
	}
	
	currentSha = content.sha;

	[script callWebScriptMethod:@"loadCommit" withArguments: nil];
}

- (void) selectCommit: (NSString*) sha
{
	[historyController selectCommit:sha];
}

- (void) sendKey: (NSString*) key
{
	id script = [view windowScriptObject];
	[script callWebScriptMethod:@"handleKeyFromCocoa" withArguments: [NSArray arrayWithObject:key]];
}

- (void) copySource
{
	NSString *source = [(DOMHTMLElement *)[[[view mainFrame] DOMDocument] documentElement] outerHTML];
	NSPasteboard *a =[NSPasteboard generalPasteboard];
	[a declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[a setString:source forType: NSStringPboardType];
}

- (void) removeRef:(RefMenuItem *)sender
{
	NSLog(@"Removing ref: %@", [sender ref]);
	if ([historyController.repository removeRef: [sender ref]])
		NSLog(@"Deletion succesful!");
	else
		NSLog(@"Deletion failed!");
}

- (NSArray *)	   webView:(WebView *)sender
contextMenuItemsForElement:(NSDictionary *)element
		  defaultMenuItems:(NSArray *)defaultMenuItems
{
	DOMNode *node = [element valueForKey:@"WebElementDOMNode"];

	// If clicked on the text, select the containing div
	if ([[node className] isEqualToString:@"DOMText"])
		node = [node parentNode];

	// Every ref has a class name of 'refs' and some other class. We check on that to see if we pressed on a ref.
	if (![[node className] hasPrefix:@"refs "])
		return defaultMenuItems;

	RefMenuItem *item = [[RefMenuItem alloc] initWithTitle:@"Remove"
													action:@selector(removeRef:)
											 keyEquivalent: @""];
	[item setTarget: self];
	[item setRef: [[[node childNodes] item:0] textContent]];
	return [NSArray arrayWithObject: item];
}


// Open external links in the default browser
-   (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
   		  request:(NSURLRequest *)request
     newFrameName:(NSString *)frameName
 decisionListener:(id < WebPolicyDecisionListener >)listener
{
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

@end
