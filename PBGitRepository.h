//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBGitRepository : NSObject {
	NSString* path;
	NSArray* commits;
}

+ (void) setGitPath;

+ (PBGitRepository*) repositoryWithPath:(NSString*) path;
- (PBGitRepository*) initWithPath:(NSString*) path;

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;
- (void) initializeCommits;
- (void) addCommit: (id)obj;

@property (copy) NSString* path;
@property (retain) NSArray* commits;

@end
