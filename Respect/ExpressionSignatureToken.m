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

#import "ExpressionSignatureToken.h"

// TODO: maybe use NSScanner

@interface NSString (ExpressionSignatureToken)
- (NSUInteger)indexOfFirstFromIndex:(NSUInteger)index
                     inCharacterSet:(NSCharacterSet *)characterSet;
- (NSUInteger)indexOfFirstOrEndFromIndex:(NSUInteger)index
                          inCharacterSet:(NSCharacterSet *)characterSet;
@end

@implementation NSString (ExpressionSignatureToken)
- (NSUInteger)indexOfFirstFromIndex:(NSUInteger)index
                     inCharacterSet:(NSCharacterSet *)characterSet {
    NSUInteger length = [self length];
    
    for (; index < length; index++) {
        if ([characterSet characterIsMember:[self characterAtIndex:index]]) {
            return index;
        }
    }
    
    return NSNotFound;
}

- (NSUInteger)indexOfFirstOrEndFromIndex:(NSUInteger)index
                          inCharacterSet:(NSCharacterSet *)characterSet {
    index = [self indexOfFirstFromIndex:index inCharacterSet:characterSet];
    if (index == NSNotFound) {
        return [self length];
    }
    
    return index;
}
@end

@implementation ExpressionSignatureToken

+ (id)tokenWithRange:(NSRange)range
            inString:(NSString *)string
                type:(ExpressionSignatureTokenType)type {
    
    return [[ExpressionSignatureToken alloc] initWithRange:range
                                                  inString:string
                                                      type:type];
}

+ (ExpressionSignatureToken *)tokenizeString:(NSString *)string
                                   fromIndex:(NSUInteger)index {
    static NSCharacterSet *whitespaceCharacterSet = nil;
    static NSMutableCharacterSet *identFirstCharacerSet = nil;
    static NSMutableCharacterSet *identCharacterSet = nil;
    static NSDictionary *charToToken = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
        identFirstCharacerSet = [NSMutableCharacterSet letterCharacterSet];
        // add "*" to allow wildcard matching
        // TODO: [0-9A-Za-z_]? \u?
        [identFirstCharacerSet addCharactersInString:@"_$*"];
        identCharacterSet = [NSMutableCharacterSet letterCharacterSet];
        [identCharacterSet addCharactersInString:@"0123456789_$*"];
        charToToken = @{@"[": @(SIGNATURE_TOKEN_OPEN_BRACKET),
                       @"]": @(SIGNATURE_TOKEN_CLOSE_BRACKET),
                       @"(": @(SIGNATURE_TOKEN_OPEN_PARENTHESES),
                       @")": @(SIGNATURE_TOKEN_CLOSE_PARENTHESES),
                       @":": @(SIGNATURE_TOKEN_COLON),
                       @",": @(SIGNATURE_TOKEN_COMMA),
                       @"@": @(SIGNATURE_TOKEN_AT),
                       @"$": @(SIGNATURE_TOKEN_DOLLAR)};
    });
    
    index = [string indexOfFirstFromIndex:index
                           inCharacterSet:[whitespaceCharacterSet invertedSet]];
    if (index == NSNotFound) {
        return [ExpressionSignatureToken tokenWithRange:NSMakeRange(0, 0)
                                               inString:@""
                                                   type:SIGNATURE_TOKEN_END];
    }
    
    NSString *c = [string substringWithRange:NSMakeRange(index, 1)];
    NSNumber *token = charToToken[c];
    if (token != nil) {
        return [ExpressionSignatureToken
                tokenWithRange:NSMakeRange(index, 1)
                inString:string
                type:[token intValue]];
    } else if ([identFirstCharacerSet characterIsMember:[c characterAtIndex:0]]) {
        NSRange r;
        r.location = index;
        r.length = ([string indexOfFirstOrEndFromIndex:index
                                        inCharacterSet:[identCharacterSet invertedSet]]
                    - index);
        return [ExpressionSignatureToken tokenWithRange:r
                                               inString:string
                                                   type:SIGNATURE_TOKEN_IDENT];
    }
    
    NSRange r = NSMakeRange(index, [string length] - index);
    return [ExpressionSignatureToken tokenWithRange:r
                                           inString:string
                                               type:SIGNATURE_TOKEN_UNKNOWN];
}

- (id)initWithRange:(NSRange)range
           inString:(NSString *)string
               type:(ExpressionSignatureTokenType)type {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.range = range;
    self.string = [string substringWithRange:range];
    self.type = type;
    
    return self;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ type=%d string=%@",
            [super description], self.type, self.string];
}

@end

