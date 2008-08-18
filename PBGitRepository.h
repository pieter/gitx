//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRevList.h"

extern NSString* PBGitRepositoryErrorDomain;

@interface PBGitRepository : NSDocument {
	PBGitRevList* revisionList;
	NSArray* branches;
	NSString* currentBranch;
}

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;
- (NSString*) outputForCommand:(NSString*) cmd;
- (NSString*) outputForArguments:(NSArray*) args;

- (void) readBranches;
- (void) readCurrentBranch;

- (NSString*) parseSymbolicReference:(NSString*) ref;
- (NSString*) parseReference:(NSString*) ref;

+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
@property (readonly) PBGitRevList* revisionList;
@property (assign) NSArray* branches;
@property (assign) NSString* currentBranch;

@end
