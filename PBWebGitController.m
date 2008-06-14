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
	NSLog(@"WebGitController activated");
	NSLog([[NSBundle mainBundle] resourcePath]);
	NSString* file = [[NSBundle mainBundle] pathForResource:@"commit" ofType:@"html"];
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:file]];
	NSLog(@"Request: %@", request);
	[[view mainFrame] loadRequest:request];	
}

- (void) webView:(id) view didFinishLoadForFrame:(id) frame
{
	NSLog(@"Loading done");
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

- (void) changeContentTo: (id) content
{
	NSLog(@"Starting Change");
	id script = [view windowScriptObject];
	[script setValue: content forKey:@"CommitObject"];
	NSLog(@"Done 1");
	[script callWebScriptMethod:@"doeHet" withArguments: nil];
	NSLog(@"Change done");
}
@end
