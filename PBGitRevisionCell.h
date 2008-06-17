//
//  PBGitRevisionCell.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBGitRevisionCell : NSTextFieldCell {
	NSNumber* commit;
}

@property(retain) NSNumber* commit;
@end
