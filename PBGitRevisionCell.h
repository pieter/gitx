//
//  PBGitRevisionCell.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitGrapher.h"

@interface PBGitRevisionCell : NSTextFieldCell {
	PBGitCellInfo cellInfo;
	BOOL isReady;
}

@property(assign)  PBGitCellInfo cellInfo;
@end
