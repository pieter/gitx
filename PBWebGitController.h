//
//  PBWebGitController.h
//  GitTest
//
//  Created by Pieter de Bie on 14-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApplicationController.h"
#import "PBGitCommit.h"
#import "PBDetailController.h"
#import <WebKit/WebKit.h>

@interface PBWebGitController : NSObject {
	IBOutlet ApplicationController* controller;
	IBOutlet WebView* view;
	IBOutlet PBDetailController* detailController;
	NSString* currentSha;
	NSString* diff;
}

- (void) changeContentTo: (PBGitCommit *) content;
@property (readonly) NSString* diff;
@end
