//
//  speedtest.m
//  GitX
//
//  Created by Pieter de Bie on 20-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "speedtest.h"
#import "PBGitRepository.h"
#import "PBGitRevList.h"

int main()
{
	PBGitRepository *repo = [[PBGitRepository alloc] initWithURL:[NSURL URLWithString:@"file:///Users/pieter/projects/git"]];
	PBGitRevList *revList =  [[PBGitRevList alloc] initWithRepository:repo];
	PBGitRevSpecifier *revSpecifier = [[PBGitRevSpecifier alloc] initWithParameters:[NSArray arrayWithObject:@"master"]];
	
	//[repo reloadRefs];
	[revList walkRevisionListWithSpecifier:revSpecifier];
	
	return 0;
}