//
//  PBRepositoryDocumentController.h
//  GitX
//
//  Created by Ciarán Walsh on 15/08/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PBRepositoryDocumentController : NSDocumentController
{

}

- (id) openRepositoryAtLocation:(NSURL*) url RevParseArgs:(NSArray*)args;
@end
