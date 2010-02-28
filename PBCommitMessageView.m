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
        // This depends upon the fact that NSTextView always redraws complete lines.
        float padding = [[self textContainer] lineFragmentPadding];
        NSRect line;
        line.origin.x = padding + aRect.origin.x + lineWidth;
        line.origin.y = aRect.origin.y;
        line.size.width = 1;
        line.size.height = aRect.size.height;
        NSRectFill(line);
    }
}

@end
