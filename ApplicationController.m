//
//  GitTest_AppDelegate.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "ApplicationController.h"
#import "PBGitRevisionCell.h"
#import "PBGitWindowController.h"
#import "PBRepositoryDocumentController.h"
#import "PBCLIProxy.h"
#import "PBServicesController.h"
#import "PBGitXProtocol.h"
#import "PBPrefsWindowController.h"
#import "PBNSURLPathUserDefaultsTransfomer.h"
#import "PBGitDefaults.h"
#import "PBCloneRepositoryPanel.h"
#import "BMScript.h"
#import "PBGitSidebarController.h"

@implementation ApplicationController
@synthesize cliProxy;
@synthesize cliArgs;
@synthesize launchedFromGitx;
@synthesize deferredSelectSha;

static ApplicationController * sharedApplicationControllerInstance = nil; 

+ (void) initialize {
    if (sharedApplicationControllerInstance == nil)
        sharedApplicationControllerInstance = [[self alloc] init];
}

+ (ApplicationController *) sharedApplicationController {
    //Already set by +initialize.
    return sharedApplicationControllerInstance;
}

+ (id) allocWithZone:(NSZone *) zone {
    //Usually already set by +initialize.
    if (sharedApplicationControllerInstance) {
        //The caller expects to receive a new object, so implicitly retain it
        //to balance out the eventual release message.
        return [sharedApplicationControllerInstance retain];
    } else {
        //When not already set, +initialize is our caller.
        //It's creating the shared instance, let this go through.
        return [super allocWithZone: zone];
    }
}

- (id) copyWithZone:(NSZone *) zone {
    return self;
}

- (NSUInteger) retainCount {
    return UINT_MAX; // denotes an object that cannot be released
}

- (ApplicationController *) init
{
    //If sharedApplicationControllerInstance is nil, +initialize is our caller, so initialize the instance.
    //If it is not nil, simply return the instance without re-initializing it.
    if (sharedApplicationControllerInstance == nil) {
#ifdef DEBUG_BUILD
        [NSApp activateIgnoringOtherApps:YES];
#endif
        if(self = [super init]) {
            if(![[NSBundle bundleWithPath:@"/System/Library/Frameworks/Quartz.framework/Frameworks/QuickLookUI.framework"] load])
                if(![[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load])
                    NSLog(@"Could not load QuickLook");

            self.cliProxy = [PBCLIProxy new];
            launchedFromGitx = NO;
            cliArgs = nil;
            deferredSelectSha = nil;
        }
        /* Value Transformers */
        NSValueTransformer *transformer = [[PBNSURLPathUserDefaultsTransfomer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"PBNSURLPathUserDefaultsTransfomer"];
        // Make sure the PBGitDefaults is initialized, by calling a random method
        [PBGitDefaults class];
        return self;
    }
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
	int serviceVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"Services Version"];
	if (serviceVersion < 2)
	{
		NSLog(@"Updating services menu…");
		NSUpdateDynamicServices();
		[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"Services Version"];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	// Make sure Git's SSH password requests get forwarded to our little UI tool:
	setenv( "SSH_ASKPASS", [[[NSBundle mainBundle] pathForResource: @"gitx_askpasswd" ofType: @""] UTF8String], 1 );
	setenv( "DISPLAY", "localhost:0", 1 );

    char * launchedfromgitx = getenv("GITX_LAUNCHED_FROM_CLI");
    char * cliargs = getenv("GITX_CLI_ARGUMENTS");

    self.launchedFromGitx = (launchedfromgitx ? YES : NO);

    if (cliargs) {
        self.cliArgs = [NSString stringWithUTF8String:(cliargs)];
    }

    // NSLog(@"[%@ %s] launchedFromGitx = %@", [self class], _cmd, (launchedFromGitx ? @"YES" : @"NO"));
    // NSLog(@"[%@ %s] cliArgs = %@", [self class], _cmd, cliArgs);

	[self registerServices];

    if ([cliArgs isEqualToString:@"--all"]) {
        [PBGitDefaults setBranchFilter:kGitXAllBranchesFilter];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if ([cliArgs isEqualToString:@"--local"]) {
        [PBGitDefaults setBranchFilter:kGitXLocalRemoteBranchesFilter];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    BOOL hasOpenedDocuments = NO;
    launchedDocuments = [[[PBRepositoryDocumentController sharedDocumentController] documents] copy];

	// Only try to open a default document if there are no documents open already.
	// For example, the application might have been launched by double-clicking a .git repository,
	// or by dragging a folder to the app icon
	if ([launchedDocuments count])
		hasOpenedDocuments = YES;

    // open any documents that were open the last time the app quit
    if ([PBGitDefaults openPreviousDocumentsOnLaunch]) {
        for (NSString *path in [PBGitDefaults previousDocumentPaths]) {
            NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
            NSError *error = nil;
            if (url && [[PBRepositoryDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error])
                hasOpenedDocuments = YES;
        }
    }

	// Try to find the current directory, to open that as a repository...
	if ([PBGitDefaults openCurDirOnLaunch] && !hasOpenedDocuments) {
		NSString *curPath = [[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"];
        NSURL *url = nil;
		if (curPath)
			url = [NSURL fileURLWithPath:curPath];
        // Try to open the found URL
        NSError *error = nil;
        if (url && [[PBRepositoryDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error])
            hasOpenedDocuments = YES;
	}

    launchedDocuments = [[[PBRepositoryDocumentController sharedDocumentController] documents] copy];

    // ...to bring the launched documents to the front
    for (PBGitRepository *document in launchedDocuments) {

        PBGitWindowController * wc = [(PBGitRepository *)document windowController];
        PBGitHistoryController * historyViewController = wc.historyController;
        NSArrayController * ccontroller = historyViewController.commitController;

        // determine what to show right after start - stage or standard history view?
        if ([cliArgs isEqualToString:@"--commit"] || [cliArgs isEqualToString:@"-c"]) {
            [wc showCommitView:self];
            launchedFromGitx = NO;
        } else {
            [wc showHistoryView:self];
        }

        if ([cliArgs hasPrefix:@"--author"]) {
            NSArray * components = [cliArgs componentsSeparatedByString:@"="];
            NSString * author = [components objectAtIndex:1];
            [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"author contains[c] %@", author]];
            [historyViewController.commitList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        } else if ([cliArgs hasPrefix:@"--subject"]) {
            NSArray * components = [cliArgs componentsSeparatedByString:@"="];
            NSString * subject = [components objectAtIndex:1];
            [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"subject contains[c] %@", subject]];
        } else if ([cliArgs hasPrefix:@"--sha"]) {
            NSArray * components = [cliArgs componentsSeparatedByString:@"="];
            NSString * sha = [components objectAtIndex:1];
            [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"realSha contains[c] %@", sha]];
        } else if ([cliArgs hasPrefix:@"-S"]) {
            NSString * subject = [cliArgs substringFromIndex:2];
            [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"subject contains[c] %@", subject]];
        }

        [document showWindows];
    }

    if (launchedFromGitx) {
        [self performSelector:@selector(finalizeCLILaunch:) withObject:self afterDelay:0.5];
    }

	if (![[NSApplication sharedApplication] isActive])
		return;

	// The current directory was not enabled or could not be opened (most likely it’s not a git repository).
	// show an open panel for the user to select a repository to view
	if ([PBGitDefaults showOpenPanelOnLaunch] && !hasOpenedDocuments)
		[[PBRepositoryDocumentController sharedDocumentController] openDocument:self];
}

- (void) finalizeCLILaunch:(id)object {
    for (PBGitRepository * document in launchedDocuments) {
        BOOL success = [[[(PBGitRepository *)document windowController] historyController] selectCommit:self.deferredSelectSha];
        // NSLog(@"[%@ %s] trying to select commit with sha %@ (success = %@)", [self class], _cmd, self.deferredSelectSha, BMStringFromBOOL(success));
        if (success) {
            PBGitWindowController * wc = [(PBGitRepository *)document windowController];
            PBGitHistoryController * histController = wc.historyController;
            PBCommitList * clist = histController.commitList;
            // updating the selection with the selection seems redundant but it also updates the row select indicator
            [clist selectRowIndexes:[clist selectedRowIndexes] byExtendingSelection:NO];
            [histController scrollSelectionToTopOfViewFrom:0];
            [histController updateKeys];
        }
    }
    // Reset CLI indication status so KVO all over the controllers can go the intended ways again...
    self.deferredSelectSha = nil;
    self.launchedFromGitx = NO;
}


- (void) windowWillClose:(id)sender
{
    if ([[[sender object] windowController] isKindOfClass:[PBPrefsWindowController class]] ) {
        for (PBGitRepository * doc in [[PBRepositoryDocumentController sharedDocumentController] documents]) {
            [[[doc windowForSheet] contentView] setNeedsDisplay:YES];
        }
    } else {
        [firstResponder terminate: sender];
    }	
}

- (IBAction)openPreferencesWindow:(id)sender
{
    DBPrefsWindowController * prefsWindowController = [PBPrefsWindowController sharedPrefsWindowController];
    [[prefsWindowController window] setDelegate:self];
	[prefsWindowController showWindow:nil];
}

- (IBAction)showAboutPanel:(id)sender
{
	NSString *gitversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleGitVersion"];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	if (gitversion)
		[dict addEntriesFromDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:gitversion, @"Version", nil]];

	#ifdef DEBUG_BUILD
		[dict addEntriesFromDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:@"GitX (DEBUG)", @"ApplicationName", nil]];
	#endif

	[NSApp orderFrontStandardAboutPanelWithOptions:dict];
}

- (IBAction) showCloneRepository:(id)sender
{
	if (!cloneRepositoryPanel)
		cloneRepositoryPanel = [PBCloneRepositoryPanel panel];

	[cloneRepositoryPanel showWindow:self];
}

- (IBAction)installCliTool:(id)sender;
{
	BOOL success               = NO;
	NSString* installationPath = @"/usr/local/bin/";
	NSString* installationName = @"gitx";
	NSString* toolPath         = [[NSBundle mainBundle] pathForResource:@"gitx" ofType:@""];
	if (toolPath) {
		AuthorizationRef auth;
		if (AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth) == errAuthorizationSuccess) {
			char const* mkdir_arg[] = { "-p", [installationPath UTF8String], NULL};
			char const* mkdir	= "/bin/mkdir";
			AuthorizationExecuteWithPrivileges(auth, mkdir, kAuthorizationFlagDefaults, (char**)mkdir_arg, NULL);
			char const* arguments[] = { "-f", "-s", [toolPath UTF8String], [[installationPath stringByAppendingString: installationName] UTF8String],  NULL };
			char const* helperTool  = "/bin/ln";
			if (AuthorizationExecuteWithPrivileges(auth, helperTool, kAuthorizationFlagDefaults, (char**)arguments, NULL) == errAuthorizationSuccess) {
				int status;
				int pid = wait(&status);
				if (pid != -1 && WIFEXITED(status) && WEXITSTATUS(status) == 0)
					success = true;
				else
					errno = WEXITSTATUS(status);
			}

			AuthorizationFree(auth, kAuthorizationFlagDefaults);
		}
	}

	if (success) {
		[[NSAlert alertWithMessageText:@"Installation Complete"
	                    defaultButton:nil
	                  alternateButton:nil
	                      otherButton:nil
	        informativeTextWithFormat:@"The gitx tool has been installed to %@", installationPath] runModal];
	} else {
		[[NSAlert alertWithMessageText:@"Installation Failed"
	                    defaultButton:nil
	                  alternateButton:nil
	                      otherButton:nil
	        informativeTextWithFormat:@"Installation to %@ failed", installationPath] runModal];
	}
}

/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "GitTest" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (IBAction) showHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://gitx.frim.nl/user_manual.html"]];
}

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"GitTest"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"GitTest.xml"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[PBGitDefaults removePreviousDocumentPaths];

	if ([PBGitDefaults openPreviousDocumentsOnLaunch]) {
		NSArray *documents = [[PBRepositoryDocumentController sharedDocumentController] documents];
		if ([documents count] > 0) {
			NSMutableArray *paths = [NSMutableArray array];
			for (PBGitRepository *repository in documents)
				[paths addObject:[repository workingDirectory]];

			[PBGitDefaults setPreviousDocumentPaths:paths];
		}
	}
}

/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {

    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}
@end
