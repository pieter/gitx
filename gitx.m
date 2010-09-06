//
//  gitx.m
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBCLIProxy.h"
#import "PBGitBinary.h"
#import "PBEasyPipe.h"
#import "PBGitRepository.h"
#include <sys/syslimits.h>      /* for ARG_MAX */

NSDistantObject* connectToProxy()
{
	id proxy = [NSConnection rootProxyForConnectionWithRegisteredName:PBDOConnectionName host:nil];
	[proxy setProtocolForProxy:@protocol(GitXCliToolProtocol)];
	return proxy;
}

NSDistantObject *createProxy()
{
	NSDistantObject * proxy = connectToProxy();

	if (proxy) {
        return proxy;
    }

	// The connection failed, so try to launch the app
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"nl.frim.GitX"
														 options:NSWorkspaceLaunchWithoutActivation
								  additionalEventParamDescriptor:nil
												launchIdentifier:nil];

	// Now attempt to connect, allowing the app time to startup
	int attempt;
	for (attempt = 0; proxy == nil && attempt < 50; ++attempt) {
		if ( (proxy = connectToProxy()) != nil )
			return proxy;
		usleep(15000);
	}
    
    if (proxy) {
        return proxy;
    }

	// not succesful!
	fprintf(stderr, "Couldn't connect to app server!\n");
	exit(1);
	return nil;
}

void usage(char const *programName)
{

	printf("Usage: %s (-h|--help|--version)\n", programName);
	printf("   or: %s (--commit)\n", programName);
	printf("   or: %s (--subject=<subject>|--sha=<sha>|--author=<author>)\n", programName);
	printf("   or: %s <revlist options>\n", programName);
	printf("\n");
	printf("\t-h, --help          print this help\n");
	printf("\t--commit, -c        start GitX in commit mode\n");
	printf("\n");
	printf("RevList options\n");
	printf("\tSee 'man git-log' and 'man git-rev-list' for options you can pass to gitx\n");
	printf("\n");
	printf("\t--all                  show all branches\n");
    printf("\t--local                show local branches\n");
    printf("\t--sha=<sha>            filter the current branch for <sha>\n");
    printf("\t--author=<author>      filter the current branch for <author>\n");
    printf("\t--subject=<subject>    filter the current branch for <subject>\n");
    printf("\t-S<subject>            same as above (included for legacy compatibility)\n");
	printf("\t<branch>               show specific branch\n");
	printf("\t -- <path>             show commits touching paths\n");
	exit(1);
}

void version_info()
{
	NSString *version = [[[NSBundle bundleForClass:[PBGitBinary class]] infoDictionary] valueForKey:@"CFBundleVersion"];
	printf("This is GitX version %s\n", [version UTF8String]);
	if ([PBGitBinary path])
		printf("Using git found at %s, version %s\n", [[PBGitBinary path] UTF8String], [[PBGitBinary version] UTF8String]);
	else
		printf("GitX cannot find a git binary\n");
	exit(1);
}

void git_path()
{
	if (![PBGitBinary path])
		exit(101);

	NSString *path = [[PBGitBinary path] stringByDeletingLastPathComponent];
	printf("%s", [path UTF8String]);
	exit(0);
}

void handleSTDINDiff(id<GitXCliToolProtocol> proxy)
{
	NSFileHandle *handle = [NSFileHandle fileHandleWithStandardInput];
	NSData *data = [handle readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	if (string && [string length] > 0) {
		[proxy openDiffWindowWithDiff:string];
		exit(0);
	}
}

void handleDiffWithArguments(NSArray *arguments, NSString *directory, id<GitXCliToolProtocol> proxy)
{
	int ret;
	arguments = [[NSArray arrayWithObject:@"diff"] arrayByAddingObjectsFromArray:arguments];
	NSString *diff = [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:arguments inDir:directory retValue:&ret];
	if (ret) {
		printf("Invalid diff command\n");
		exit(3);
	}

	[proxy openDiffWindowWithDiff:diff];
	exit(0);
}

int main(int argc, const char** argv)
{
	if (argc >= 2 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h")))
		usage(argv[0]);
	if (argc >= 2 && (!strcmp(argv[1], "--version") || !strcmp(argv[1], "-v")))
		version_info();
	if (argc >= 2 && !strcmp(argv[1], "--git-path"))
		git_path();

	if (![PBGitBinary path]) {
		printf("%s\n", [[PBGitBinary notFoundError] UTF8String]);
		exit(2);
	}
    
	// Create arguments
	argv++; argc--;
    
    NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:argc];
    int i = 0;
    for (i = 0; i < argc; i++)
        [arguments addObject: [NSString stringWithUTF8String:argv[i]]];
    
    // I hate using env vars for this but I don't see how else we get the parameters
    // to the Application client as the proxy connection routines above start up the
    // ApplicationController which in turn initializes the PBCLIProxy and starts with
    // the usual business of calling -populateList from PBGitSidebarController.
    NSString * fullargs = [arguments componentsJoinedByString:@" "];
    if ([fullargs length] <= ARG_MAX) {
        setenv("GITX_CLI_ARGUMENTS", [fullargs UTF8String], 1);
        setenv("GITX_LAUNCHED_FROM_CLI", "YES", 1);
    } else {
        fprintf(stderr, "Argument size exceeds system limit of (%d)! Ignoring args.", ARG_MAX);
    }
    
   id proxy = createProxy();
    
	if (!isatty(STDIN_FILENO) && fdopen(STDIN_FILENO, "r"))
		handleSTDINDiff(proxy);

	// From this point, we require a working directory
	NSString *pwd = [[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"];
	if (!pwd)
		exit(2);

	if ([arguments count] > 0 && ([[arguments objectAtIndex:0] isEqualToString:@"--diff"] ||
		[[arguments objectAtIndex:0] isEqualToString:@"-d"]))
		handleDiffWithArguments([arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)], pwd, proxy);

	// No diff, just open the current dir
	NSError* error = nil;

	if (![proxy openRepository:pwd arguments: arguments error:&error]) {
		fprintf(stderr, "Error opening repository at %s\n", [pwd UTF8String]);
		if (error)
			fprintf(stderr, "\t%s\n", [[error localizedFailureReason] UTF8String]);
        return 1;
	}
        
	return 0;
}
