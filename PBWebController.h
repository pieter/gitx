//
//  PBWebController.h
//  GitX
//
//  Created by Pieter de Bie on 08-10-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface PBWebController : NSObject {
	IBOutlet WebView* view;
	NSString *startFile;
	BOOL finishedLoading;
}

@property (retain) NSString *startFile;
@end
