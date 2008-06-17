//
//  PBQLOutlineView.h
//  GitX
//
//  Created by Pieter de Bie on 6/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBDetailController.h"

@interface PBQLOutlineView : NSOutlineView {
	IBOutlet PBDetailController* controller;
}

@end
