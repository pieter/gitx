//
//  GLFileView.m
//  GitX
//
//  Created by German Laullon on 14/09/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GLFileView.h"
#import "PBGitTree.h"
#import "PBGitCommit.h"
#import "PBGitHistoryController.h"


#define GROUP_LABEL				@"Label"			// string
#define GROUP_SEPARATOR			@"HasSeparator"		// BOOL as NSNumber
#define GROUP_SELECTION_MODE	@"SelectionMode"	// MGScopeBarGroupSelectionMode (int) as NSNumber
#define GROUP_ITEMS				@"Items"			// array of dictionaries, each containing the following keys:
#define ITEM_IDENTIFIER			@"Identifier"		// string
#define ITEM_NAME				@"Name"				// string

#define GROUP_ID_FILEVIEW       @"fileview"
#define GROUP_ID_BLAME          @"blame"
#define GROUP_ID_LOG            @"log"

@interface GLFileView ()

- (void)saveSplitViewPosition;

@end


@implementation GLFileView

- (void) awakeFromNib
{
	startFile = GROUP_ID_FILEVIEW;
	//repository = historyController.repository;
	[super awakeFromNib];
	[historyController.treeController addObserver:self forKeyPath:@"selection" options:0 context:@"treeController"];
	
	[fileListSplitView setHidden:YES];
	[self performSelector:@selector(restoreSplitViewPositiion) withObject:nil afterDelay:0];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//NSLog(@"keyPath=%@ change=%@ context=%@ object=%@ \n %@",keyPath,change,context,object,[historyController.treeController selectedObjects]);
	[self showFile];
}

- (void) showFile
{
	NSArray *files=[historyController.treeController selectedObjects];
	if ([files count] > 0) {
		PBGitTree *file = [files objectAtIndex:0];

		NSString *fileTxt = @"";
		if([startFile isEqualToString:GROUP_ID_FILEVIEW])
			fileTxt = [self escapeHTML:[file textContents]];
		else if([startFile isEqualToString:GROUP_ID_BLAME])
			fileTxt = [self parseBlame:[file blame]];
		else if([startFile isEqualToString:GROUP_ID_LOG])
			fileTxt = [self htmlHistory:file];

		id script = self.view.windowScriptObject;
		NSString *filePath = [file fullPath];
        [script callWebScriptMethod:@"showFile" withArguments:[NSArray arrayWithObjects:fileTxt, filePath, nil]];
	}
	
#if 0
	NSString *dom=[[[[view mainFrame] DOMDocument] documentElement] outerHTML];
	NSString *tmpFile=@"~/tmp/test.html";
	[dom writeToFile:[tmpFile stringByExpandingTildeInPath] atomically:true encoding:NSUTF8StringEncoding error:nil];
#endif 
}

#pragma mark JavaScript log.js methods

- (void) selectCommit:(NSString*)c
{
	[historyController selectCommit: [GTOID oidWithSHA: c]];
}

- (void) didLoad
{
	[self showFile];
}

- (void)closeView
{
	[historyController.treeController removeObserver:self forKeyPath:@"selection"];
	[self saveSplitViewPosition];

	[super closeView];
}

- (NSString *) escapeHTML:(NSString *)txt
{
	CFStringRef escaped = CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)txt, NULL);
	return (__bridge_transfer NSString *)escaped;
}

- (NSString *) parseBlame:(NSString *)txt
{
	txt=[self escapeHTML:txt];
	
	NSArray *lines = [txt componentsSeparatedByString:@"\n"];
	NSString *line;
	NSMutableDictionary *headers=[NSMutableDictionary dictionary];
	NSMutableString *res=[NSMutableString string];
	
	[res appendString:@"<table class='blocks'>\n"];
	int i=0;
	while(i<[lines count]){
		line=[lines objectAtIndex:i];
		NSArray *header=[line componentsSeparatedByString:@" "];
		if([header count]==4){
			NSString *commitID = (NSString *)[header objectAtIndex:0];
			int nLines=[(NSString *)[header objectAtIndex:3] intValue];
			[res appendFormat:@"<tr class='block l%d'>\n",nLines];
			line=[lines objectAtIndex:++i];
			if([[[line componentsSeparatedByString:@" "] objectAtIndex:0] isEqual:@"author"]){
				NSString *author=[line stringByReplacingOccurrencesOfString:@"author" withString:@""];
				NSString *summary=nil;
				while(summary==nil){
					line=[lines objectAtIndex:i++];
					if([[[line componentsSeparatedByString:@" "] objectAtIndex:0] isEqual:@"summary"]){
						summary=[line stringByReplacingOccurrencesOfString:@"summary" withString:@""];
					}
				}
				NSRange trunc_c={0,7};
				NSString *truncate_c=commitID;
				if([commitID length]>8){
					truncate_c=[commitID substringWithRange:trunc_c];
				}
				NSRange trunc={0,22};
				NSString *truncate_a=author;
				if([author length]>22){
					truncate_a=[author substringWithRange:trunc];
				}
				NSString *truncate_s=summary;
				if([summary length]>30){
					truncate_s=[summary substringWithRange:trunc];
				}
				NSString *block=[NSString stringWithFormat:@"<td><p class='author'><a class='commit-link' href='#' data-commit-id='%@'>%@</a> %@</p><p class='summary'>%@</p></td>\n<td>\n",commitID,truncate_c,truncate_a,truncate_s];
				[headers setObject:block forKey:[header objectAtIndex:0]];
			}
			[res appendString:[headers objectForKey:[header objectAtIndex:0]]];
			
			NSMutableString *code=[NSMutableString string];
			do{
				line=[lines objectAtIndex:i++];
			}while([line characterAtIndex:0]!='\t');
			line=[line substringFromIndex:1];
			line=[line stringByReplacingOccurrencesOfString:@"\t" withString:@"&nbsp;&nbsp;&nbsp;&nbsp;"];
			[code appendString:line];
			[code appendString:@"\n"];
			
			int n;
			for(n=1;n<nLines;n++){
				i++;
				do{
					line=[lines objectAtIndex:i++];
				}while([line characterAtIndex:0]!='\t');
				line=[line substringFromIndex:1];
				line=[line stringByReplacingOccurrencesOfString:@"\t" withString:@"&nbsp;&nbsp;&nbsp;&nbsp;"];
				[code appendString:line];
				[code appendString:@"\n"];
			}
			[res appendFormat:@"<pre class='first-line: %@;brush: objc'>%@</pre>",[header objectAtIndex:2],code];
			[res appendString:@"</td>\n"];
		}else{
			break;
		}
		[res appendString:@"</tr>\n"];
	}  
	[res appendString:@"</table>\n"];
	//NSLog(@"%@",res);
	
	return (NSString *)res;
}

- (NSString *) htmlHistory:(PBGitTree *)file
{
	// \0 can't be passed as a shell argument, so use a sufficiently long random seperator instead
	NSString *seperator = [[NSUUID UUID] UUIDString];
	NSString *commitTerminator = [[NSUUID UUID] UUIDString];
	NSString *logFormat = [[@"%h,%s,%aN,%ar,%H" stringByReplacingOccurrencesOfString:@"," withString:seperator] stringByAppendingString:commitTerminator];
	NSString *output = [file log:logFormat];
	NSArray<NSString *> *rawCommits = [output componentsSeparatedByString:commitTerminator];
	rawCommits = [rawCommits subarrayWithRange:(NSRange){0, rawCommits.count - 1}];

	NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];

	NSMutableString *html = [NSMutableString string];
	for (NSString *rawCommit in rawCommits) {
		NSArray<NSString *> *parts = [rawCommit componentsSeparatedByString:seperator];
		[html appendFormat:
		 @"<div id='%@' class='commit'>"
			 "<p class='title'>%@</p>"
			 "<table>"
				 "<tr><td>Author:</td><td>%@</td></tr>"
				 "<tr><td>Date:</td><td>%@</td></tr>"
		 		 "<tr><td>Commit:</td><td><a class='commit-link' href='#'>%@</a></td></tr>"
			 "</table>"
		 "</div>",
		 [self escapeHTML:[parts[0] stringByTrimmingCharactersInSet:whitespaceSet]], // trim leading newline from split
		 [self escapeHTML:parts[1]],
		 [self escapeHTML:parts[2]],
		 [self escapeHTML:parts[3]],
		 [self escapeHTML:parts[4]]];
	}
	return html;
}


#pragma mark NSSplitView delegate methods

#define kFileListSplitViewLeftMin 120
#define kFileListSplitViewRightMin 180
#define kHFileListSplitViewPositionDefault @"File List SplitView Position"

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return kFileListSplitViewLeftMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	return [splitView frame].size.width - [splitView dividerThickness] - kFileListSplitViewRightMin;
}

// while the user resizes the window keep the left (file list) view constant and just resize the right view
// unless the right view gets too small
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [splitView frame];

	CGFloat dividerThickness = [splitView dividerThickness];

	NSView *leftView = [[splitView subviews] objectAtIndex:0];
	NSRect leftFrame = [leftView frame];
	leftFrame.size.height = newFrame.size.height;

	if ((newFrame.size.width - leftFrame.size.width - dividerThickness) < kFileListSplitViewRightMin) {
		leftFrame.size.width = newFrame.size.width - kFileListSplitViewRightMin - dividerThickness;
	}

	NSView *rightView = [[splitView subviews] objectAtIndex:1];
	NSRect rightFrame = [rightView frame];
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;
	rightFrame.size.width = newFrame.size.width - rightFrame.origin.x;
	rightFrame.size.height = newFrame.size.height;

	[leftView setFrame:leftFrame];
	[rightView setFrame:rightFrame];
}

// NSSplitView does not save and restore the position of the SplitView correctly so do it manually
- (void)saveSplitViewPosition
{
	CGFloat position = [[[fileListSplitView subviews] objectAtIndex:0] frame].size.width;
	[[NSUserDefaults standardUserDefaults] setDouble:position forKey:kHFileListSplitViewPositionDefault];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

// make sure this happens after awakeFromNib
- (void)restoreSplitViewPositiion
{
	CGFloat position = [[NSUserDefaults standardUserDefaults] doubleForKey:kHFileListSplitViewPositionDefault];
	if (position < 1.0)
		position = 200;

	[fileListSplitView setPosition:position ofDividerAtIndex:0];
	[fileListSplitView setHidden:NO];
}



@synthesize groups;

@end
