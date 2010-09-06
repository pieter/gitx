//
//  PBGitDefaults.h
//  GitX
//
//  Created by Jeff Mesnil on 19/10/08.
//  Copyright 2008 Jeff Mesnil (http://jmesnil.net/). All rights reserved.
//

@interface PBGitDefaults : NSObject
{

}

+ (int) commitMessageViewVerticalLineLength;
+ (BOOL) commitMessageViewHasVerticalLine;
+ (BOOL) isGistEnabled;
+ (BOOL) isGravatarEnabled;
+ (BOOL) confirmPublicGists;
+ (BOOL) isGistPublic;
+ (BOOL)showWhitespaceDifferences;
+ (BOOL)openCurDirOnLaunch;
+ (BOOL)showOpenPanelOnLaunch;
+ (BOOL) shouldCheckoutBranch;
+ (void) setShouldCheckoutBranch:(BOOL)shouldCheckout;
+ (NSString *) recentCloneDestination;
+ (void) setRecentCloneDestination:(NSString *)path;
+ (BOOL) suppressAcceptDropRef;
+ (void) setSuppressAcceptDropRef:(BOOL)suppress;
+ (BOOL) showStageView;
+ (void) setShowStageView:(BOOL)suppress;
+ (BOOL) openPreviousDocumentsOnLaunch;
+ (void) setPreviousDocumentPaths:(NSArray *)documentPaths;
+ (NSArray *) previousDocumentPaths;
+ (void) removePreviousDocumentPaths;
+ (NSInteger) branchFilter;
+ (void) setBranchFilter:(NSInteger)state;
+ (NSInteger)historySearchMode;
+ (void)setHistorySearchMode:(NSInteger)mode;

@end
