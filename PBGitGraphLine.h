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
	char upper;
	char from;
	char to;
	char colorIndex;
}
@property(readonly) char upper, from, to, colorIndex;
- (id)initWithUpper: (char) u From: (char) f to: (char) t color: (char) c;
+ (PBGitGraphLine*) lowerLineFrom:(char) f to: (char) t color: (char) c;
+ (PBGitGraphLine*) upperLineFrom:(char) f to: (char) t color: (char) c;

@end