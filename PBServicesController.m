//
//  PBServicesController.m
//  GitX
//
//  Created by Pieter de Bie on 10/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBServicesController.h"
#import "PBRepositoryDocumentController.h"
#import "PBGitRepository.h"

@implementation PBServicesController

- (NSString *)completeSHA1For:(NSString *)sha URL:(NSURL **)url
{
	NSArray *documents = [[NSApplication sharedApplication] orderedDocuments];
	for (PBGitRepository *repo in documents)
	{
		int ret = 1;
		NSString *s = [repo outputForArguments:[NSArray arrayWithObjects:@"log", @"-1", @"--pretty=format:%h (%s)", sha, nil] retValue:&ret];
		if (!ret) {
			*url = [NSURL URLWithString:[NSString stringWithFormat:@"http://github.com/pieter/gitx/commit/%@", [s substringToIndex:[s rangeOfString:@" "].location]]];
			return s;
		}
	}
	return @"Could not find SHA";
}

-(NSString *)runNameRevFor:(NSString *)s
{
	NSArray *repositories = [[NSApplication sharedApplication] orderedDocuments];
	if ([repositories count] == 0)
		return s;
	PBGitRepository *repo = [repositories objectAtIndex:0];
	int ret = 1;
	NSString *returnString = [repo outputForArguments:[NSArray arrayWithObjects:@"name-rev", @"--stdin", nil] inputString:s retValue:&ret];
	if (ret)
		return s;
	return returnString;
}

-(void)completeSha:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
	NSArray *types = [pboard types];
	if (![types containsObject:NSStringPboardType])
	{
		*error = @"Could not get data";
		return;
	}

	NSString *s = [pboard stringForType:NSStringPboardType];
	NSURL *url = nil;
	if ([s rangeOfString:@" "].location == NSNotFound)
		s = [self completeSHA1For:s URL:&url];
	else
		s = [self runNameRevFor:s];

	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:s];
	if (url) {
		[as beginEditing];
		[as addAttribute:NSLinkAttributeName value:url range:NSMakeRange(0, [as length])];
		[as endEditing];
	}
	NSLog(@"Returning: %@", as);
	[pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFDPboardType, NSHTMLPboardType, nil] owner:nil];
	NSString *html = [NSString stringWithFormat:@"<a href='%@'>%@</a>", url, s];
	[pboard setData:[html dataUsingEncoding:NSUTF8StringEncoding] forType:NSHTMLPboardType];
	[pboard setData:[as RTFDFromRange:NSMakeRange(0, [as length]) documentAttributes:nil] forType:NSRTFDPboardType];
	[pboard setString:s forType:NSStringPboardType];
}
@end
