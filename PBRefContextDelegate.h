//
//  PBRefContextDelegate.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//



@protocol PBRefContextDelegate
- (NSArray *) menuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit;
@end
