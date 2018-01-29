//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBGitHistoryList;
@class PBGitRevSpecifier;
@protocol PBGitRefish;
@class PBGitRef;
@class PBGitStash;
@class PBGitRepositoryDocument;
@class GTRepository;
@class GTConfiguration;

extern NSString *PBGitRepositoryDocumentType;

typedef enum branchFilterTypes {
	kGitXAllBranchesFilter = 0,
	kGitXLocalRemoteBranchesFilter,
	kGitXSelectedBranchFilter
} PBGitXBranchFilterType;

@class PBGitWindowController;
@class PBGitCommit;
@class PBGitIndex;
@class GTOID;
@class PBGitRepositoryWatcher;
@class GTSubmodule;

@interface PBGitRepository : NSDocument

@property (nonatomic, weak) PBGitRepositoryDocument *document; // Backward-compatibility while PBGitRepository gets "modelized";

@property (nonatomic, assign) BOOL hasChanged;
@property (nonatomic, assign) NSInteger currentBranchFilter;

@property (readonly, strong) PBGitWindowController *windowController;
@property (readonly, getter = getIndexURL) NSURL* indexURL;

@property (nonatomic, strong) PBGitHistoryList *revisionList;
@property (nonatomic, readonly, strong) NSArray* stashes;
@property (nonatomic, readonly, strong) NSArray* branches;
@property (nonatomic, strong) NSMutableOrderedSet* branchesSet;
@property (nonatomic, strong) PBGitRevSpecifier* currentBranch;
@property (nonatomic, strong) NSMutableDictionary* refs;
@property (readonly, strong) GTRepository* gtRepo;
@property (nonatomic, readonly) BOOL isShallowRepository;

@property (nonatomic, strong) NSMutableArray<GTSubmodule *>* submodules;
@property (readonly, strong) PBGitIndex *index;

// Designated initializer
- (id)initWithURL:(NSURL *)repositoryURL error:(NSError **)error;

- (void) beginAddRemote:(NSString *)remoteName forURL:(NSString *)remoteURL;
- (void) beginFetchFromRemoteForRef:(PBGitRef *)ref;
- (void) beginPullFromRemote:(PBGitRef *)remoteRef forRef:(PBGitRef *)ref rebase:(BOOL)rebase;
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
- (BOOL) stashPop:(PBGitStash *)stash;
- (BOOL) stashApply:(PBGitStash *)stash;
- (BOOL) stashDrop:(PBGitStash *)stash;
- (BOOL) stashSave;
- (BOOL) stashSaveWithKeepIndex:(BOOL)keepIndex;

- (BOOL)ignoreFilePaths:(NSArray *)filePaths error:(NSError **)error;

- (BOOL)updateReference:(PBGitRef *)ref toPointAtCommit:(PBGitCommit *)newCommit;
- (NSString *)performDiff:(PBGitCommit *)startCommit against:(PBGitCommit *)diffCommit forFiles:(NSArray *)filePaths;

- (NSURL *) gitURL ;

- (BOOL)executeHook:(NSString *)name output:(NSString **)output GITX_DEPRECATED;
- (BOOL)executeHook:(NSString *)name withArgs:(NSArray*) arguments output:(NSString **)output GITX_DEPRECATED;

- (BOOL)executeHook:(NSString *)name error:(NSError **)error;
- (BOOL)executeHook:(NSString *)name arguments:(NSArray *)arguments error:(NSError **)error;
- (BOOL)executeHook:(NSString *)name arguments:(NSArray *)arguments output:(NSString **)outputPtr error:(NSError **)error;

- (NSString *)workingDirectory;
- (NSURL *)workingDirectoryURL;
- (NSString *)projectName;

- (NSString *)gitIgnoreFilename;
- (BOOL)isBareRepository;

- (BOOL)hasSVNRemote;

- (void) reloadRefs;
- (void) lazyReload;
- (PBGitRevSpecifier*)headRef;
- (GTOID *)headOID;
- (PBGitCommit *)headCommit;
- (GTOID *)OIDForRef:(PBGitRef *)ref;
- (PBGitCommit *)commitForRef:(PBGitRef *)ref;
- (PBGitCommit *)commitForOID:(GTOID *)sha;
- (BOOL)isOIDOnSameBranch:(GTOID *)baseOID asOID:(GTOID *)testOID;
- (BOOL)isOIDOnHeadBranch:(GTOID *)testOID;
- (PBGitStash *)stashForRef:(PBGitRef *)ref;
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

- (GTReference*) parseSymbolicReference:(NSString*) ref;
- (BOOL) revisionExists:(NSString*) spec;

- (void) forceUpdateRevisions;
- (NSURL*) getIndexURL;

- (GTSubmodule *)submoduleAtPath:(NSString *)path error:(NSError **)error;

@end
