//
//  GLFileView.m
//  GitX
//
//  Created by German Laullon on 14/09/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GLFileView.h"


@implementation GLFileView

- (void) awakeFromNib
{
	startFile = @"fileview";
	//repository = historyController.repository;
	[super awakeFromNib];
	[historyController.treeController addObserver:self forKeyPath:@"selection" options:0 context:@"treeController"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//NSLog(@"keyPath=%@ change=%@ context=%@ object=%@ \n %@",keyPath,change,context,object,[historyController.treeController selectedObjects]);
	NSArray *files=[historyController.treeController selectedObjects];
	if ([files count]>0) {
		PBGitTree *file=[files objectAtIndex:0];
		NSString *fileTxt=[file textContents];
		id script = [view windowScriptObject];
		[script callWebScriptMethod:@"showFile" withArguments:[NSArray arrayWithObject:fileTxt]];
	}
}
@end
