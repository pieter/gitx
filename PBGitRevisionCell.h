//
//  PBGitRevisionCell.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitGrapher.h"
#import "PBGraphCellInfo.h"
#import "PBGitHistoryController.h"

@interface PBGitRevisionCell : NSActionCell {
	id objectValue;
	PBGraphCellInfo *cellInfo;
	NSTextFieldCell *textCell;
	IBOutlet PBGitHistoryController *controller;
}

@property(retain) PBGitCommit* objectValue;
@end
