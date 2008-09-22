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
	NSMutableArray* branches;
	NSIndexSet* currentBranch;
	NSMutableDictionary* refs;
}

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;
- (NSString*) outputForCommand:(NSString*) cmd;
- (NSString*) outputForCommand:(NSString *)str retValue:(int *)ret;
- (NSString*) outputForArguments:(NSArray*) args;
- (NSString*) outputForArguments:(NSArray*) args retValue:(int *)ret;

- (BOOL) reloadRefs;
- (void) addRef:(PBGitRef *)ref fromParameters:(NSArray *)params;
- (void) readCurrentBranch;
- (PBGitRevSpecifier*) addBranch: (PBGitRevSpecifier*) rev;
- (void) selectBranch: (PBGitRevSpecifier*) rev;

- (NSString*) parseSymbolicReference:(NSString*) ref;
- (NSString*) parseReference:(NSString*) ref;

+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
+ (NSURL*)baseDirForURL:(NSURL*)repositoryURL;

- (id) initWithURL: (NSURL*) path andRevSpecifier:(PBGitRevSpecifier*) rev;
- (void) setup;

@property (retain) PBGitRevList* revisionList;
@property (assign) NSMutableArray* branches;
@property (assign) NSIndexSet* currentBranch;
@property (assign) NSMutableDictionary* refs;
@end
