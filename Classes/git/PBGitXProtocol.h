//
//  PBGitXProtocol.h
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@interface PBGitXProtocol : NSURLProtocol {
	NSFileHandle *handle;
}
@end

@interface NSURLRequest (PBGitXProtocol)
@property (readonly) PBGitRepository *repository;
@end

@interface NSMutableURLRequest (PBGitXProtocol)
@property (retain) PBGitRepository *repository;
@end

