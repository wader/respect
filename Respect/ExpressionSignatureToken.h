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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ExpressionSignatureTokenType) {
    SIGNATURE_TOKEN_OPEN_BRACKET,
    SIGNATURE_TOKEN_CLOSE_BRACKET,
    SIGNATURE_TOKEN_OPEN_PARENTHESES,
    SIGNATURE_TOKEN_CLOSE_PARENTHESES,
    SIGNATURE_TOKEN_IDENT,
    SIGNATURE_TOKEN_AT,
    SIGNATURE_TOKEN_DOLLAR,
    SIGNATURE_TOKEN_COLON,
    SIGNATURE_TOKEN_COMMA,
    SIGNATURE_TOKEN_END,
    SIGNATURE_TOKEN_UNKNOWN
};

@interface ExpressionSignatureToken : NSObject
@property(nonatomic, assign, readwrite) NSRange range;
@property(nonatomic, copy, readwrite) NSString *string;
@property(nonatomic, assign, readwrite) ExpressionSignatureTokenType type;

+ (instancetype)tokenWithRange:(NSRange)range
                      inString:(NSString *)string
                          type:(ExpressionSignatureTokenType)type;
+ (ExpressionSignatureToken *)tokenizeString:(NSString *)string
                                   fromIndex:(NSUInteger)index;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRange:(NSRange)range
                     inString:(NSString *)string
                         type:(ExpressionSignatureTokenType)type NS_DESIGNATED_INITIALIZER;
@end
