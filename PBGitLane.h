//
//  PBGitLane.h
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>

class PBGitLane {
	static int s_colorIndex;

	NSString *d_sha;
	int d_index;

public:

	PBGitLane(NSString *sha)
	{
		d_index = s_colorIndex++;
		d_sha = [sha copy];
	}
	
	PBGitLane()
	{
		d_index = s_colorIndex++;
		d_sha = NULL;
	}
	
	bool isCommit(NSString *sha) const;
	void setSha(NSString *sha);
	NSString *sha() const
	{
		return [d_sha copy];
	}
	
	int index() const;

	static void resetColors();
};
