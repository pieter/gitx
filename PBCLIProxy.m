//
//  PBCLIProxy.m
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
#import "PBGitBinary.h"
#import "PBDiffWindowController.h"

@implementation PBCLIProxy
@synthesize connection;

- (id)init
{
	if (self = [super init]) {
		connection = [NSConnection new];
		[connection setRootObject:self];

		if ([connection registerName:PBDOConnectionName] == NO)
			NSBeep();
	}
	return self;
}

- (BOOL)openRepository:(NSString *)repositoryPath arguments: (NSArray*) args error:(NSError**)error
{
	// FIXME I found that creating this redundant NSURL reference was necessary to
	// work around an apparent bug with GC and Distributed Objects
	// I am not familiar with GC though, so perhaps I was doing something wrong.
    
    // !!! Andre Berg 20100326: This is because NSURL objects are passed by reference
    // See NSObject's implementation of -replacementObjectForPortCoder: where it says
    // "Subclasses that want to be passed by copy instead of by reference must override 
    // this method and return self."
    // In other words we either make a subclass of NSURL that returns self for that implementation
    // or we simply pass the path as NSString which is always bycopy.
    // See also http://jens.mooseyard.com/2009/07/the-subtle-dangers-of-distributed-objects/#comment-3068
    //
	NSURL* url = [NSURL fileURLWithPath:repositoryPath isDirectory:YES];
	NSArray* arguments = [NSArray arrayWithArray:args];

	PBGitRepository *document = [[PBRepositoryDocumentController sharedDocumentController] documentForLocation:url];
	if (!document) {
		if (error) {
            NSString *suggestion = nil;
            NSInteger errCode = -1;
            
            if ([PBGitBinary path]) {
                suggestion = @"this isn't a git repository";
                errCode = PBNotAGitRepositoryErrorCode;
            } else {
                suggestion = @"GitX can't find your git binary";
                errCode = PBGitBinaryNotFoundErrorCode;
            }
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not create document. Perhaps %@", suggestion]
																 forKey:NSLocalizedFailureReasonErrorKey];

			*error = [NSError errorWithDomain:PBCLIProxyErrorDomain code:errCode userInfo:userInfo];
		}
		return NO;
	}

    NSLog(@"document = %@ at path = %@", document, repositoryPath);      
    
    document.launchedFromCLI = YES;

	if ([arguments count] > 0 && ([[arguments objectAtIndex:0] isEqualToString:@"--commit"] ||
		[[arguments objectAtIndex:0] isEqualToString:@"-c"]))
		[document.windowController showCommitView:self];
	else {
        PBGitRevSpecifier* rev = nil;
        if ([arguments count] > 0 && [[arguments objectAtIndex:0] isEqualToString:@"--all"]) {
            document.currentBranchFilter = kGitXAllBranchesFilter;
            [document readCurrentBranch];
            rev = document.currentBranch;
        } else if ([arguments count] > 0 && [[arguments objectAtIndex:0] isEqualToString:@"--local"]) {
            document.currentBranchFilter = kGitXLocalRemoteBranchesFilter;
            [document readCurrentBranch];
            rev = document.currentBranch;
        }
        
        if (!rev) {
            rev = [[PBGitRevSpecifier alloc] initWithParameters:arguments];
            rev.workingDirectory = url;
            document.currentBranch = [document addBranch: rev];
        }
        
		[document.windowController showHistoryView:self];
	}
	[NSApp activateIgnoringOtherApps:YES];

	return YES;
}

- (void)openDiffWindowWithDiff:(NSString *)diff
{
	PBDiffWindowController *diffController = [[PBDiffWindowController alloc] initWithDiff:[diff copy]];
	[diffController showWindow:nil];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}
@end
