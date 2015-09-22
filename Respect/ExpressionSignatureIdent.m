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

#import "ExpressionSignatureIdent.h"
#import "ExpressionSignatureToken.h"

@implementation ExpressionSignatureIdent

+ (id<ExpressionSignature>)parseTokens:(PeekableEnumerator *)tokens
                                 error:(NSError **)error {
    ExpressionSignatureToken *token = [tokens nextObject];

    if (token.type == SIGNATURE_TOKEN_IDENT) {
        return [[ExpressionSignatureIdent alloc] initWithName:token.string];
    }

    return nil;
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.name = name;

    return self;
}


- (NSString *)toPattern {
    // TODO: [0-9A-Za-z_]? \u?
    return [self.name stringByReplacingOccurrencesOfString:@"*"
                                                withString:@"[\\w\\d_$]*"];
}

- (NSString *)description {
    return self.name;
}

@end
