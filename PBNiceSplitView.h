//
//  PBNiceSplitView.h
//  GitX
//
//  Created by Pieter de Bie on 31-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBNiceSplitView : NSSplitView {

}

- (void) restoreDefault: (NSString *) defaultName;
- (void) saveDefault: (NSString *) defaultName;

@end
