//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitHistoryList.h"
#import "PBGitRevSpecifier.h"
#import "PBGitConfig.h"
#import "PBGitRefish.h"

extern NSString* PBGitRepositoryErrorDomain;
typedef enum branchFilterTypes {
	kGitXAllBranchesFilter = 0,
	kGitXLocalRemoteBranchesFilter,
	kGitXSelectedBranchFilter
} PBGitXBranchFilterType;

static NSString * PBStringFromBranchFilterType(PBGitXBranchFilterType type) {
    switch (type) {
        case kGitXAllBranchesFilter:
            return @"All";
            break;
        case kGitXLocalRemoteBranchesFilter:
            return @"Local";
            break;
        case kGitXSelectedBranchFilter:
            return @"Selected";
            break;
        default:
            break;
    }
    return @"Not a branch filter type";
}

@class PBGitWindowController;
@class PBGitCommit;
@class PBGitSHA;

@interface PBGitRepository : NSDocument {
	PBGitHistoryList* revisionList;
	PBGitConfig *config;

	BOOL hasChanged;
	NSMutableArray *branches;
	PBGitRevSpecifier *currentBranch;
	NSInteger currentBranchFilter;
	NSMutableDictionary *refs;

	PBGitRevSpecifier *_headRef; // Caching
	PBGitSHA* _headSha;
}

- (void) cloneRepositoryToPath:(NSString *)path bare:(BOOL)isBare;
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

- (void) reloadRefs;
- (void) addRef:(PBGitRef *)ref fromParameters:(NSArray *)params;
- (void) lazyReload;
- (PBGitRevSpecifier*)headRef;
- (PBGitSHA *)headSHA;
- (PBGitCommit *)headCommit;
- (PBGitSHA *)shaForRef:(PBGitRef *)ref;
- (PBGitCommit *)commitForRef:(PBGitRef *)ref;
- (PBGitCommit *)commitForSHA:(PBGitSHA *)sha;
- (BOOL)isOnSameBranch:(PBGitSHA *)baseSHA asSHA:(PBGitSHA *)testSHA;
- (BOOL)isSHAOnHeadBranch:(PBGitSHA *)testSHA;
- (BOOL)isRefOnHeadBranch:(PBGitRef *)testRef;
- (BOOL)checkRefFormat:(NSString *)refName;
- (BOOL)refExists:(PBGitRef *)ref;
- (PBGitRef *)refForName:(NSString *)name;

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
- (void) forceUpdateRevisions;

// for the scripting bridge
- (void)findInModeScriptCommand:(NSScriptCommand *)command;


@property (assign) BOOL hasChanged;
@property (readonly) PBGitWindowController *windowController;
@property (readonly) PBGitConfig *config;
@property (retain) PBGitHistoryList *revisionList;
@property (assign) NSMutableArray* branches;
@property (assign) PBGitRevSpecifier *currentBranch;
@property (assign) NSInteger currentBranchFilter;
@property (retain) NSMutableDictionary* refs;
@end
