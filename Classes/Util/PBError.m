//
//  PBError.m
//  GitX
//
//  Created by Andre Berg on 31.10.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "PBError.h"

NSString * const PBGitXErrorDomain      = @"PBGitXErrorDomain";

@implementation NSError (PBError)

+ (NSError *)pb_errorWithDescription:(NSString *)description failureReason:(NSString *)failureReason
{
	return [self pb_errorWithDescription:description failureReason:failureReason underlyingError:nil userInfo:nil];
}

+ (NSError *)pb_errorWithDescription:(NSString *)description failureReason:(NSString *)failureReason userInfo:(nullable NSDictionary *)userInfo
	NSParameterAssert(description != nil);
	NSParameterAssert(failureReason != nil);

	NSMutableDictionary *errorInfo = userInfo ? [userInfo mutableCopy] : [NSMutableDictionary dictionary];

	[errorInfo addEntriesFromDictionary:@{
										  NSLocalizedDescriptionKey: description,
										  NSLocalizedFailureReasonErrorKey: failureReason,
										  }];

	return [NSError errorWithDomain:PBGitXErrorDomain code:0 userInfo:userInfo];
}

@end
