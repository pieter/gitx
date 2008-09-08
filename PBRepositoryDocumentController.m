//
//  PBRepositoryDocumentController.mm
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBRepositoryDocumentController.h"
#import "PBGitRepository.h"

@implementation PBRepositoryDocumentController
// This method is overridden to configure the open panel to only allow
// selection of directories
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:YES];
	return [openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject: @"git"]];
}

// Convert paths to the .git dir before searching for an already open document
- (id)documentForURL:(NSURL *)URL
{
	return [super documentForURL:[PBGitRepository gitDirForURL:URL]];
}

- (void)noteNewRecentDocumentURL:(NSURL*)url
{
	[super noteNewRecentDocumentURL:[PBGitRepository baseDirForURL:url]];
}

- (id) openRepositoryAtLocation:(NSURL*) url RevParseArgs:(NSArray*)args
{
	id document = [self documentForURL:url];
	if (!document) {
		document = [[PBGitRepository alloc] initWithURL:url	andArguments:args];
		[self addDocument:document];
		[document makeWindowControllers];
	} else {
		// TODO: Add another revwalk specifier and show that.
	}
	[document showWindows];
	return document;
}
@end
