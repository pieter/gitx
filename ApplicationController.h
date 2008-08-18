//
//  GitTest_AppDelegate.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@class PBCLIProxy;

@interface ApplicationController : NSObject 
{
	IBOutlet NSWindow *window;
	IBOutlet id firstResponder;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;

	PBCLIProxy *cliProxy;
}
@property (retain) PBCLIProxy* cliProxy;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)installCliTool:(id)sender;

- (IBAction)saveAction:sender;
- (IBAction)switchBranch:sender;
@end
