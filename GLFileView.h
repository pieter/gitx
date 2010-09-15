//
//  GLFileView.h
//  GitX
//
//  Created by German Laullon on 14/09/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBWebController.h"

#import "PBGitCommit.h"
#import "PBGitHistoryController.h"
#import "PBRefContextDelegate.h"


@interface GLFileView : PBWebController {
	IBOutlet PBGitHistoryController* historyController;
}

@end
