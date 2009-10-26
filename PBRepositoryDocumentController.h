//
//  PBRepositoryDocumentController.h
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRevSpecifier.h"


@interface PBRepositoryDocumentController : NSDocumentController
{
	IBOutlet NSWindow *cloneWindow;
	IBOutlet NSTextField *cloneURLField;
}

- (id) documentForLocation:(NSURL*) url;
- (IBAction) cloneURL:(id)sender;
- (IBAction) showClone:(id)sender;
- (IBAction) hideClone:(id)sender;

@end
