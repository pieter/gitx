//
//  PBGitRevSpecifier.m
//  GitX
//
//  Created by Pieter de Bie on 12-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevSpecifier.h"


@implementation PBGitRevSpecifier

@synthesize parameters;

- (id) initWithParameters:(NSArray*) params
{
	parameters = params;
	description = nil;
	return self;
}

- (id) initWithRef: (PBGitRef*) ref
{
	parameters = [NSArray arrayWithObject: ref.ref];
	description = ref.shortName;
	return self;
}

- (BOOL) isSimpleRef
{
	return ([parameters count] == 1 && ![[parameters objectAtIndex:0] hasPrefix:@"-"]);
}

- (NSString*) simpleRef
{
	if (![self isSimpleRef])
		return nil;
	return [parameters objectAtIndex:0];
}

- (NSString*) description
{
	if (description)
		return description;
	
	return [parameters componentsJoinedByString:@" "];
}

- (BOOL) hasPathLimiter;
{
	for (NSString* param in parameters)
		if ([param isEqualToString:@"--"])
			return YES;
	return NO;
}

- (BOOL) isEqualTo: (PBGitRevSpecifier*) other
{
	if ([self isSimpleRef] ^ [other isSimpleRef])
		return NO;
	
	if ([self isSimpleRef])
		return [[self description] isEqualToString: [other description]];

	return ([[parameters componentsJoinedByString:@" "] isEqualToString: [other.parameters componentsJoinedByString:@" "]] &&
			 (!description  || [description isEqualToString:other.description]));
}
@end
