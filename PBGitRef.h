//
//  PBGitRef.h
//  GitX
//
//  Created by Pieter de Bie on 06-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const kGitXTagRefPrefix;
extern NSString * const kGitXBranchRefPrefix;
extern NSString * const kGitXRemoteRefPrefix;


@interface PBGitRef : NSObject {
	NSString* ref;
}

- (NSString*) shortName;
- (NSString *) tagName;
- (NSString *) branchName;
- (NSString *) remoteName;
- (NSString *) remoteBranchName;

- (NSString*) type;
- (BOOL) isBranch;
- (BOOL) isTag;
- (BOOL) isRemote;
- (BOOL) isRemoteBranch;

- (PBGitRef *) remoteRef;

- (BOOL) isEqualToRef:(PBGitRef *)otherRef;

+ (PBGitRef*) refFromString: (NSString*) s;
- (PBGitRef*) initWithString: (NSString*) s;
@property(readonly) NSString* ref;

@end
