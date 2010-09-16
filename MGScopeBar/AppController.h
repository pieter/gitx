//
//  AppController.h
//  MGScopeBar
//
//  Created by Matt Gemmell on 16/03/2008.
//

#import <Cocoa/Cocoa.h>
#import "MGScopeBarDelegateProtocol.h"

@interface AppController : NSObject <MGScopeBarDelegate> {
	IBOutlet NSTextField *labelField;
	IBOutlet MGScopeBar *scopeBar;
	IBOutlet NSView *accessoryView;
	NSMutableArray *groups;
}

@property(retain) NSMutableArray *groups;

@end
