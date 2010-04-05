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

- (BOOL) openRepository:(in bycopy NSString *)repositoryPath arguments:(in bycopy NSArray *)args error:(byref NSError **)error
{
    NSLog(@"============================== PBCLIProxy START ==============================");

    if (!repositoryPath || !args) {
        return NO;
    }

	// FIXME I found that creating this redundant NSURL reference was necessary to
	// work around an apparent bug with GC and Distributed Objects
	// I am not familiar with GC though, so perhaps I was doing something wrong.
    //
    // !!! Andre Berg 20100326: This is because NSURL objects are passed as proxies
    // See also http://jens.mooseyard.com/2009/07/the-subtle-dangers-of-distributed-objects/#comment-3069
    // We should be able to adjust this by using bycopy modifiers.
    //
	NSURL* url = [NSURL fileURLWithPath:repositoryPath isDirectory:YES];
    NSString * fullargs = [args componentsJoinedByString:@" "];
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
        NSLog(@"============================== PBCLIProxy Abort ==============================");
		return NO;
	} else if (![document checkRefFormat:fullargs] &&
             ![document checkRefFormatForBranch:fullargs]) {

        NSString * suggestion = @"the arguments passed do not constitute a valid ref format";
        NSString * recoveryInfo = @"(see git help check-ref-format)";
        NSInteger errCode = PBNotAValidRefFormatErrorCode;

        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat: @"Ignoring parameters passed to gitx. It appears %@.",
                                   suggestion], NSLocalizedFailureReasonErrorKey,
                                  recoveryInfo, NSLocalizedRecoverySuggestionErrorKey, nil];

        *error = [NSError errorWithDomain:PBCLIProxyErrorDomain code:errCode userInfo:userInfo];

        fprintf(stderr, "\t%s\n", [[*error localizedFailureReason] UTF8String]);
    }

    NSLog(@"document = %@ at path = %@", document, repositoryPath);

// 	if ([args count] > 0 && ([[args objectAtIndex:0] isEqualToString:@"--commit"] ||
// 		[[args objectAtIndex:0] isEqualToString:@"-c"])) {
//         [document.windowController showCommitView:self];
//     }
//     else if ([args count] > 0 && ([[args objectAtIndex:0] hasPrefix:@"--author"])) {
//         NSArray * components = [[args objectAtIndex:0] componentsSeparatedByString:@"="];
//         NSString * author = [components objectAtIndex:1];
//         NSArrayController * ccontroller = document.windowController.historyController.commitController;
//         [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"author contains[c] %@", author]];
//         [document.windowController.historyController.commitList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
//     } else if ([args count] > 0 && ([[args objectAtIndex:0] hasPrefix:@"--subject"])) {
//         NSArray * components = [[args objectAtIndex:0] componentsSeparatedByString:@"="];
//         NSString * subject = [components objectAtIndex:1];
//         NSArrayController * ccontroller = document.windowController.historyController.commitController;
//         [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"subject contains[c] %@", subject]];
//     } else if ([args count] > 0 && ([[args objectAtIndex:0] hasPrefix:@"--sha"])) {
//         NSArray * components = [[args objectAtIndex:0] componentsSeparatedByString:@"="];
//         NSString * sha = [components objectAtIndex:1];
//         NSArrayController * ccontroller = document.windowController.historyController.commitController;
//         [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"realSha contains[c] %@", sha]];
//     } else if ([args count] > 0 && ([[args objectAtIndex:0] hasPrefix:@"-S"])) {
//         NSString * subject = [[args objectAtIndex:0] substringFromIndex:2];
//         NSArrayController * ccontroller = document.windowController.historyController.commitController;
//         [ccontroller setFilterPredicate:[NSPredicate predicateWithFormat:@"subject contains[c] %@", subject]];
//     }

//     if ([args count] > 0 && [[args objectAtIndex:0] isEqualToString:@"--all"]) {
//         document.currentBranchFilter = kGitXAllBranchesFilter;
//     } else if ([args count] > 0 && [[args objectAtIndex:0] isEqualToString:@"--local"]) {
//         document.currentBranchFilter = kGitXLocalRemoteBranchesFilter;
//     }
    
//     [document readCurrentBranch];
//     rev = document.currentBranch;
//
//     if (!rev && [args count] > 0) {
//         rev = [[PBGitRevSpecifier alloc] initWithParameters:args];
//         document.currentBranch = rev;
//         document.currentBranchFilter = kGitXSelectedBranchFilter;
//     }
        
	[NSApp activateIgnoringOtherApps:YES];

    NSLog(@"============================== PBCLIProxy END ==============================");
	return YES;
}

- (oneway void) openDiffWindowWithDiff:(in bycopy NSString *)diff
{
	PBDiffWindowController *diffController = [[PBDiffWindowController alloc] initWithDiff:[diff copy]];
	[diffController showWindow:nil];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}
@end
