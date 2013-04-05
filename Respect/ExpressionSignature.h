// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// Parses "expression signature" strings to regex for matching

#import <Foundation/Foundation.h>
#import "PeekableEnumerator.h"

extern NSString * const SignatureMatcherErrorDomain;

@protocol ExpressionSignature <NSObject>
+ (id<ExpressionSignature>)parseTokens:(PeekableEnumerator *)tokens
                                 error:(NSError **)error;
- (NSString *)toPattern;
@end

@interface ExpressionSignature : NSObject<ExpressionSignature>
+ (NSError *)errorWithDescription:(NSString *)description;
+ (NSError *)errorWithDescriptionFormat:(NSString *)descriptionFormat, ... NS_FORMAT_FUNCTION(1, 2);
+ (ExpressionSignature *)signatureFromString:(NSString *)signature
                                       error:(NSError **)error;
+ (NSRegularExpression *)stringToRegEx:(NSString *)signature
                                 error:(NSError **)error;
@end
