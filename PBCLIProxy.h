//
//  PBCLIProxy.h
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitXErrors.h"

@interface PBCLIProxy : NSObject
{
	NSConnection *connection;
}
@property (retain) NSConnection* connection;
@end

#define PBDOConnectionName @"GitXDOConnection"
#define PBCLIProxyErrorDomain @"PBCLIProxyErrorDomain"

@protocol GitXCliToolProtocol
- (BOOL)openRepository:(NSString *)repositoryPath arguments: (NSArray*) args error:(NSError**)error;
- (void)openDiffWindowWithDiff:(NSString *)diff;
@end