//
//  FileViewerController.m
//  GitX
//
//  Created by German Laullon on 11/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FileViewerController.h"
#import "PBGitHistoryController.h"
#import "PBGitDefaults.h"

#define GROUP_LABEL				@"Label"			// string
#define GROUP_SEPARATOR			@"HasSeparator"		// BOOL as NSNumber
#define GROUP_SELECTION_MODE	@"SelectionMode"	// MGScopeBarGroupSelectionMode (int) as NSNumber
#define GROUP_ITEMS				@"Items"			// array of dictionaries, each containing the following keys:
#define ITEM_IDENTIFIER			@"Identifier"		// string
#define ITEM_NAME				@"Name"				// string

@implementation FileViewerController


#pragma mark Setup and teardown

- (id)initWithRepository:(PBGitRepository *)theRepository andController:(id)theController;
{
	repository=theRepository;
	controller=theController;
	return [self initWithNibName:@"FileViewer" bundle:[NSBundle mainBundle]];	
}

- (void)awakeFromNib
{
	self.groups = [NSMutableArray arrayWithCapacity:0];
	scopeBar.delegate = self;
	NSArray *items = [NSArray arrayWithObjects:
					  [NSDictionary dictionaryWithObjectsAndKeys:
					   (commit)?@"commit":@"diff", ITEM_IDENTIFIER, 
					   @"Diff", ITEM_NAME, 
					   nil], 
					  [NSDictionary dictionaryWithObjectsAndKeys:
					   @"source", ITEM_IDENTIFIER, 
					   @"Source", ITEM_NAME, 
					   nil], 
					  [NSDictionary dictionaryWithObjectsAndKeys:
					   @"blame", ITEM_IDENTIFIER, 
					   @"Blame", ITEM_NAME, 
					   nil], 
					  [NSDictionary dictionaryWithObjectsAndKeys:
					   @"log", ITEM_IDENTIFIER, 
					   @"History", ITEM_NAME, 
					   nil], 
					  nil];
	[self.groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithBool:NO], GROUP_SEPARATOR, 
							[NSNumber numberWithInt:MGRadioSelectionMode], GROUP_SELECTION_MODE, // single selection group.
							items, GROUP_ITEMS, 
							nil]];
	[scopeBar reloadData];
	[webViewFileViwer setUIDelegate:self];
	[webViewFileViwer setFrameLoadDelegate:self];
	[webViewFileViwer setResourceLoadDelegate:self];}


- (void)dealloc
{
	self.groups = nil;
	[super dealloc];
}


#pragma mark JavaScript log.js methods

- (void) selectCommit:(NSString*)c
{
	NSLog(@"[FileViewerController controller:%@]",controller);
	if([(PBGitHistoryController *)controller selectCommit:sha])
		NSLog(@"---");
	NSLog(@"[FileViewerController selectCommit:%@]",c);
}


#pragma mark MGScopeBarDelegate methods


- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar
{
	return [self.groups count];
}


- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(int)groupNumber
{
	return [[self.groups objectAtIndex:groupNumber] valueForKeyPath:[NSString stringWithFormat:@"%@.%@", GROUP_ITEMS, ITEM_IDENTIFIER]];
}


- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber
{
	return [[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_LABEL]; // might be nil, which is fine (nil means no label).
}


- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(NSString *)identifier inGroup:(int)groupNumber
{
	NSArray *items = [[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_ITEMS];
	if (items) {
		for (NSDictionary *item in items) {
			if ([[item objectForKey:ITEM_IDENTIFIER] isEqualToString:identifier]) {
				return [item objectForKey:ITEM_NAME];
				break;
			}
		}
	}
	return nil;
}


- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(int)groupNumber
{
	return [[[self.groups objectAtIndex:groupNumber] objectForKey:GROUP_SELECTION_MODE] intValue];
}

- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected forItem:(NSString *)identifier inGroup:(int)groupNumber
{
	NSString *path = [NSString stringWithFormat:@"html/views/%@", identifier];
	NSString *html = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:path];
	NSLog(@"[FileViewerController scopeBar:selectedStateChanged] -> file: '%@' (%@)",html,identifier);
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:html]];
	[[webViewFileViwer mainFrame] loadRequest:request];	
}

- (void)showFile:(NSString *)f sha:(NSString *)s{
	file=f;
	sha=s;
	NSString *show=[[[scopeBar selectedItems] objectAtIndex:0] objectAtIndex:0];
	NSLog(@"[showFile:sha] showFile:%@ sha:%@ (show=%@)",file,sha,show);
	[self scopeBar:scopeBar selectedStateChanged:true forItem:show inGroup:0];
}

# pragma mark WebKitDelegate methods

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
    NSLog(@"[Alert] message = %@",message);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    NSLog(@"[%@ %s]: self = %@ (%i)", [self class], _cmd, self,[self respondsToSelector:sel]);
    return NO;
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	id script = [sender windowScriptObject];
	NSLog(@"Controller: %@", controller);
	[script setValue:controller forKey:@"Controller"];
	[script setValue:[PBGitDefaults alloc] forKey:@"Config"];
}

- (void)webView:(WebView *)webView addMessageToConsole:(NSDictionary *)dictionary
{
	NSLog(@"Error from webkit: %@", dictionary);
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSString *show=[[[scopeBar selectedItems] objectAtIndex:0] objectAtIndex:0];
	
	NSString *path = [NSString stringWithFormat:@"html/views/%@", show];
	NSString *formatFile = [[NSBundle mainBundle] pathForResource:@"format" ofType:@"html" inDirectory:path];
	//NSString *testFile = [NSString stringWithFormat:@"%@/test.html",NSHomeDirectory()];
	NSString *format;
	if(formatFile!=nil)
		format=[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:formatFile] encoding:NSUTF8StringEncoding error:nil];
	
	NSString *txt;
	if(show==@"source")
		txt=[repository outputForArguments:[NSArray arrayWithObjects:@"show", [self refSpec], nil]];
	else if(show==@"blame")
		txt=[self parseBlame:[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"blame", @"-p", file, sha, nil]]];
	else if(show==@"diff"){
		NSString *diff_p=[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"show", @"--pretty=format:", sha, file, nil]];
		NSString *diff_l=[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", file, nil]];
		txt=[NSString stringWithFormat:@"%@\n%@",diff_p,diff_l];
	}
	else if(show==@"commit")
		txt=[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", (sha!=nil)?sha:file, (sha!=nil)?file:nil, nil]];
	else if(show==@"log")
		txt=[self parseLog:[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"log", [NSString stringWithFormat:@"--pretty=format:%@",format], @"--", file, nil]]];
	else
		return; // XXXX controlar mejor.
	
	NSLog(@"didFinishLoadForFrame -> txt: '%@'",([txt length]>180)?[txt substringToIndex:180]:txt);
	
	id script = [webViewFileViwer windowScriptObject];
	[script callWebScriptMethod:@"showFile"
				  withArguments:[NSArray arrayWithObjects:txt, nil]];
	
	//[[[[[sender mainFrame] DOMDocument] documentElement] outerHTML] writeToFile:testFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSString*)refSpec
{
	return [NSString stringWithFormat:@"%@:%@", (sha!=nil)?sha:@"HEAD", file];
}


-(NSString *)parseLog:(NSString *)string
{
	return string;
}

-(NSString *)parseBlame:(NSString *)string
{
	string=[string stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	string=[string stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSString *line;
	NSMutableDictionary *headers=[NSMutableDictionary dictionary];
	NSMutableString *res=[NSMutableString string];
	
	[res appendString:@"<table class='blocks'>\n"];
	int i=0;
	while(i<[lines count]){
		line=[lines objectAtIndex:i];
		NSArray *header=[line componentsSeparatedByString:@" "];
		if([header count]==4){
			int nLines=[(NSString *)[header objectAtIndex:3] intValue];
			[res appendFormat:@"<tr class='block l%d'>\n",nLines];
			line=[lines objectAtIndex:++i];
			if([[[line componentsSeparatedByString:@" "] objectAtIndex:0] isEqual:@"author"]){
				NSString *author=line;
				NSString *summary=nil;
				while(summary==nil){
					line=[lines objectAtIndex:i++];
					if([[[line componentsSeparatedByString:@" "] objectAtIndex:0] isEqual:@"summary"]){
						summary=line;
					}
				}
				NSString *block=[NSString stringWithFormat:@"<td><p class='author'>%@</p><p class='summary'>%@</p></td>\n<td>\n",author,summary];
				[headers setObject:block forKey:[header objectAtIndex:0]];
			}
			[res appendString:[headers objectForKey:[header objectAtIndex:0]]];
			
			NSMutableString *code=[NSMutableString string];
			do{
				line=[lines objectAtIndex:i++];
			}while([line characterAtIndex:0]!='\t');
			line=[line stringByReplacingOccurrencesOfString:@"\t" withString:@"&nbsp;&nbsp;&nbsp;&nbsp;"];
			[code appendString:line];
			[code appendString:@"\n"];
			
			int n;
			for(n=1;n<nLines;n++){
				line=[lines objectAtIndex:i++];
				do{
					line=[lines objectAtIndex:i++];
				}while([line characterAtIndex:0]!='\t');
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

#pragma mark Accessors and properties
/*
 
 - (IBAction)updateFileViwer:(id)sender
 {
 NSString *type
 int option=[displayControl selectedSegment];
 if(option==0)
 type=@"source";
 else if(option==1)
 type=@"blame";
 else if(option==2)
 type=@"diff";
 
 }
 
 
 - (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
 {
 NSString *messageString = [error localizedDescription];
 NSString *moreString = [error localizedFailureReason] ?
 [error localizedFailureReason] :
 NSLocalizedString(@"Try typing the URL again.", nil);
 messageString = [NSString stringWithFormat:@"%@. %@", messageString, moreString];
 NSLog(@"ERROR!!!! - %@",messageString);
 }
 
 /*
 
 NSArray *objects = [treeController selectedObjects];
 NSArray *content = [treeController content];
 
 if ([objects count] && [content count]) {
 PBGitTree *treeItem = [objects objectAtIndex:0];
 currentFileBrowserSelectionPath = [treeItem.fullPath componentsSeparatedByString:@"/"];
 
 NSString *txt=[treeItem contents:[displayControl selectedSegment]];
 
 */ 
@synthesize groups;
@synthesize commit;

@end
