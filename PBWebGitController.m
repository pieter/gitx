//
//  PBWebGitController.m
//  GitTest
//
//  Created by Pieter de Bie on 14-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBWebGitController.h"
@interface RefMenuItem : NSMenuItem
{
	NSString *ref;
}
@property (copy) NSString *ref;
@end
@implementation RefMenuItem
@synthesize ref;
@end


@implementation PBWebGitController

@synthesize diff;

- (void) awakeFromNib
{
	[historyController addObserver:self forKeyPath:@"webCommit" options:0 context:@"ChangedCommit"];
	NSString* file = [[NSBundle mainBundle] pathForResource:@"commit" ofType:@"html"];
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:file]];
	currentSha = @"Not Loaded";

	[[view mainFrame] loadRequest:request];	
}

- (void) webView:(id) v didFinishLoadForFrame:(id) frame
{
	id script = [view windowScriptObject];
	[script setValue: self forKey:@"Controller"];
	currentSha = @"";

	[self changeContentTo: historyController.webCommit];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == @"ChangedCommit") {
		[self changeContentTo: historyController.webCommit];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) changeContentTo: (PBGitCommit *) content
{
	if (content == nil || [currentSha isEqualToString:@"Not Loaded"])
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

- (void) log: (NSString*) logMessage
{
	NSLog(logMessage);
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
	NSString *source = [[[[view mainFrame] DOMDocument] documentElement] outerHTML];
	NSPasteboard *a =[NSPasteboard generalPasteboard];
	[a declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[a setString:source forType: NSStringPboardType];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}

- (void) removeRef:(RefMenuItem *)sender
{
	NSLog(@"Removing ref: %@", [sender ref]);
	if ([historyController.repository removeRef: [sender ref]])
		NSLog(@"Deletion succesful!");
	else
		NSLog(@"Deletion failed!");
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	DOMNode *node = [element valueForKey:@"WebElementDOMNode"];

	if ([[node className] isEqualToString:@"DOMText"])
		node = [node parentNode];

	// Every ref has a class name of 'refs' and some other class. We check on that to see if we pressed on a ref.
	if ([[node className] hasPrefix:@"refs "]) {
		RefMenuItem *item = [[RefMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeRef:) keyEquivalent: @""];
		[item setTarget: self];
		[item setRef: [[[node childNodes] item:0] textContent]];
		return [NSArray arrayWithObject: item];
	}

	return defaultMenuItems;
}
@end
