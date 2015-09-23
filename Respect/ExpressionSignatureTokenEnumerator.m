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

#import "ExpressionSignatureTokenEnumerator.h"
#import "ExpressionSignatureToken.h"

@interface ExpressionSignatureTokenEnumerator ()
@property(nonatomic, copy, readwrite) NSString *signature;
@property(nonatomic, assign, readwrite) NSUInteger index;
@end

@implementation ExpressionSignatureTokenEnumerator

- (instancetype)initWithSignature:(NSString *)signature {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.signature = signature;
    self.index = 0;

    return self;
}

- (id)nextObject {
    if (self.index == NSNotFound) {
        return nil;
    }

    ExpressionSignatureToken *token = [ExpressionSignatureToken
                                       tokenizeString:self.signature
                                       fromIndex:self.index];
    if (token.type == SIGNATURE_TOKEN_END) {
        return nil;
    }

    self.index = NSMaxRange(token.range);

    return token;
}

- (NSArray *)allObjects {
    NSMutableArray *objects = [NSMutableArray array];

    id object = nil;
    while ((object = [self nextObject])) {
        [objects addObject:object];
    }

    return objects;
}

@end
