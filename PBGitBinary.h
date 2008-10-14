//
//  PBGitBinary.h
//  GitX
//
//  Created by Pieter de Bie on 04-10-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBGitBinary : NSObject {

}

+ (NSString *) path;
+ (NSString *) version;
+ (NSArray *) searchLocations;
+ (NSString *) notFoundError;
@end
