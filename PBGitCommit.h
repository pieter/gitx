//
//  PBGitCommit.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@interface PBGitCommit : NSObject {
	NSString* sha;
	NSString* subject;
	NSString* author;
	PBGitRepository* repository;
}

- initWithRepository:(PBGitRepository*) repo andSha:(NSString*) sha;

@property (copy) NSString* sha;
@property (copy) NSString* subject;
@property (copy) NSString* author;

@property (readonly) NSString* details;

@property (retain) PBGitRepository* repository;
@end
