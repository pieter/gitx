//
//  PBRepositoryDocumentController.mm
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBRepositoryDocumentController.h"
#import "PBGitRepositoryDocument.h"
#import "PBGitRevList.h"
#import "PBGitBinary.h"

#import <ObjectiveGit/GTRepository.h>

@implementation PBRepositoryDocumentController
// This method is overridden to configure the open panel to only allow
// selection of directories
- (void)beginOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray<NSString *> *)inTypes completionHandler:(void (^)(NSInteger))completionHandler {
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"git"]];

	NSModalResponse response = [openPanel runModal];

	completionHandler(response);
}

- (id)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
	NSOpenPanel *op = [NSOpenPanel openPanel];

	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
	[op setAllowsMultipleSelection:NO];
	[op setMessage:NSLocalizedString(@"Initialize a repository here:", @"Message at the top of the repository initialisation file selection dialogue box")];
	[op setTitle:NSLocalizedString(@"New Repository", @"Title of the repository initialisation file selection dialogue box")];
	if ([op runModal] != NSFileHandlingPanelOKButton) {
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
		}
        return nil;
    }

	GTRepository *repo = [GTRepository initializeEmptyRepositoryAtFileURL:[op URL] options:nil error:outError];
    if (!repo)
        return nil; // Repo creation failed

    return [[PBGitRepositoryDocument alloc] initWithContentsOfURL:[op URL] ofType:PBGitRepositoryDocumentType error:outError];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([item action] == @selector(newDocument:))
		return ([PBGitBinary path] != nil);
	return YES;
}

@end
