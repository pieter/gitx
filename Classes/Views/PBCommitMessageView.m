//
//  PBCommitMessageView.m
//  GitX
//
//  Created by Jeff Mesnil on 13/10/08.
//  Copyright 2008 Jeff Mesnil (http://jmesnil.net/). All rights reserved.
//

#import "PBCommitMessageView.h"

#import "PBGitDefaults.h"
#import "PBGitRepository.h"

@implementation PBCommitMessageView

- (void) awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults addObserver:self
               forKeyPath:@"PBCommitMessageViewHasVerticalLine"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [defaults addObserver:self
               forKeyPath:@"PBCommitMessageViewVerticalLineLength"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [defaults addObserver:self
               forKeyPath:@"PBCommitMessageViewVerticalBodyLineLength"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)aRect
{
	[super drawRect:aRect];

    if ([PBGitDefaults commitMessageViewHasVerticalLine]) {

        float characterWidth = [@" " sizeWithAttributes:[self typingAttributes]].width;
        float lineWidth = characterWidth * [PBGitDefaults commitMessageViewVerticalLineLength];
        NSRect line;
        float padding;
        float textViewHeight = [self bounds].size.height;

        // draw a vertical line after the given size (used as an indicator
        // for the first line of the commit message)
        [[NSColor lightGrayColor] set];
        padding = [[self textContainer] lineFragmentPadding];
        line.origin.x = padding + lineWidth;
        line.origin.y = 0;
        line.size.width = 1;
        line.size.height = textViewHeight;
        NSRectFill(line);

        // and one for the body of the commit message
        lineWidth = characterWidth * [PBGitDefaults commitMessageViewVerticalBodyLineLength];
        [[NSColor darkGrayColor] set];
        padding = [[self textContainer] lineFragmentPadding];
        line.origin.x = padding + lineWidth;
        line.origin.y = 0;
        line.size.width = 1;
        line.size.height = textViewHeight;
        NSRectFill(line);
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSURLPboardType] ) {
        NSString *droppedPath = [[NSURL URLFromPasteboard:pboard] path];
		NSString *baseDir = [self.repository.workingDirectory stringByAppendingString:@"/"];
		if (baseDir && [droppedPath hasPrefix:baseDir]) {
			NSString *relativePath = [droppedPath substringFromIndex:(baseDir.length)];
			if (relativePath.length) {
				[pboard clearContents];
				[pboard setString:relativePath forType:NSPasteboardTypeString];
			}

		}
    }
	return [super performDragOperation:sender];
}

@end
