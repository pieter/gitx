//
//  MGRecessedPopUpButtonCell.h
//  MGScopeBar
//
//  Created by Matt Gemmell on 20/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import <Cocoa/Cocoa.h>

/*
 This cell class is used only for NSPopUpButtons which do NOT automatically 
 get their titles from their selected menu-items, since such popup-buttons 
 are weirdly broken when using the recessed bezel-style.
*/

@interface MGRecessedPopUpButtonCell : NSPopUpButtonCell {
	NSButton *recessedButton; // we use a separate NSButton to do the bezel-drawing.
}

@end
