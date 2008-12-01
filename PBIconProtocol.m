//
//  PBGitXProtocol.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBIconProtocol.h"

@implementation PBIconProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request
{
	return [[[request URL] scheme] isEqualToString:@"PBIcon"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

-(void)startLoading
{
	NSString *extension = [[[[self request] URL] description] pathExtension];

	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
	data = [icon TIFFRepresentation];

    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[[self request] URL]
														MIMEType:@"image/tiff"
										   expectedContentLength:[data length]
												textEncodingName:nil];

    [[self client] URLProtocol:self
			didReceiveResponse:response
			cacheStoragePolicy:NSURLCacheStorageAllowed];

    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void) stopLoading
{

}

@end