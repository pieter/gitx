//
//  PBLine.h
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBGitGraphLine : NSObject
{
	int upper;
	int from;
	int to;
	int colorIndex;
}
@property(readonly) int upper, from, to, colorIndex;
- (id)initWithUpper: (int) u From: (int) f to: (int) t color: (int) c;
+ (PBGitGraphLine*) lowerLineFrom:(int) f to: (int) t color: (int) c;
+ (PBGitGraphLine*) upperLineFrom:(int) f to: (int) t color: (int) c;

@end