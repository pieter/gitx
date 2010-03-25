//
//  PBGitCommit.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommit.h"
#import "PBGitDefaults.h"


NSString * const kGitXCommitType = @"commit";


@implementation PBGitCommit

@synthesize repository, subject, timestamp, author, parentShas, nParents, sign, lineInfo;

- (NSArray *) parents
{
	if (nParents == 0)
		return NULL;

	int i;
	NSMutableArray *p = [NSMutableArray arrayWithCapacity:nParents];
	for (i = 0; i < nParents; ++i)
	{
		char buff[GIT_OID_HEXSZ+1];
		char * s = git_oid_to_string(buff, GIT_OID_HEXSZ+1, parentShas + i);		
		[p addObject:[NSString stringWithUTF8String:s]];
	}
	return p;
}

- (NSDate *)date
{
	return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

-(NSString *)dateString {
    if ([PBGitDefaults showRelativeDates]) {
        // Code modified from Gilean ( http://stackoverflow.com/users/6305/gilean ).
        // Copied from stackoverflow's accepted answer for Objective C relative dates.
        // http://stackoverflow.com/questions/902950/iphone-convert-date-string-to-a-relative-time-stamp
        // Modified the seconds constants with compile time math to aid in ease of adjustment of "Majic" numbers.
        //
        NSDate *todayDate = [NSDate date];
        double ti = [self.date timeIntervalSinceDate:todayDate];
        ti = ti * -1;
        if(ti < 1) {
            return @"In the future!";
        } else      if ( ti < 60 ) {
            return @"less than a minute ago";
        } else if ( ti < (60 * 60) ) {
            int diff = round(ti / 60);
            if ( diff < 2 ) {
                return @"1 minute ago";
            } else {
                return [NSString stringWithFormat:@"%d minutes ago", diff];
            }
        } else if ( ti < ( 60 * 60 * 24 ) ) {
            int diff = round(ti / 60 / 60);
            if ( diff < 2 ) {
                return @"1 hour ago";
            } else {
                return[NSString stringWithFormat:@"%d hours ago", diff];
            }
        } else if ( ti < ( 60 * 60 * 24 * 7 ) ) {
            int diff = round(ti / 60 / 60 / 24);
            if ( diff < 2 ) {
                return @"1 day ago";
            } else {
                return[NSString stringWithFormat:@"%d days ago", diff];
            }
        } else if ( ti < ( 60 * 60 * 24 * 31.5 ) ) {
            int diff = round(ti / 60 / 60 / 24 / 7);
            if ( diff < 2 ) {
                return @"1 week ago";
            } else {
                return[NSString stringWithFormat:@"%d weeks ago", diff];
            }
        } else if ( ti < ( 60 * 60 * 24 * 365 ) ) {
            int diff = round(ti / 60 / 60 / 24 / 30);
            if ( diff < 2 ) {
                return @"1 month ago";
            } else {
                return[NSString stringWithFormat:@"%d months ago", diff];
            }
        } else {
            float diff = round(ti / 60 / 60 / 24 / 365 * 4) / 4.0;
            if ( diff < 1.25 ) {
                return @"1 year ago";
            } else {
                return[NSString stringWithFormat:@"%g years ago", diff];
            }
        }
    } else {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S" allowNaturalLanguage:NO];
        return [formatter stringFromDate: self.date];
    }
}

- (NSArray*) treeContents
{
	return self.tree.children;
}

- (git_oid *)sha
{
	return &sha;
}

+ commitWithRepository:(PBGitRepository*)repo andSha:(git_oid)newSha
{
	return [[[self alloc] initWithRepository:repo andSha:newSha] autorelease];
}

- initWithRepository:(PBGitRepository*) repo andSha:(git_oid)newSha
{
	details = nil;
	repository = repo;
	sha = newSha;
	return self;
}

- (NSString *)realSha
{
	if (!realSHA) {
		char buff[GIT_OID_HEXSZ+1];
		char * hex = git_oid_to_string(buff, GIT_OID_HEXSZ+1, &sha);		
		realSHA = [NSString stringWithUTF8String:hex];
	}

	return realSHA;
}

- (BOOL) isOnSameBranchAs:(PBGitCommit *)other
{
	if (!other)
		return NO;

	NSString *mySHA = [self realSha];
	NSString *otherSHA = [other realSha];

	if ([otherSHA isEqualToString:mySHA])
		return YES;

	return [repository isOnSameBranch:otherSHA asSHA:mySHA];
}

- (BOOL) isOnHeadBranch
{
	return [self isOnSameBranchAs:[repository headCommit]];
}

// FIXME: Remove this method once it's unused.
- (NSString*) details
{
	return @"";
}

- (NSString *) patch
{
	if (_patch != nil)
		return _patch;

	NSString *p = [repository outputForArguments:[NSArray arrayWithObjects:@"format-patch",  @"-1", @"--stdout", [self realSha], nil]];
	// Add a GitX identifier to the patch ;)
	_patch = [[p substringToIndex:[p length] -1] stringByAppendingString:@"+GitX"];
	return _patch;
}

- (PBGitTree*) tree
{
	return [PBGitTree rootForCommit: self];
}

- (void)addRef:(PBGitRef *)ref
{
	if (!self.refs)
		self.refs = [NSMutableArray arrayWithObject:ref];
	else
		[self.refs addObject:ref];
}

- (void)removeRef:(id)ref
{
	if (!self.refs)
		return;

	[self.refs removeObject:ref];
}

- (BOOL) hasRef:(PBGitRef *)ref
{
	if (!self.refs)
		return NO;

	for (PBGitRef *existingRef in self.refs)
		if ([existingRef isEqualToRef:ref])
			return YES;

	return NO;
}

- (NSMutableArray *)refs
{
	return [[repository refs] objectForKey:[self realSha]];
}

- (void) setRefs:(NSMutableArray *)refs
{
	[[repository refs] setObject:refs forKey:[self realSha]];
}

- (void)finalize
{
	free(parentShas);
	[super finalize];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}


#pragma mark <PBGitRefish>

- (NSString *) refishName
{
	return [self realSha];
}

- (NSString *) shortName
{
	return [[self realSha] substringToIndex:10];
}

- (NSString *) refishType
{
	return kGitXCommitType;
}

@end
