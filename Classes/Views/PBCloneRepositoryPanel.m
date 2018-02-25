//
//  PBCloneRepositoryPanel.m
//  GitX
//
//  Created by Nathan Kinsinger on 2/7/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import "PBCloneRepositoryPanel.h"
#import "PBRemoteProgressSheet.h"
#import "PBGitDefaults.h"



@implementation PBCloneRepositoryPanel


@synthesize repositoryURL;
@synthesize destinationPath;
@synthesize errorMessage;
@synthesize repositoryAccessoryView;

@synthesize isBare;



#pragma mark -
#pragma mark PBCloneRepositoryPanel

+ (id) panel
{
	return [[self alloc] initWithWindowNibName:@"PBCloneRepositoryPanel"];
}

+ (void)beginCloneRepository:(NSString *)repository toURL:(NSURL *)targetURL isBare:(BOOL)bare
{
	if (!repository || [repository isEqualToString:@""] || !targetURL || [[targetURL path] isEqualToString:@""])
		return;

	PBCloneRepositoryPanel *clonePanel = [PBCloneRepositoryPanel panel];
	[clonePanel showWindow:self];

	[clonePanel.repositoryURL setStringValue:repository];
	[clonePanel.destinationPath setStringValue:[targetURL path]];
	clonePanel.isBare = bare;

	[clonePanel clone:self];
}


- (void) awakeFromNib
{
	[self window];
	[self.errorMessage setStringValue:@""];
	path = [PBGitDefaults recentCloneDestination];
	if (path)
		[self.destinationPath setStringValue:path];
	
	browseRepositoryPanel = [NSOpenPanel openPanel];
	[browseRepositoryPanel setTitle:NSLocalizedString(@"Browse for git repository", @"Title for the file selector sheet for the source on the local file system to clone _from_")];
	[browseRepositoryPanel setMessage:NSLocalizedString(@"Select a folder with a git repository", @"Message on the file selector sheet to clone a repository from the local file system")];
	[browseRepositoryPanel setPrompt:NSLocalizedString(@"Select", @"Select (directory on local file system to clone a new repository from)")];
    [browseRepositoryPanel setCanChooseFiles:NO];
    [browseRepositoryPanel setCanChooseDirectories:YES];
    [browseRepositoryPanel setAllowsMultipleSelection:NO];
	[browseRepositoryPanel setCanCreateDirectories:NO];
	[browseRepositoryPanel setAccessoryView:repositoryAccessoryView];
	
	browseDestinationPanel = [NSOpenPanel openPanel];
	[browseDestinationPanel setTitle:NSLocalizedString(@"Browse clone destination", @"Title for the file selector sheet for the destination of a clone operation")];
	[browseDestinationPanel setMessage:NSLocalizedString(@"Select a folder to clone the git repository into", @"Message on the file selector sheet for the destination of a clone operation")];
	[browseDestinationPanel setPrompt:NSLocalizedString(@"Select",  @"Select (destination to clone a new repository to)")];
    [browseDestinationPanel setCanChooseFiles:NO];
    [browseDestinationPanel setCanChooseDirectories:YES];
    [browseDestinationPanel setAllowsMultipleSelection:NO];
	[browseDestinationPanel setCanCreateDirectories:YES];
}


- (void)showErrorSheet:(NSError *)error
{
	[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window]
											   modalDelegate:self
											  didEndSelector:@selector(errorSheetDidEnd:returnCode:contextInfo:)
												 contextInfo:NULL];
}



#pragma mark IBActions

- (IBAction) closeCloneRepositoryPanel:(id)sender
{
	[self close];
}


- (IBAction) clone:(id)sender
{
	[self.errorMessage setStringValue:@""];
	
	NSString *url = [self.repositoryURL stringValue];
	if ([url isEqualToString:@""]) {
		[self.errorMessage setStringValue:NSLocalizedString(@"Repository URL is required", @"Error message for missing source location when starting a clone operation")];
		return;
	}
	
	path = [self.destinationPath stringValue];
	if ([path isEqualToString:@""]) {
		[self.errorMessage setStringValue:NSLocalizedString(@"Destination path is required", @"Error message for missing target location when starting a clone operation")];
		return;
	}

	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"clone", @"--", url, path, nil];
	if (isBare)
		[arguments insertObject:@"--bare" atIndex:1];
	
	NSString *title = NSLocalizedString(@"Cloning Repository", @"Title of clone dialogue while clone is running");
	NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Cloning repository at: %@", @"Message in clone dialogue while clone is running."), url];


	NSURL *documentURL = [NSURL fileURLWithPath:path];
	PBRemoteProgressSheet *sheet = [PBRemoteProgressSheet progressSheetWithTitle:title description:description];
	[sheet beginProgressSheetForBlock:^NSError *{
		NSURL *repoURL = [NSURL URLWithString:url];
		NSError *error = nil;
		[GTRepository cloneFromURL:repoURL
				toWorkingDirectory:documentURL
						   options:@{GTRepositoryCloneOptionsBare: @(self.isBare)}
							 error:&error
			 transferProgressBlock:nil
			 checkoutProgressBlock:nil];
		return error;
	} completionHandler:^(NSError *error) {
		if (error) {
			[self close];
			[self showErrorSheet:error];
			return;
		}

		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:documentURL display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
			if (!document && error) {
				[self showErrorSheet:error];
				return;
			}

			[self close];

			NSString *containingPath = [path stringByDeletingLastPathComponent];
			[PBGitDefaults setRecentCloneDestination:containingPath];
			[self.destinationPath setStringValue:containingPath];
			[self.repositoryURL setStringValue:@""];
		}];
	}];
}


- (IBAction) browseRepository:(id)sender
{
    [browseRepositoryPanel beginSheetModalForWindow:[self window]
                                  completionHandler:^(NSInteger result) {
                                      if (result == NSOKButton) {
                                          NSURL *url = [[browseRepositoryPanel URLs] lastObject];
                                          [self.repositoryURL setStringValue:[url path]];
                                      }
                                  }];
}


- (IBAction) showHideHiddenFiles:(id)sender
{
	// This uses undocumented OpenPanel features to show hidden files (required for 10.5 support)
	NSNumber *showHidden = [NSNumber numberWithBool:[sender state] == NSOnState];
	[[browseRepositoryPanel valueForKey:@"_navView"] setValue:showHidden forKey:@"showsHiddenFiles"];
}


- (IBAction) browseDestination:(id)sender
{
    [browseDestinationPanel beginSheetModalForWindow:[self window]
                                   completionHandler:^(NSInteger result) {
                                       if (result == NSOKButton) {
                                           NSURL *url = [[browseDestinationPanel URLs] lastObject];
                                           [self.destinationPath setStringValue:[url path]];
                                       }
                                   }];
}



#pragma mark Callbacks


- (void) errorSheetDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)code contextInfo:(void *)info
{
	[self close];
}


@end
