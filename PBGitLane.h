//
//  PBGitLane.h
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#include "git/oid.h"

@class PBGitCommit;

struct PBGitLane {
	static int s_colorIndex;

	PBGitCommit *commit;
	int index;

	PBGitLane(PBGitCommit *commit)
	{
		index = s_colorIndex++;
		this->commit = commit;
	}

	PBGitLane()
	{
		commit = nil;
		index = s_colorIndex++;
	}
	
	static void resetColors();
	bool operator ==(PBGitLane const &other)
	{
		return commit == other.commit && index == other.index;
	}
};