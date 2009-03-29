//
//  PBGitRevPool.h
//  GitX
//
//  Created by Pieter de Bie on 29-03-09.
//  Copyright 2009 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "git/oid.h"

@class PBGitRepository;
@class PBGitCommit;
@class PBGitRevSpecifier;

@interface PBGitRevPool : NSObject {
	PBGitRepository *repository;
	__weak id delegate;
	NSMapTable *revisions;
}

@property (assign) __weak id delegate;

- initWithRepository:(PBGitRepository *)repo;
- (void)loadRevisions:(PBGitRevSpecifier *)revisions;

- (PBGitCommit *)commitWithSha:(NSString *)sha;
- (PBGitCommit *)commitWithOid:(git_oid *)oid;
@end

@interface NSObject(PBRevPoolDelegate)

- (void)revPool:(PBGitRevPool *)pool encounteredCommit:(PBGitCommit *)commit;

@end
