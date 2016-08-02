//
//  PBOpenFiles.h
//  GitX
//
//  Created by Tommy Sparber on 02/08/16.
//  Based on code by Etienne
//

#import <Foundation/Foundation.h>

@interface PBOpenFiles : NSObject

+ (void)showInFinderAction:(id)sender with:(NSURL *)workingDirectoryURL;
+ (void)openFilesAction:(id)sender with:(NSURL *)workingDirectoryURL;

@end
