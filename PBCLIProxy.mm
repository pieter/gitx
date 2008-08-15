//
//  PBCLIProxy.mm
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBCLIProxy.h"

@implementation PBCLIProxy
@synthesize connection;

- (id)init
{
	if (self = [super init]) {
		self.connection = [NSConnection new];
		[self.connection setRootObject:self];

		if ([self.connection registerName:ConnectionName] == NO)
			NSBeep();

	}
	return self;
}
@end
