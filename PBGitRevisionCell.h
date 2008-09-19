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

@interface PBGitRevisionCell : NSActionCell {
	id objectValue;
	PBGraphCellInfo*	cellInfo;
	NSTextFieldCell* textCell;
}

@property(retain) PBGitCommit* objectValue;
@end
