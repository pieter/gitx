//
//  PBGitRef.h
//  GitX
//
//  Created by Pieter de Bie on 06-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBGitRef : NSObject {
	NSString* ref;
}

- (NSString*) shortName;
- (NSString*) type;
+ (PBGitRef*) refFromString: (NSString*) s;
- (PBGitRef*) initWithString: (NSString*) s;
@property(readonly) NSString* ref;

@end
