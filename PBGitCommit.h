//
//  PBGitCommit.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"
#import "PBGitTree.h"
#import "PBGitRefish.h"
#include "git/oid.h"


extern NSString * const kGitXCommitType;


@interface PBGitCommit : NSObject <PBGitRefish> {
	git_oid sha;
	git_oid *parentShas;
	int nParents;

	NSString* subject;
	NSString* author;
	NSString* details;
	NSString *_patch;
	NSArray* parents;
	NSString *realSHA;

	int timestamp;
	char sign;
	id lineInfo;
	PBGitRepository* repository;
}

+ commitWithRepository:(PBGitRepository*)repo andSha:(git_oid)newSha;
- initWithRepository:(PBGitRepository *)repo andSha:(git_oid)sha;

- (void)addRef:(PBGitRef *)ref;
- (void)removeRef:(id)ref;
- (BOOL) hasRef:(PBGitRef *)ref;

- (NSString *)realSha;
- (BOOL) isOnSameBranchAs:(PBGitCommit *)other;
- (BOOL) isOnHeadBranch;

// <PBGitRefish>
- (NSString *) refishName;
- (NSString *) shortName;
- (NSString *) refishType;

@property (readonly) git_oid *sha;
@property (copy) NSString* subject;
@property (copy) NSString* author;
@property (readonly) NSArray* parents; // TODO: remove this and its uses

@property (assign) git_oid *parentShas;
@property (assign) int nParents, timestamp;

@property (retain) NSMutableArray* refs;
@property (readonly) NSDate *date;
@property (readonly) NSString* dateString;
@property (readonly) NSString* patch;
@property (assign) char sign;

@property (readonly) NSString* details;
@property (readonly) PBGitTree* tree;
@property (readonly) NSArray* treeContents;
@property (retain) PBGitRepository* repository;
@property (retain) id lineInfo;
@end
