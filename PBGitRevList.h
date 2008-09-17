//
//  PBGitRevList.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBGitRevList : NSObject {
	NSArray* commits;
	id repository;
	NSString* lastSha;
}

- initWithRepository:(id)repo;
- (void) readCommits;

@property(retain) NSArray* commits;

@end
