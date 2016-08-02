//
//  PBOpenFiles.m
//  GitX
//
//  Created by Tommy Sparber on 02/08/16.
//  Based on code by Etienne
//

#import "PBOpenFiles.h"

@implementation PBOpenFiles

+ (NSArray *)selectedURLsFromSender:(id)sender with:(NSURL *)workingDirectoryURL {
	NSArray *selectedFiles = [sender representedObject];
	if ([selectedFiles count] == 0)
		return nil;

	NSMutableArray *URLs = [NSMutableArray array];
	for (id file in selectedFiles) {
		NSString *path = file;
		// Those can be PBChangedFiles sent by PBGitIndexController. Get their path.
		if ([file respondsToSelector:@selector(path)]) {
			path = [file path];
		}

		if (![path isKindOfClass:[NSString class]])
			continue;
		[URLs addObject:[workingDirectoryURL URLByAppendingPathComponent:path]];
	}

	return URLs;
}

+ (void)showInFinderAction:(id)sender with:(NSURL *)workingDirectoryURL {
	NSArray *URLs = [self selectedURLsFromSender:sender with:workingDirectoryURL];
	if ([URLs count] == 0)
		return;

	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
}

+ (void)openFilesAction:(id)sender with:(NSURL *)workingDirectoryURL {
	NSArray *URLs = [self selectedURLsFromSender:sender with:workingDirectoryURL];

	if ([URLs count] == 0)
		return;

	[[NSWorkspace sharedWorkspace] openURLs:URLs
					withAppBundleIdentifier:nil
									options:0
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:NULL];
}

@end
