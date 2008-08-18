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
}

+ (PBGitRepository*) repositoryWithPath:(NSString*) path;
- (PBGitRepository*) initWithPath:(NSString*) path;

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;

@property (readonly) PBGitRevList* revisionList;

@end
