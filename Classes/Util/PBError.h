//
//  PBError.h
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const PBGitXErrorDomain;

@interface NSError (PBError)
+ (NSError *)pb_errorWithDescription:(NSString *)description failureReason:(NSString *)failureReason;
+ (NSError *)pb_errorWithDescription:(NSString *)description failureReason:(NSString *)failureReason userInfo:(nullable NSDictionary *)userInfo;
+ (NSError *)pb_errorWithDescription:(NSString *)description failureReason:(NSString *)failureReason underlyingError:(nullable NSError *)underError;
+ (NSError *)pb_errorWithDescription:(NSString *)description failureReason:(NSString *)failureReason underlyingError:(nullable NSError *)underError userInfo:(nullable NSDictionary *)userInfo;
@end

BOOL PBReturnError(NSError **error, NSString *description, NSString *failureReason);
BOOL PBReturnErrorWithUserInfo(NSError **error, NSString *description, NSString *failureReason, NSDictionary * _Nullable userInfo);
BOOL PBReturnErrorWithBuilder(NSError **error, NSError * (^errorBuilder)(void));

NS_ASSUME_NONNULL_END
