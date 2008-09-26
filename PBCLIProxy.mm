//
//  PBCLIProxy.mm
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBCLIProxy.h"
#import "PBRepositoryDocumentController.h"
#import "PBGitRevSpecifier.h"
#import "PBGitRepository.h"
#import "PBGitWindowController.h"

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

- (BOOL)openRepository:(NSURL*)repositoryPath arguments: (NSArray*) args error:(NSError**)error;
{
	// FIXME I found that creating this redundant NSURL reference was necessary to
	// work around an apparent bug with GC and Distributed Objects
	// I am not familiar with GC though, so perhaps I was doing something wrong.
	NSURL* url = [NSURL fileURLWithPath:[repositoryPath path]];
	NSArray* arguments = [NSArray arrayWithArray:args];

	PBGitRepository *document = [[PBRepositoryDocumentController sharedDocumentController] documentForLocation:url];
	if (!document)
		return NO;
	
	if ([arguments count] > 0 && ([[arguments objectAtIndex:0] isEqualToString:@"--commit"] ||
		[[arguments objectAtIndex:0] isEqualToString:@"-c"]))
		((PBGitWindowController *)document.windowController).selectedViewIndex = 1;
	else {
		PBGitRevSpecifier* rev = [[PBGitRevSpecifier alloc] initWithParameters:arguments];
		[document selectBranch: [document addBranch: rev]];
	}
	[NSApp activateIgnoringOtherApps:YES];

	return YES;
}
@end
