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

+ (PBGitRepository*) repositoryWithPath:(NSString*) path;
- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (void) addCommit: (id)obj;

@property (copy) NSString* path;
@property (retain) NSArray* commits;

@end
