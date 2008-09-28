//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRevList.h"
#import "PBGitRevSpecifier.h"

extern NSString* PBGitRepositoryErrorDomain;

@interface PBGitRepository : NSDocument {
	PBGitRevList* revisionList;

	BOOL hasChanged;
	NSMutableArray* branches;
	NSIndexSet* currentBranch;
	NSMutableDictionary* refs;
}

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;
- (NSFileHandle *) handleInWorkDirForArguments:(NSArray *)args;
- (NSString*) outputForCommand:(NSString*) cmd;
- (NSString *)outputForCommand:(NSString *)str retValue:(int *)ret;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input retValue:(int *)ret;
- (NSString*) outputForArguments:(NSArray*) args;
- (NSString*) outputForArguments:(NSArray*) args retValue:(int *)ret;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments;

- (NSString *)workingDirectory;

- (BOOL) reloadRefs;
- (void) addRef:(PBGitRef *)ref fromParameters:(NSArray *)params;
- (BOOL) removeRef:(NSString *)ref;
- (void) lazyReload;

- (void) readCurrentBranch;
- (PBGitRevSpecifier*) addBranch: (PBGitRevSpecifier*) rev;
- (void) selectBranch: (PBGitRevSpecifier*) rev;

- (NSString*) parseSymbolicReference:(NSString*) ref;
- (NSString*) parseReference:(NSString*) ref;

+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
+ (NSURL*)baseDirForURL:(NSURL*)repositoryURL;

- (id) initWithURL: (NSURL*) path;
- (void) setup;

@property (assign) BOOL hasChanged;
@property (readonly) NSWindowController *windowController;
@property (retain) PBGitRevList* revisionList;
@property (assign) NSMutableArray* branches;
@property (assign) NSIndexSet* currentBranch;
@property (assign) NSMutableDictionary* refs;
@end
