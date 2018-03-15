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

@interface NSMenuItem (PBRefMenuItem)

+ (NSArray *)pb_defaultMenuItemsForRef:(PBGitRef *)refs inRepository:(PBGitRepository *)repo;
+ (NSArray *)pb_defaultMenuItemsForCommits:(NSArray<PBGitCommit *> *)commits;

@end
