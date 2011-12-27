//
//  PBCommitMessageView.m
//  GitX
//
//  Created by Jeff Mesnil on 13/10/08.
//  Copyright 2008 Jeff Mesnil (http://jmesnil.net/). All rights reserved.
//

#import "PBCommitMessageView.h"
#import "PBGitDefaults.h"

@implementation PBCommitMessageView

- (void)drawRect:(NSRect)aRect
{
	[super drawRect:aRect];

	// draw a vertical line after the given size (used as an indicator
	// for the first line of the commit message)
    if ([PBGitDefaults commitMessageViewHasVerticalLine]) {
        float characterWidth = [@" " sizeWithAttributes:[self typingAttributes]].width;
        float lineWidth = characterWidth * [PBGitDefaults commitMessageViewVerticalLineLength];

        [[NSColor lightGrayColor] set];
        float padding = [[self textContainer] lineFragmentPadding];
        NSRect line;
        line.origin.x = padding + lineWidth;
        line.origin.y = 0;
        line.size.width = 1;
        line.size.height = [self bounds].size.height;
        NSRectFill(line);
    }
}

@end
