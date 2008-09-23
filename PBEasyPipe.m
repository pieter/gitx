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

+ (NSTask *) taskForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir
{
	NSTask* task = [[NSTask alloc] init];
	task.launchPath = cmd;
	task.arguments = args;
	if (dir)
		task.currentDirectoryPath = dir;
	
	NSLog(@"Starting `cmd %@ %@` in dir %@", cmd, [args componentsJoinedByString:@" "], dir);
	NSPipe* pipe = [NSPipe pipe];
	task.standardOutput = pipe;
	return task;
}

+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args inDir: (NSString*) dir
{
	NSTask *task = [self taskForCommand:cmd withArgs:args inDir:dir];
	NSFileHandle* handle = [task.standardOutput fileHandleForReading];
	
	[task launch];
	return handle;
}



+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
				      retValue:(int *)      ret
{
	NSTask *task = [self taskForCommand:cmd withArgs:args inDir:dir];
	NSFileHandle* handle = [task.standardOutput fileHandleForReading];
	[task launch];
	
	NSData* data = [handle readDataToEndOfFile];
	NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];
	
	[task waitUntilExit];
	if (ret)
		*ret = [task terminationStatus];
	return string;
}	

+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
				   inputString:(NSString *)input
				      retValue:(int *)      ret
{
	NSTask *task = [self taskForCommand:cmd withArgs:args inDir:dir];
	NSFileHandle* handle = [task.standardOutput fileHandleForReading];
	task.standardInput = [NSPipe pipe];
	NSFileHandle *inHandle = [task.standardInput fileHandleForWriting];
	[inHandle writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
	[inHandle closeFile];
	
	[task launch];
	
	NSData* data = [handle readDataToEndOfFile];
	NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];
	
	[task waitUntilExit];
	if (ret)
		*ret = [task terminationStatus];
	return string;
}	

// We don't use the above function because then we'd have to wait until the program was finished
// with running

+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args  inDir: (NSString*) dir
{
	NSTask *task = [self taskForCommand:cmd withArgs:args inDir:dir];
	NSFileHandle* handle = [task.standardOutput fileHandleForReading];
	
	[task launch];
	
	NSData* data = [handle readDataToEndOfFile];
	NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];
	return string;
}


+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args
{
	return [self outputForCommand:cmd withArgs:args inDir:nil];
}

@end
