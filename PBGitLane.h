//
//  PBGitLane.h
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static int PBGITLANE_CURRENT_INDEX = 0;

@interface PBGitLane : NSObject {
	NSString* sha;
	int index;
}
- (id) initWithCommit: (NSString*) c;
- (BOOL) isCommit: (NSString*) c;

@property(assign)  NSString* sha;
@property(readonly) int index;

@end
