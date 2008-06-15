//
//  PBGitTree.h
//  GitTest
//
//  Created by Pieter de Bie on 15-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@interface PBGitTree : NSObject {
	NSString* sha;
	NSString* path;
	PBGitRepository* repository;
	PBGitTree* parent;
	NSArray* children;
	BOOL leaf;
}

+ (PBGitTree*) rootForCommit: (id) commit;
+ (PBGitTree*) treeForTree: (PBGitTree*) tree andPath: (NSString*) path;

@property(copy) NSString* sha;
@property(copy) NSString* path;
@property(assign) BOOL leaf;
@property(retain) PBGitRepository* repository;
@property(assign) PBGitTree* parent;
@property(readonly) NSString* fullPath;
@end
