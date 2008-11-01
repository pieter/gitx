//
//  PBRefMenuItem.h
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRef.h"
#import "PBGitCommit.h"

@interface PBRefMenuItem : NSMenuItem {
	PBGitRef *ref;
	PBGitCommit *commit;
}
	
@property (retain) PBGitCommit *commit;
@property (retain) PBGitRef *ref;

+ (NSArray *)defaultMenuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit target:(id)target;

@end
