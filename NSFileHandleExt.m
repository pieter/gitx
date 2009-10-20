/*
 *  Extension for NSFileHandle to make it capable of easy network programming
 *
 *  Version 1.0, get the newest from http://michael.stapelberg.de/NSFileHandleExt.php
 *
 *  Copyright 2007 Michael Stapelberg
 *
 *  Distributed under BSD-License, see http://michael.stapelberg.de/BSD.php
 *
 */


#define CONN_TIMEOUT 5
#define BUFFER_SIZE 256

#import <objc/objc-auto.h> /* for objc_collect */

@implementation NSFileHandle(NSFileHandleExt)

-(NSString*)readLine {
    
	// If the socket is closed, return an empty string
	if ([self fileDescriptor] <= 0)
		return @"";
	
	int fd = [self fileDescriptor];
	
	// Allocate BUFFER_SIZE bytes to store the line
	int bufferSize = BUFFER_SIZE;
	char *buffer = (char*)malloc(bufferSize + 1);
	if (buffer == NULL)
		[[NSException exceptionWithName:@"No memory left" reason:@"No more memory for allocating buffer" userInfo:nil] raise];
	
	int bytesReceived = 0, n = 1;
	
	while (n > 0) {
		n = read(fd, buffer + bytesReceived++, 1);
		
		if (n < 0)
			[[NSException exceptionWithName:@"Socket error" reason:@"Remote host closed connection" userInfo:nil] raise];
		
		if (bytesReceived >= bufferSize) {
			// Make buffer bigger
			bufferSize += BUFFER_SIZE;
			buffer = (char*)realloc(buffer, bufferSize + 1);
			if (buffer == NULL)
				[[NSException exceptionWithName:@"No memory left" reason:@"No more memory for allocating buffer" userInfo:nil] raise];
		}       
		
		switch (*(buffer + bytesReceived - 1)) {
			case '\n':
				buffer[bytesReceived-1] = '\0';
				NSString* s = [NSString stringWithCString: buffer encoding: NSUTF8StringEncoding];
				if ([s length] == 0)
					s = [NSString stringWithCString: buffer encoding: NSISOLatin1StringEncoding];
				return s;
			case '\r':
				bytesReceived--;
		}
	}       
	
	buffer[bytesReceived-1] = '\0';
	NSString *retVal = [NSString stringWithCString: buffer  encoding: NSUTF8StringEncoding];
	if ([retVal length] == 0)
		retVal = [NSString stringWithCString: buffer encoding: NSISOLatin1StringEncoding];
	
	free(buffer);
    
    [[NSGarbageCollector defaultCollector] collectExhaustively];
	return retVal;
}

@end
