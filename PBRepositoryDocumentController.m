//
//  PBRepositoryDocumentController.mm
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBRepositoryDocumentController.h"
#import "PBGitRepository.h"
#import "PBGitRevList.h"

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

- (IBAction) showClone:(id)sender {
    [cloneWindow makeKeyAndOrderFront:sender];
}

- (IBAction)cloneURL:(id)sender
{
    NSString * remoteRepo = [cloneURLField stringValue];

    [cloneWindow close];

    NSOpenPanel * op = [NSOpenPanel openPanel];

    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setAllowsMultipleSelection:NO];
    [op setCanCreateDirectories:YES];
    [op setMessage:@"Clone the repository here:"];
    [op setTitle:@"Clone Repository Location"];
    if ([op runModal] == NSFileHandlingPanelOKButton) {
        NSString * path = [op filename];
        int terminationStatus;
        NSString * result = [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:[NSArray arrayWithObjects:@"clone", remoteRepo, path, nil] inDir:path inputString:nil retValue:&terminationStatus];

        if (terminationStatus == 0)
            [self openDocumentWithContentsOfURL:[op URL] display:YES error:NULL];
        else
            NSRunAlertPanel(@"Failed to clone Git repository", @"Git returned the following error when trying to clone the repository: %@", nil, nil, nil, result);
    }
} // cloneURL

- (IBAction) hideClone:(id)sender {
    [cloneWindow close];
}


- (void) noteNewRecentDocumentURL:(NSURL *)url {
    [super noteNewRecentDocumentURL:[PBGitRepository baseDirForURL:url]];
}

// overidden to provide sanity checks and recovery suggestions when a folder is opened that is not a git repo
// this can happen if for example an Open Recent entry now points to a hierarchy which had its .git folder removed
- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    if (![PBGitRepository gitDirForURL:absoluteURL]) {
        NSString * reason = @"It does not appear to be a git repository.";
        NSString * suggestion = @"Make sure there really is a \u201c.git\u201d folder somewhere in the path hierarchy you are trying to open";
        NSDictionary * errInfo = [NSDictionary dictionaryWithObjectsAndKeys:reason, NSLocalizedFailureReasonErrorKey, suggestion, NSLocalizedRecoverySuggestionErrorKey, nil];
        if (outError)
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:PBNotAGitRepositoryErrorCode userInfo:errInfo];
        return nil;
    }
    return [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
}

- (id) documentForLocation:(NSURL *)url {
    id document = [self documentForURL:url];

    if (!document) {

        if (!(document = [[PBGitRepository alloc] initWithURL:url]))
            return nil;

        [self addDocument:document];
    } else
        [document showWindows];

    return document;
}

- (IBAction) newDocument:(id)sender {
    NSOpenPanel * op = [NSOpenPanel openPanel];

    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setAllowsMultipleSelection:NO];
    [op setMessage:@"Initialize a repository here:"];
    [op setTitle:@"New Repository"];
    if ([op runModal] == NSFileHandlingPanelOKButton) {
        NSString * path = [op filename];
        int terminationStatus;
        NSString * result = [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:[NSArray arrayWithObjects:@"init", @"-q", nil] inDir:path inputString:nil retValue:&terminationStatus];

        if (terminationStatus == 0)
            [self openDocumentWithContentsOfURL:[op URL] display:YES error:NULL];
        else
            NSRunAlertPanel(@"Failed to create new Git repository", @"Git returned the following error when trying to create the repository: %@", nil, nil, nil, result);
    }
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
    if ([item action] == @selector(newDocument:)) {
        return ([PBGitBinary path] != nil);
    } else if ([item action] == @selector(saveAction:)) {
        // disable the Save menu item if there is no repository document open
        return ([[PBRepositoryDocumentController sharedDocumentController] currentDocument] != nil);
    }
    return [super validateMenuItem:item];
}

@end
