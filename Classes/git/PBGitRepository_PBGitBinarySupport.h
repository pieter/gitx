//
//  PBGitRepository_PBGitBinarySupport.h
//  GitX
//
//  Created by Etienne on 22/02/2017.
//
//

#import <Foundation/Foundation.h>
#import "PBGitRepository.h"

@class PBTask;

NS_ASSUME_NONNULL_BEGIN

@interface PBGitRepository (PBGitBinarySupport)
- (PBTask *)taskWithArguments:(nullable NSArray *)arguments;
- (BOOL)launchTaskWithArguments:(nullable NSArray *)arguments error:(NSError **)error;
- (nullable NSString *)outputOfTaskWithArguments:(nullable NSArray *)arguments error:(NSError **)error;
@end

@interface PBGitRepository (PBGitBinarySupportDeprecated)
- (NSFileHandle*) handleForCommand:(NSString*) cmd GITX_DEPRECATED;
- (NSFileHandle*) handleForArguments:(NSArray*) args GITX_DEPRECATED;
- (NSFileHandle *) handleInWorkDirForArguments:(NSArray *)args GITX_DEPRECATED;
- (NSString*) outputForCommand:(NSString*) cmd GITX_DEPRECATED;
- (NSString *)outputForCommand:(NSString *)str retValue:(int *)ret GITX_DEPRECATED;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input retValue:(int *)ret GITX_DEPRECATED;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input byExtendingEnvironment:(NSDictionary *)dict retValue:(int *)ret GITX_DEPRECATED;


- (NSString*) outputForArguments:(NSArray*) args GITX_DEPRECATED;
- (NSString*) outputForArguments:(NSArray*) args retValue:(int *)ret GITX_DEPRECATED;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments GITX_DEPRECATED;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments retValue:(int *)ret GITX_DEPRECATED;
@end

NS_ASSUME_NONNULL_END
