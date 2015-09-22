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

#import "ExpressionSignatureCall.h"
#import "ExpressionSignatureSend.h"
#import "ExpressionSignatureToken.h"
#import "ExpressionSignatureIdent.h"
#import "ExpressionSignatureArgument.h"

@implementation ExpressionSignatureCall

+ (id<ExpressionSignature>)parseTokens:(PeekableEnumerator *)tokens
                                 error:(NSError **)error {
    error = error ?: &(NSError * __autoreleasing){nil};

    ExpressionSignatureToken *current = [tokens nextObject];

    ExpressionSignatureCall *call = [[ExpressionSignatureCall alloc] init];
    call.name = [[ExpressionSignatureIdent alloc] initWithName:current.string];
    NSMutableArray *arguments = [NSMutableArray array];
    call.arguments = arguments;

    // consume open parentehses
    [tokens nextObject];

    ExpressionSignatureToken *peeked;
    BOOL emptyArgument = YES;
    while ((peeked = [tokens peekObject])) {
        if (peeked.type == SIGNATURE_TOKEN_CLOSE_PARENTHESES) {
            [tokens nextObject];
            break;
        }

        if (peeked.type == SIGNATURE_TOKEN_COMMA) {
            [arguments addObject:[[ExpressionSignatureArgument alloc]
                                  initWithType:SIGNATURE_ARGUMENT_SKIP]];
            [tokens nextObject];

            emptyArgument = YES;

            continue;
        }

        id<ExpressionSignature> exp = [ExpressionSignature parseTokens:tokens error:error];
        if (![exp isKindOfClass:[ExpressionSignatureArgument class]] &&
            ![exp isKindOfClass:[ExpressionSignatureCall class]] &&
            ![exp isKindOfClass:[ExpressionSignatureSend class]]) {
            *error = [ExpressionSignature errorWithDescriptionFormat:@"Expected argument, call or send at \"%@\"",
                      current.string];
            return nil;
        }

        [arguments addObject:exp];

        emptyArgument = NO;

        ExpressionSignatureToken *peeked = [tokens peekObject];
        if (peeked != nil && peeked.type == SIGNATURE_TOKEN_COMMA) {
            [tokens nextObject];
            emptyArgument = YES;
        }
    }

    // if no arguments, add a dummy skip argument
    if (emptyArgument) {
        [arguments addObject:[[ExpressionSignatureArgument alloc]
                              initWithType:SIGNATURE_ARGUMENT_SKIP]];
    }

    return call;
}


- (NSString *)description {
    NSMutableString *d = [NSMutableString string];

    [d appendFormat:@"%@(", (self.name).description];
    NSUInteger i = 0;
    for (id<ExpressionSignature> argument in self.arguments) {
        [d appendString:argument.description];
        if (i < (self.arguments).count-1) {
            [d appendString:@", "];
        }
        i++;
    }
    [d appendString:@")"];

    return d;
}

- (NSString *)toPattern {
    NSMutableString *pattern = [NSMutableString string];

    [pattern appendFormat:@"%@\\s*\\(\\s*", [self.name toPattern]];
    NSUInteger i = 0;
    for (id<ExpressionSignature> argument in self.arguments) {
        [pattern appendString:[argument toPattern]];
        [pattern appendString:@"\\s*"];
        if (i < self.arguments.count-1) {
            [pattern appendString:@",\\s*"];
        }
        i++;
    }
    [pattern appendString:@"\\)"];
    
    return pattern;
}

@end
