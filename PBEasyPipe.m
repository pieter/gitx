//
//  PBEasyPipe.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBEasyPipe.h"


@implementation PBEasyPipe

+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args
{
	return [self handleForCommand:cmd withArgs:args inDir:nil];
}

+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args inDir: (NSString*) dir
{
	NSTask* task = [[NSTask alloc] init];
	task.launchPath = cmd;
	task.arguments = args;
	if (dir)
		task.currentDirectoryPath = dir;
	NSLog(@"Starting `cmd %@ %@` in dir %@", cmd, [args componentsJoinedByString:@" "], dir);
	NSPipe* pipe = [NSPipe pipe];
	task.standardOutput = pipe;
	
	NSFileHandle* handle = [NSFileHandle fileHandleWithStandardOutput];
	handle = [pipe fileHandleForReading];
	
	[task launch];
	return handle;
}



+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args inDir: (NSString*) dir
{
	NSFileHandle* handle = [self handleForCommand:cmd withArgs: args inDir: dir];
	NSData* data = [handle readDataToEndOfFile];
	NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];
	
	return string;
}	
+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args
{
	return [self outputForCommand:cmd withArgs:args inDir:nil];
}

@end
