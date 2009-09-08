//
//  PBSourceViewItem.h
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBSourceViewItem : NSObject {
	NSString *name;
}

- (id)initWithName:(NSString *)name;

@property(retain) NSString *name;
@property(readonly) NSArray *children;
@end
