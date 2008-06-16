//
//  PBDetailController.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitCommit.h"
#import "PBGitTree.h"

@interface PBDetailController : NSObject {
	IBOutlet NSNumber* selectedTab;
	IBOutlet NSArrayController* commitController;

	PBGitTree* gitTree;
	PBGitCommit* webCommit;
	PBGitCommit* rawCommit;
	PBGitCommit* realCommit;
}

@property (copy) NSNumber* selectedTab;
@property (retain) PBGitCommit* webCommit;
@property (retain) PBGitCommit* rawCommit;
@property (retain) PBGitTree* gitTree;

@end
