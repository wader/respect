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

#import "ExpressionSignatureSend.h"
#import "ExpressionSignatureToken.h"
#import "ExpressionSignatureCall.h"
#import "ExpressionSignatureSend.h"
#import "ExpressionSignatureIdent.h"
#import "ExpressionSignatureToken.h"
#import "ExpressionSignatureArgument.h"

@interface ExpressionSignatureSendParameter : NSObject
@property(nonatomic, copy, readwrite) NSString *name; // TODO: ident for wildcard?
@property(nonatomic, strong, readwrite) id argument;
@end

@implementation ExpressionSignatureSendParameter
@synthesize name = _name;
@synthesize argument = _argument;

@end


@implementation ExpressionSignatureSend
@synthesize receiver = _receiver;
@synthesize parameters = _parameters;

+ (id<ExpressionSignature>)parseTokens:(PeekableEnumerator *)tokens
                                 error:(NSError **)error {
    error = error ?: &(NSError * __autoreleasing){nil};
    
    // consume [
    [tokens nextObject];
    
    ExpressionSignatureToken *current = nil;
    ExpressionSignatureToken *peeked = [tokens peekObject];
    if (peeked == nil) {
        *error = [ExpressionSignature errorWithDescription:@"Unexpected end after ["];
        return nil;
    }
    
    ExpressionSignatureSend *exp = [[ExpressionSignatureSend alloc] init];
    NSMutableArray *parameters = [NSMutableArray array];
    exp.parameters = parameters;
    exp.receiver = [ExpressionSignature parseTokens:tokens error:error];
    
    if (![exp.receiver isKindOfClass:[ExpressionSignatureIdent class]] &&
        ![exp.receiver isKindOfClass:[ExpressionSignatureCall class]] &&
        ![exp.receiver isKindOfClass:[ExpressionSignatureSend class]]) {
        *error = [ExpressionSignature errorWithDescriptionFormat:@"Expected ident, call or send at \"%@\"",
                  peeked.string];
        return nil;
    }
    
    // indicates if we have seen a parameter without argument (no colon)
    BOOL noArgument = NO;
    while ((peeked = [tokens peekObject])) {
        if (peeked.type == SIGNATURE_TOKEN_IDENT) {
            current = [tokens nextObject];
            
            ExpressionSignatureSendParameter *parameter = [[ExpressionSignatureSendParameter alloc] init];
            parameter.name = current.string;
            
            peeked = [tokens peekObject];
            if (peeked.type == SIGNATURE_TOKEN_COLON) {
                if (noArgument) {
                    *error = [ExpressionSignature errorWithDescriptionFormat:@"Invalid signature parameter at \"%@\"",
                              current.string];
                    return nil;
                }
                
                [tokens nextObject];
                
                ExpressionSignatureToken *token0 = [tokens peekObjectAtOffset:0];
                ExpressionSignatureToken *token1 = [tokens peekObjectAtOffset:1];
                
                if ((token0 != nil && token0.type == SIGNATURE_TOKEN_CLOSE_BRACKET) ||
                    (token0 != nil && token0.type == SIGNATURE_TOKEN_IDENT &&
                     token1 != nil && token1.type == SIGNATURE_TOKEN_COLON)
                    ) {
                    parameter.argument = [[ExpressionSignatureArgument alloc]
                                           initWithType:SIGNATURE_ARGUMENT_SKIP];
                } else {
                    parameter.argument = [ExpressionSignature parseTokens:tokens error:error];
                    if (parameter.argument == nil) {
                        return nil;
                    }
                }
            } else {
                if ([parameters count] > 0) {
                    *error = [ExpressionSignature errorWithDescriptionFormat:@"Invalid signature parameter at \"%@\"",
                              current.string];
                    return nil;
                }
                noArgument = YES;
            }
            
            [parameters addObject:parameter];
        } else {
            break;
        }
    }
    
    if ([parameters count] == 0) {
        *error = [ExpressionSignature errorWithDescriptionFormat:@"Signature has no parameters"];
        return nil;
    }
    
    current = [tokens nextObject];
    if (current.type == SIGNATURE_TOKEN_CLOSE_BRACKET) {
        return exp;
    } else if (current.type == SIGNATURE_TOKEN_UNKNOWN) {
        *error = [ExpressionSignature errorWithDescriptionFormat:@"Unknown token at \"%@\"",
                  current.string];
        return nil;
    } else {
        *error = [ExpressionSignature errorWithDescriptionFormat:@"Unexpected end"];
        return nil;
    }
}

- (NSString *)description {
    NSMutableString *d = [NSMutableString string];
    
    [d appendString:@"["];
    if (self.receiver != nil) {
        [d appendString:[self.receiver description]];
    } else {
        [d appendString:@"?"];
    }
    [d appendString:@" "];
    for (ExpressionSignatureSendParameter *parameter in self.parameters) {
        [d appendString:parameter.name];
        if (parameter.argument != nil) {
            [d appendString:@":"];
            [d appendString:[parameter.argument description]];
        }
    }
    [d appendString:@"]"];
    
    return d;
}

- (NSString *)toPattern {
    NSMutableString *pattern = [NSMutableString string];
    
    [pattern appendFormat:@"\\[\\s*%@", [self.receiver toPattern]];
    if ([self.receiver isKindOfClass:[ExpressionSignatureIdent class]]) {
        [pattern appendString:@"\\s+"];
    } else {
        [pattern appendString:@"\\s*"];
    }
    
    for (ExpressionSignatureSendParameter *parameter in self.parameters) {
        [pattern appendString:parameter.name];
        if (parameter.argument != nil) {
            [pattern appendString:@":\\s*"];
            [pattern appendString:[parameter.argument toPattern]];
        }
        [pattern appendString:@"\\s*"];
    }
    [pattern appendString:@"\\]"];
    
    return pattern;
}


@end
