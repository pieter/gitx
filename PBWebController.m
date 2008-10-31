//
//  PBWebController.m
//  GitX
//
//  Created by Pieter de Bie on 08-10-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBWebController.h"
#import "PBGitRepository.h"
#include <SystemConfiguration/SCNetworkReachability.h>

@implementation PBWebController

@synthesize startFile;

- (void) awakeFromNib
{
	NSString *path = [NSString stringWithFormat:@"html/views/%@", startFile];
	NSString* file = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:path];
	NSLog(@"path: %@, file: %@", path, file);
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:file]];
	callbacks = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsObjectPointerPersonality|NSPointerFunctionsStrongMemory) valueOptions:(NSPointerFunctionsObjectPointerPersonality|NSPointerFunctionsStrongMemory)];

	finishedLoading = NO;
	[view setUIDelegate:self];
	[view setFrameLoadDelegate:self];
	[[view mainFrame] loadRequest:request];
}

- (WebScriptObject *) script
{
	return [view windowScriptObject];
}

# pragma mark Delegate methods

- (void) webView:(id) v didFinishLoadForFrame:(id) frame
{
	id script = [view windowScriptObject];
	[script setValue: self forKey:@"Controller"];

	finishedLoading = YES;
	if ([self respondsToSelector:@selector(didLoad)])
		[self performSelector:@selector(didLoad)];
}

- (void)webView:(WebView *)webView addMessageToConsole:(NSDictionary *)dictionary
{
	NSLog(@"Error from webkit: %@", dictionary);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}

#pragma mark Functions to be used from JavaScript

- (void) log: (NSString*) logMessage
{
	NSLog(@"%@", logMessage);
}

- (BOOL) isReachable:(NSString *)hostname
{
	SCNetworkConnectionFlags flags;
	if (!SCNetworkCheckReachabilityByName([hostname cStringUsingEncoding:NSASCIIStringEncoding], &flags))
		return FALSE;

	// If a connection is required, then it's not reachable
	if (flags & (kSCNetworkFlagsConnectionRequired | kSCNetworkFlagsConnectionAutomatic | kSCNetworkFlagsInterventionRequired))
		return FALSE;

	return flags > 0;
}

#pragma mark Using async function from JS

- (void) runCommand:(WebScriptObject *)arguments inRepository:(PBGitRepository *)repository callBack:(WebScriptObject *)callBack
{
	// The JS bridge does not handle JS Arrays, even though the docs say it does. So, we convert it ourselves.
	int length = [[arguments valueForKey:@"length"] intValue];
	NSMutableArray *realArguments = [NSMutableArray arrayWithCapacity:length];
	int i = 0;
	for (i = 0; i < length; i++)
		[realArguments addObject:[arguments webScriptValueAtIndex:i]];

	NSFileHandle *handle = [repository handleInWorkDirForArguments:realArguments];
	[callbacks setObject:callBack forKey:handle];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(JSRunCommandDone:) name:NSFileHandleReadToEndOfFileCompletionNotification object:handle]; 
	[handle readToEndOfFileInBackgroundAndNotify];
}

- (void) callSelector:(NSString *)selectorString onObject:(id)object callBack:(WebScriptObject *)callBack
{
	NSArray *arguments = [NSArray arrayWithObjects:selectorString, object, nil];
	NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runInThread:) object:arguments];
	[callbacks setObject:callBack forKey:thread];
	[thread start];
}

- (void) runInThread:(NSArray *)arguments
{
	SEL selector = NSSelectorFromString([arguments objectAtIndex:0]);
	id object = [arguments objectAtIndex:1];
	id ret = [object performSelector:selector];
	NSArray *returnArray = [NSArray arrayWithObjects:[NSThread currentThread], ret, nil];
	[self performSelectorOnMainThread:@selector(threadFinished:) withObject:returnArray waitUntilDone:NO];
}


- (void) returnCallBackForObject:(id)object withData:(id)data
{
	WebScriptObject *a = [callbacks objectForKey: object];
	if (!a) {
		NSLog(@"Could not find a callback for object: %@", object);
		return;
	}

	[callbacks removeObjectForKey:object];
	[a callWebScriptMethod:@"call" withArguments:[NSArray arrayWithObjects:@"", data, nil]];
}

- (void) threadFinished:(NSArray *)arguments
{
	[self returnCallBackForObject:[arguments objectAtIndex:0] withData:[arguments objectAtIndex:1]];
}

- (void) JSRunCommandDone:(NSNotification *)notification
{
	NSString *data = [[NSString alloc] initWithData:[[notification userInfo] valueForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
	[self returnCallBackForObject:[notification object] withData:data];
}

@end
