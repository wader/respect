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

#import "ExpressionSignature.h"
#import "PeekableEnumerator.h"
#import "ExpressionSignatureToken.h"
#import "ExpressionSignatureTokenEnumerator.h"
#import "ExpressionSignatureSend.h"
#import "ExpressionSignatureCall.h"
#import "ExpressionSignatureArgument.h"
#import "ExpressionSignatureIdent.h"

NSString * const ExpressionSignatureErrorDomain = @"ExpressionSignatureErrorDomain";

@implementation ExpressionSignature

+ (NSError *)errorWithDescription:(NSString *)description {
    return [NSError
            errorWithDomain:ExpressionSignatureErrorDomain
            code:0
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                      description,
                      NSLocalizedDescriptionKey,
                      nil]];
    
}

+ (NSError *)errorWithDescriptionFormat:(NSString *)descriptionFormat, ... {
    va_list va;
    va_start(va, descriptionFormat);
    NSError *error = [self errorWithDescription:
                      [[[NSString alloc] initWithFormat:descriptionFormat
                                              arguments:va]
                       autorelease]];
    va_end(va);
    
    return error;
}

// TODO: capture group info? string unescape
+ (NSRegularExpression *)stringToRegEx:(NSString *)signature
                                 error:(NSError **)error {
    error = error ?: &(NSError *){nil};
    
    ExpressionSignature *exp = [ExpressionSignature
                                signatureFromString:signature
                                error:error];
    if (*error != nil) {
        return nil;
    }
    
    return [NSRegularExpression
            regularExpressionWithPattern:[exp toPattern]
            options:0
            error:error];
}

+ (ExpressionSignature *)signatureFromString:(NSString *)signature
                                       error:(NSError **)error {
    error = error ?: &(NSError *){nil};
    
    PeekableEnumerator *peekableTokenEnumerator = [[[PeekableEnumerator alloc]
                                                    initWithEnumerator:
                                                    [[[ExpressionSignatureTokenEnumerator alloc]
                                                      initWithSignature:signature]
                                                     autorelease]]
                                                   autorelease];
    ExpressionSignature *exp = [self parseTokens:peekableTokenEnumerator
                                           error:error];
    if (exp == nil) {
        return nil;
    }
    
    if ([peekableTokenEnumerator peekObject] != nil) {
        ExpressionSignatureToken *token = [peekableTokenEnumerator nextObject];
        *error = [self errorWithDescriptionFormat:@"Trailing characters at \"%@...\"",
                  token.string];
        return nil;
    }
    
    return exp;
}

+ (id<ExpressionSignature>)parseTokens:(PeekableEnumerator *)tokens
                                 error:(NSError **)error {
    error = error ?: &(NSError *){nil};
    
    ExpressionSignatureToken *token0 = [tokens peekObjectAtOffset:0];
    ExpressionSignatureToken *token1 = [tokens peekObjectAtOffset:1];
    
    if (token0 == nil) {
        *error = [self errorWithDescriptionFormat:@"Unexpected end"];
        return nil;
    }
    
    if (token0.type == SIGNATURE_TOKEN_OPEN_BRACKET) {
        return [ExpressionSignatureSend parseTokens:tokens error:error];
    } else if (token0.type == SIGNATURE_TOKEN_IDENT &&
               token1 != nil && token1.type == SIGNATURE_TOKEN_OPEN_PARENTHESES) {
        return [ExpressionSignatureCall parseTokens:tokens error:error];
    } else if (token0.type == SIGNATURE_TOKEN_IDENT) {
        return [ExpressionSignatureIdent parseTokens:tokens error:error];
    } else if (token0.type == SIGNATURE_TOKEN_AT ||
               token0.type == SIGNATURE_TOKEN_DOLLAR) {
        return [ExpressionSignatureArgument parseTokens:tokens error:error];
    } else {
        *error = [self errorWithDescriptionFormat:@"Unexpected token \"%@\"",
                  token0.string];
        return nil;
    }
}

- (NSString *)toPattern {
    return @"";
}

- (NSString *)description {
    return @"";
}

@end
