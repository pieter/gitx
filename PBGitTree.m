//
//  PBGitTree.m
//  GitTest
//
//  Created by Pieter de Bie on 15-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitTree.h"
#import "PBGitCommit.h"
#import "NSFileHandleExt.h"
#import "PBEasyPipe.h"
#import "PBEasyFS.h"

@implementation PBGitTree

@synthesize sha, path, repository, leaf, parent, iconImage, absolutePath;

+ (PBGitTree*) rootForCommit:(id) commit
{
	PBGitCommit* c = commit;
	PBGitTree* tree = [[self alloc] init];
	tree.parent = nil;
	tree.leaf = NO;
	tree.sha = [c realSha];
	tree.repository = c.repository;
	tree.path = @"";
	return tree;
}

+ (PBGitTree*) treeForTree: (PBGitTree*) prev andPath: (NSString*) path;
{
	PBGitTree* tree = [[self alloc] init];
	tree.parent = prev;
	tree.sha = prev.sha;
	tree.repository = prev.repository;
	tree.path = path;
	return tree;
}

- (id) init
{
    if (self = [super init]) {
        children = nil;
        localFileName = nil;
        leaf = YES;
        absolutePath = [PBGitRepository basePath];
    }
	return self;
}

- (NSString*) refSpec
{
	return [NSString stringWithFormat:@"%@:%@", self.sha, self.fullPath];
}

- (BOOL) isLocallyCached
{
	NSFileManager* fs = [NSFileManager defaultManager];
	if (localFileName && [fs fileExistsAtPath:localFileName])
	{
		NSDate* mtime = [[fs attributesOfItemAtPath:localFileName error: nil] objectForKey:NSFileModificationDate];
		if ([mtime compare:localMtime] == 0)
			return YES;
	}
	return NO;
}

- (BOOL)hasBinaryHeader:(NSString*)contents
{
	if(!contents)
		return NO;

	return [contents rangeOfString:@"\0" options:0 range:NSMakeRange(0, ([contents length] >= 8000) ? 7999 : [contents length])].location != NSNotFound;
}

- (BOOL)hasBinaryAttributes
{
	// First ask git check-attr if the file has a binary attribute custom set
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"check-attr", @"binary", [self fullPath], nil]];
	NSData *data = [handle readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];

	if (!string)
		return NO;
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	if ([string hasSuffix:@"binary: set"])
		return YES;

	if ([string hasSuffix:@"binary: unset"])
		return NO;

	// Binary state unknown, do a check on common filename-extensions
	for (NSString *extension in [NSArray arrayWithObjects:@".pdf", @".jpg", @".jpeg", @".png", @".bmp", @".gif", @".o", nil]) {
		if ([[self fullPath] hasSuffix:extension])
			return YES;
	}

	return NO;
}

- (NSString*) contents
{
	if (!leaf)
		return [NSString stringWithFormat:@"This is a tree with path %@", [self fullPath]];
	
	if ([self isLocallyCached]) {
		NSData *data = [NSData dataWithContentsOfFile:localFileName];
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (!string)
			string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
		return string;
	}
	
	//return [repository outputForArguments:[NSArray arrayWithObjects:@"show", [self refSpec], nil]];
	return [repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"blame", self.path, nil]];
}

// XXX: create img tag for images.
- (NSString*) contents:(NSInteger)option
{
	NSString* contents;

	if (!leaf)
		return [NSString stringWithFormat:@"This is a tree with path %@", [self fullPath]];
	
	if ([self hasBinaryAttributes])
		return [NSString stringWithFormat:@"%@ appears to be a binary file of %d bytes", [self fullPath], [self fileSize]];
	
	if ([self fileSize] > 52428800) // ~50MB
		return [NSString stringWithFormat:@"%@ is too big to be displayed (%d bytes)", [self fullPath], [self fileSize]];
	
	if ([self hasBinaryHeader:contents])
		return [NSString stringWithFormat:@"%@ appears to be a binary file of %d bytes", [self fullPath], [self fileSize]];
	
	return contents;
}

- (long long)fileSize
{
	if (_fileSize)
		return _fileSize;

	NSFileHandle *handle = [repository handleForArguments:[NSArray arrayWithObjects:@"cat-file", @"-s", [self refSpec], nil]];
	NSString *sizeString = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSISOLatin1StringEncoding];

	if (!sizeString)
		_fileSize = -1;
	else
		_fileSize = [sizeString longLongValue];

	return _fileSize;
}

- (NSString *)textContents
{
	if (!leaf)
		return [NSString stringWithFormat:@"This is a tree with path %@", [self fullPath]];

	if ([self hasBinaryAttributes])
		return [NSString stringWithFormat:@"%@ appears to be a binary file of %d bytes", [self fullPath], [self fileSize]];

	if ([self fileSize] > 52428800) // ~50MB
		return [NSString stringWithFormat:@"%@ is too big to be displayed (%d bytes)", [self fullPath], [self fileSize]];

	NSString* contents = [self contents];

	if ([self hasBinaryHeader:contents])
		return [NSString stringWithFormat:@"%@ appears to be a binary file of %d bytes", [self fullPath], [self fileSize]];

	return contents;
}

- (void) saveToFolder: (NSString *) dir
{
	NSString* newName = [dir stringByAppendingPathComponent:path];

	if (leaf) {
		NSFileHandle* handle = [repository handleForArguments:[NSArray arrayWithObjects:@"show", [self refSpec], nil]];
		NSData* data = [handle readDataToEndOfFile];
		[data writeToFile:newName atomically:YES];
	} else { // Directory
		[[NSFileManager defaultManager] createDirectoryAtPath:newName withIntermediateDirectories:YES attributes:nil error:nil];
		for (PBGitTree* child in [self children])
			[child saveToFolder: newName];
	}
}

- (NSString*) tmpDirWithContents
{
	if (leaf)
		return nil;

	if (!localFileName)
		localFileName = [PBEasyFS tmpDirWithPrefix: path];

	for (PBGitTree* child in [self children]) {
		[child saveToFolder: localFileName];
	}
	
	return localFileName;
}

	

- (NSString*) tmpFileNameForContents
{
	if (!leaf)
		return [self tmpDirWithContents];
	
	if ([self isLocallyCached])
		return localFileName;
	
	if (!localFileName)
		localFileName = [[PBEasyFS tmpDirWithPrefix: sha] stringByAppendingPathComponent:path];
	
	NSFileHandle* handle = [repository handleForArguments:[NSArray arrayWithObjects:@"show", [self refSpec], nil]];
	NSData* data = [handle readDataToEndOfFile];
	[data writeToFile:localFileName atomically:YES];
	
	NSFileManager* fs = [NSFileManager defaultManager];
	localMtime = [[fs attributesOfItemAtPath:localFileName error: nil] objectForKey:NSFileModificationDate];

	return localFileName;
}

- (NSArray*) children
{
	if (children != nil)
		return children;
	
	NSString* ref = [self refSpec];

	NSFileHandle* handle = [repository handleForArguments:[NSArray arrayWithObjects:@"show",@"--pretty=format:",@"--name-only", self.sha, nil]];
	//[handle readLine];
	[handle readLine];
	
	NSMutableArray* c = [NSMutableArray array];
	
	NSString* p = [handle readLine];
	while ([p length] > 0) {
		NSLog(@"-->%@",p);
		if ([p isEqualToString:@"\r"])
			break;

		BOOL isLeaf = ([p characterAtIndex:p.length - 1] != '/');
		if (!isLeaf)
			p = [p substringToIndex:[p length]-1];

		PBGitTree* child = [PBGitTree treeForTree:self andPath:p];
		child.leaf = isLeaf;
		[c addObject: child];
		
		p = [handle readLine];
	}
	children = c;
	return c;
}

- (NSString*) fullPath
{
	if (!parent)
		return @"";
	
	if ([[parent fullPath] isEqualToString:@""])
		return self.path;
	
	return [[parent fullPath] stringByAppendingPathComponent: self.path];
}

// !!! Andre Berg 20100324: finalize seldomly causes the following error message:
// malloc: resurrection error for object 0x12b1110 while assigning NSFilesystemItemRemoveOperation._removePath[32](0x12a0170)[16] = NSPathStore2[240](0x12b1110)
// garbage pointer stored into reachable memory, break on auto_zone_resurrection_error to debug
// objc[40604]: **resurrected** object 0x12b1110 of class NSPathStore2 being finalized
// - (void) finalize
// {
// 	if (localFileName)
// 		[[NSFileManager defaultManager] removeItemAtPath:localFileName error:nil];
// 	[super finalize];
// }

+(NSString *)parseBlame:(NSString *)string
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
				NSArray *h=[line componentsSeparatedByString:@" "];
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
@end
