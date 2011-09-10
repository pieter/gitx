//
//  PBEasyPipe.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DNU __attribute__ ((deprecated))

@interface PBEasyPipe: NSObject {

}

+ (NSTask *) taskForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir DNU;

+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args DNU;
+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args inDir: (NSString*) dir DNU;

+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args DNU;
+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args inDir: (NSString*) dir DNU;
+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
				      retValue:(int *)      ret DNU;
+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
				   inputString:(NSString *)input
				      retValue:(int *)      ret DNU;
+ (NSString*) outputForCommand:(NSString *) cmd
					  withArgs:(NSArray *)  args
						 inDir:(NSString *) dir
		byExtendingEnvironment:(NSDictionary *)dict
				   inputString:(NSString *)input
				      retValue:(int *)      ret DNU;


@end
