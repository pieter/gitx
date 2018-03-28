//
//  GitTest_AppDelegate.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "ApplicationController.h"
#import "PBRepositoryDocumentController.h"
#import "PBGitRevisionCell.h"
#import "PBGitWindowController.h"
#import "PBServicesController.h"
#import "PBGitXProtocol.h"
#import "PBNSURLPathUserDefaultsTransfomer.h"
#import "PBGitDefaults.h"
#import "PBCloneRepositoryPanel.h"
#import "OpenRecentController.h"
#import "PBGitBinary.h"
#import "PBGitRepositoryDocument.h"
#import "PBRepositoryFinder.h"

static OpenRecentController* recentsDialog = nil;

@interface ApplicationController ()
@end

@implementation ApplicationController

- (ApplicationController*)init
{
#ifdef DEBUG_BUILD
	[NSApp activateIgnoringOtherApps:YES];
#endif

	if(!(self = [super init]))
		return nil;

	if(![[NSBundle bundleWithPath:@"/System/Library/Frameworks/Quartz.framework/Frameworks/QuickLookUI.framework"] load])
		if(![[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load])
			NSLog(@"Could not load QuickLook");

	/* Value Transformers */
	NSValueTransformer *transformer = [[PBNSURLPathUserDefaultsTransfomer alloc] init];
	[NSValueTransformer setValueTransformer:transformer forName:@"PBNSURLPathUserDefaultsTransfomer"];
	
	// Make sure the PBGitDefaults is initialized, by calling a random method
	[PBGitDefaults class];
	
	started = NO;
	return self;
}

- (void)registerServices
{
	// Register URL
	[NSURLProtocol registerClass:[PBGitXProtocol class]];

	// Register the service class
	PBServicesController *services = [[PBServicesController alloc] init];
	[NSApp setServicesProvider:services];

	// Force update the services menu if we have a new services version
	NSInteger serviceVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"Services Version"];
	if (serviceVersion < 2)
	{
		NSLog(@"Updating services menu…");
		NSUpdateDynamicServices();
		[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"Services Version"];
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray <NSString *> *)filenames {
	PBRepositoryDocumentController * controller = [PBRepositoryDocumentController sharedDocumentController];

	NSScriptCommand *command = [NSScriptCommand currentCommand];
	for (NSString * filename in filenames) {
		NSURL * repository = [NSURL fileURLWithPath:filename];
		[controller openDocumentWithContentsOfURL:repository display:YES completionHandler:^void (NSDocument *_document, BOOL documentWasAlreadyOpen, NSError *error) {
			if (!_document) {
				NSLog(@"Error opening repository \"%@\": %@", repository.path, error);
				[controller presentError:error];
				[sender replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
			}
			else {
				[sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
			}

			if (command) {
				PBGitRepositoryDocument *document = (id)_document;
				NSURL *repoURL = [command directParameter];

				// on app launch there may be many repositories opening, so double check that this is the right repo
				if (repoURL) {
					repoURL = [PBRepositoryFinder gitDirForURL:repoURL];
					if ([repoURL isEqual:[document.fileURL URLByAppendingPathComponent:@".git"]]) {
						NSArray *arguments = command.arguments[@"openOptions"];
						[document handleGitXScriptingArguments:arguments];
					}
				}
			}
		}];
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if(!started || [[[NSDocumentController sharedDocumentController] documents] count])
		return NO;
	return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
	recentsDialog = [[OpenRecentController alloc] init];
	if ([recentsDialog.possibleResults count] > 0)
	{
		[recentsDialog show];
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	// Make sure Git's SSH password requests get forwarded to our little UI tool:
	setenv( "SSH_ASKPASS", [[[NSBundle mainBundle] pathForResource: @"gitx_askpasswd" ofType: @""] UTF8String], 1 );
	setenv( "DISPLAY", "localhost:0", 1 );

	[self registerServices];
	started = YES;
}

- (void) windowWillClose: sender
{
	[firstResponder terminate: sender];
}

//Override the default behavior
- (IBAction)openDocument:(id)sender {
	NSOpenPanel* panel = [[NSOpenPanel alloc] init];
	
	[panel setCanChooseFiles:false];
	[panel setCanChooseDirectories:true];
	
	[panel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSModalResponseOK) {
			PBRepositoryDocumentController* controller = [PBRepositoryDocumentController sharedDocumentController];
			[controller openDocumentWithContentsOfURL:panel.URL display:true completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
				if (!document) {
					NSLog(@"Error opening repository \"%@\": %@", panel.URL.path, error);
					[controller presentError:error];
				}
			}];
		}
	}];
}

- (IBAction)showAboutPanel:(id)sender
{
	NSString *gitversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleGitVersion"];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	if (gitversion)
		[dict addEntriesFromDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:gitversion, @"Version", nil]];

	#ifdef DEBUG_BUILD
		[dict addEntriesFromDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:@"GitX-dev (DEBUG)", @"ApplicationName", nil]];
	#endif

	[dict addEntriesFromDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:@"GitX-dev (rowanj fork)", @"ApplicationName", nil]];

	[NSApp orderFrontStandardAboutPanelWithOptions:dict];
}

- (IBAction) showCloneRepository:(id)sender
{
	if (!cloneRepositoryPanel)
		cloneRepositoryPanel = [PBCloneRepositoryPanel panel];

	[cloneRepositoryPanel showWindow:self];
}


#pragma mark Help menu

- (IBAction)showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://gitx.github.io"]];
}

- (IBAction)reportAProblem:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/gitx/gitx/issues"]];
}

- (IBAction)showChangeLog:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/gitx/gitx/releases"]];
}



@end
