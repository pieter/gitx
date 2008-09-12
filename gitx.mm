//
//  gitx.mm
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBCLIProxy.h"

NSDistantObject* connect()
{
	id proxy = [NSConnection rootProxyForConnectionWithRegisteredName:ConnectionName host:nil];
	[proxy setProtocolForProxy:@protocol(GitXCliToolProtocol)];
	return proxy;
}


int main(int argc, const char** argv)
{
	// Attempt to connect to the app
	id proxy = connect();

	if (!proxy) {
		// If the connection failed, try to launch the app
		[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier: @"nl.frim.GitX"
															 options: NSWorkspaceLaunchWithoutActivation
									  additionalEventParamDescriptor: nil
													launchIdentifier: nil];

		// Now attempt to connect, allowing the app time to startup
		for (int attempt = 0; proxy == nil && attempt < 50; ++attempt){
			if (proxy = connect())
				break;
			usleep(15000);
		}
	}
	if (!proxy) {
		fprintf(stderr, "Couldn't connect to app server!\n");
		exit(1);
	}

	if ([[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"]) {
		int i;
		argv++; argc--;
		NSURL* url     = [NSURL fileURLWithPath:[[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"]];

		NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:argc];
		for (i = 0; i < argc; i++)
			[arguments addObject: [NSString stringWithCString:argv[i]]];

		NSError* error = nil;
		if (![proxy openRepository:url arguments: arguments error:&error]) {
			fprintf(stderr, "Error opening repository at %s", [[url path] UTF8String]);
			if (error) {
				fprintf(stderr, ": %s", [[error localizedFailureReason] UTF8String]);
			}
			fprintf(stderr, "\n");
		}
	}
}
