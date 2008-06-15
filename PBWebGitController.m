//
//  PBWebGitController.m
//  GitTest
//
//  Created by Pieter de Bie on 14-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBWebGitController.h"


@implementation PBWebGitController

@synthesize diff;

- (void) awakeFromNib
{
	[commitsController addObserver:self forKeyPath:@"selection" options:0 context:@"ChangedCommit"];
	
	NSLog([[NSBundle mainBundle] resourcePath]);
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
	if ([[commitsController selectedObjects] count] == 0)
		return;

	[self changeContentTo: [[commitsController selectedObjects] objectAtIndex:0]];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == @"ChangedCommit") {
		if ([[commitsController selectedObjects] count] != 0)
			[self changeContentTo: [[commitsController selectedObjects] objectAtIndex:0]];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) changeContentTo: (PBGitCommit *) content
{
	if ([currentSha isEqualToString: content.sha] || [currentSha isEqualToString:@"Not Loaded"])
		return;
	
	currentSha = content.sha;
	id script = [view windowScriptObject];
	[script setValue: content forKey:@"CommitObject"];
	[script callWebScriptMethod:@"doeHet" withArguments: nil];
}

- (void) selectCommit: (NSString*) sha
{
	NSPredicate* selection = [NSPredicate predicateWithFormat:@"sha == %@", sha];
	NSArray* selectedCommits = [[commitsController arrangedObjects] filteredArrayUsingPredicate:selection];
	[commitsController setSelectedObjects:selectedCommits];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}

@end
