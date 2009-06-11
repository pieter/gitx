@class PBGitRevPool;
@class PBGitCommit;

@protocol PBRevPoolDelegate
- (void)revPool:(PBGitRevPool *)pool encounteredCommit:(PBGitCommit *)commit;
@end
