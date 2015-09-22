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

#import "ExpressionSignatureArgument.h"
#import "ExpressionSignatureToken.h"

@implementation ExpressionSignatureArgument

+ (id<ExpressionSignature>)parseTokens:(PeekableEnumerator *)tokens
                                 error:(NSError **)error {
    ExpressionSignatureToken *token = [tokens nextObject];
    if (token.type == SIGNATURE_TOKEN_AT) {
        return [[ExpressionSignatureArgument alloc]
                initWithType:SIGNATURE_ARGUMENT_STRING];
    } else if (token.type == SIGNATURE_TOKEN_DOLLAR) {
        return [[ExpressionSignatureArgument alloc]
                initWithType:SIGNATURE_ARGUMENT_NAME];
    }

    return nil;
}

- (id)initWithType:(ExpressionSignatureArgumentType)type {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.type = type;

    return self;
}

- (NSString *)toPattern {
    if (self.type == SIGNATURE_ARGUMENT_STRING) {
        // capture content of @"" or "" allowing escape
        return @"@?\"((?:\\\\.|[^\"])*)\"";
    } else if (self.type == SIGNATURE_ARGUMENT_NAME) {
        // capture identifier
        // TODO: allow ident->ident, ident.ident etc?
        return @"([\\w_][\\w\\d_]*)";
    } else if (self.type == SIGNATURE_ARGUMENT_SKIP) {
        // skip one or more characters
        return @".+";
    } else {
        NSAssert(0, @"");
    }

    return nil;
}

- (NSString *)description {
    if (self.type == SIGNATURE_ARGUMENT_STRING) {
        return @"@";
    } else if (self.type == SIGNATURE_ARGUMENT_NAME) {
        return @"$";
    } else if (self.type == SIGNATURE_ARGUMENT_SKIP) {
        return @"";
    }

    return nil;
}

@end
