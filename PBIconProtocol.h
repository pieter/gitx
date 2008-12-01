//
//  PBIconProtocol.h
//  GitX
//
//  Created by Pieter de Bie on 01-12-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBIconProtocol : NSURLProtocol  {
	NSData *data;
	NSURL *url;
}

@end