//
//  ObjectiveGit+PBCategories.h
//  GitX
//
//  Created by Etienne on 28/02/2017.
//
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTCommit (PBCategories)
- (NSArray <GTOID *> *)parentOIDs;
@end
