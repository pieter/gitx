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
	NSArray* parameters;
	id grapher;
	id repository;
}

- initWithRepository:(id)repo andRevListParameters:(NSArray*) params;

@property(retain) NSArray* commits;
@property(retain) id grapher;

@end
