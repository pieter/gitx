//
//  PBGitLane.m
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitLane.h"
//class PBGitLane {
//	static int s_colorIndex;
//	
//	char d_sha[20];
//	int d_index;
//	
//public:
//	PBGitLane(NSString *sha);
//	
//	bool isCommit(NSString *sha) const;
//	int index(); const;
//	
//	static resetColors();
//};

int PBGitLane::s_colorIndex = 0;

static git_oid str_to_oid(NSString *str)
{
	git_oid oid;
	git_oid_mkstr(&oid, [str UTF8String]);
	return oid;
}

bool PBGitLane::isCommit(git_oid *sha) const
{
	return !git_oid_cmp(&d_sha, sha);
}

bool PBGitLane::isCommit(NSString *sha) const
{
	git_oid a = str_to_oid(sha);
	return isCommit(&a);
}

int PBGitLane::index() const
{
	return d_index;
}

void PBGitLane::setSha(git_oid sha)
{
	d_sha = sha;
}

void PBGitLane::setSha(NSString *sha)
{
	return setSha(str_to_oid(sha));
}


void PBGitLane::resetColors()
{
	s_colorIndex = 0;
}
