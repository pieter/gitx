//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRevList.h"
#import "PBGitRevSpecifier.h"
#import "PBGitConfig.h"
#import "PBGitRefish.h"

extern NSString* PBGitRepositoryErrorDomain;

@class PBGitWindowController;
@class PBGitCommit;

@interface PBGitRepository : NSDocument {
	PBGitRevList* revisionList;
	PBGitConfig *config;

	BOOL hasChanged;
	NSMutableArray *branches;
	PBGitRevSpecifier *currentBranch;
	NSMutableDictionary *refs;

	PBGitRevSpecifier *_headRef; // Caching
}

- (void) beginAddRemote:(NSString *)remoteName forURL:(NSString *)remoteURL;
- (void) beginFetchFromRemoteForRef:(PBGitRef *)ref;
- (void) beginPullFromRemote:(PBGitRef *)remoteRef forRef:(PBGitRef *)ref;
- (void) beginPushRef:(PBGitRef *)ref toRemote:(PBGitRef *)remoteRef;
- (BOOL) checkoutRefish:(id <PBGitRefish>)ref;
- (BOOL) checkoutFiles:(NSArray *)files fromRefish:(id <PBGitRefish>)ref;
- (BOOL) mergeWithRefish:(id <PBGitRefish>)ref;
- (BOOL) cherryPickRefish:(id <PBGitRefish>)ref;
- (BOOL) rebaseBranch:(id <PBGitRefish>)branch onRefish:(id <PBGitRefish>)upstream;
- (BOOL) createBranch:(NSString *)branchName atRefish:(id <PBGitRefish>)ref;
- (BOOL) createTag:(NSString *)tagName message:(NSString *)message atRefish:(id <PBGitRefish>)commitSHA;
- (BOOL) deleteRemote:(PBGitRef *)ref;
- (BOOL) deleteRef:(PBGitRef *)ref;

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;
- (NSFileHandle *) handleInWorkDirForArguments:(NSArray *)args;
- (NSString*) outputForCommand:(NSString*) cmd;
- (NSString *)outputForCommand:(NSString *)str retValue:(int *)ret;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input retValue:(int *)ret;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input byExtendingEnvironment:(NSDictionary *)dict retValue:(int *)ret;


- (NSString*) outputForArguments:(NSArray*) args;
- (NSString*) outputForArguments:(NSArray*) args retValue:(int *)ret;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments retValue:(int *)ret;
- (BOOL)executeHook:(NSString *)name output:(NSString **)output;
- (BOOL)executeHook:(NSString *)name withArgs:(NSArray*) arguments output:(NSString **)output;

- (NSString *)workingDirectory;
- (NSString *) projectName;
- (NSString *)gitIgnoreFilename;
- (BOOL)isBareRepository;

- (BOOL) reloadRefs;
- (void) addRef:(PBGitRef *)ref fromParameters:(NSArray *)params;
- (void) lazyReload;
- (PBGitRevSpecifier*) headRef;
- (NSString *) headSHA;
- (PBGitCommit *) headCommit;
- (NSString *) shaForRef:(PBGitRef *)ref;
- (PBGitCommit *) commitForRef:(PBGitRef *)ref;
- (PBGitCommit *) commitForSHA:(NSString *)sha;
- (BOOL) isSHAOnHeadBranch:(NSString *)testSHA;
- (BOOL) isRefOnHeadBranch:(PBGitRef *)testRef;
- (BOOL) checkRefFormat:(NSString *)refName;
- (BOOL) refExists:(PBGitRef *)ref;

- (NSArray *) remotes;
- (BOOL) hasRemotes;
- (PBGitRef *) remoteRefForBranch:(PBGitRef *)branch error:(NSError **)error;
- (NSString *) infoForRemote:(NSString *)remoteName;

- (void) readCurrentBranch;
- (PBGitRevSpecifier*) addBranch: (PBGitRevSpecifier*) rev;
- (BOOL)removeBranch:(PBGitRevSpecifier *)rev;

- (NSString*) parseSymbolicReference:(NSString*) ref;
- (NSString*) parseReference:(NSString*) ref;

+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
+ (NSURL*)baseDirForURL:(NSURL*)repositoryURL;

- (id) initWithURL: (NSURL*) path;
- (void) setup;

@property (assign) BOOL hasChanged;
@property (readonly) PBGitWindowController *windowController;
@property (readonly) PBGitConfig *config;
@property (retain) PBGitRevList* revisionList;
@property (assign) NSMutableArray* branches;
@property (assign) PBGitRevSpecifier *currentBranch;
@property (retain) NSMutableDictionary* refs;
@end
