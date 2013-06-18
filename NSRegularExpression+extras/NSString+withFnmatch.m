// Copyright (c) 2013 <mattias.wadman@gmail.com>
//
// MIT License:
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSString+withFnmatch.h"

@implementation NSString (withFnmatch)

- (NSString *)withFnmatch_stringByEscapingCharactesInSet:(NSCharacterSet *)set {
    NSMutableString *escaped = [NSMutableString string];
    NSUInteger length = [self length];
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [self characterAtIndex:i];
        if ([set characterIsMember:c]) {
            [escaped appendString:@"\\"];
        }
        
        [escaped appendFormat:@"%C", c];
    }
    
    return escaped;
}

- (NSString *)withFnmatch_stringByUnEscapingCharactersInSet:(NSCharacterSet *)set {
    NSMutableString *unescaped = [NSMutableString string];
    NSUInteger length = [self length];
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [self characterAtIndex:i];
        if (c == '\\' && i < length - 1 &&
            (set == nil || [set characterIsMember:[self characterAtIndex:i+1]])) {
            i++;
            c = [self characterAtIndex:i];
        }
        
        [unescaped appendFormat:@"%C", c];
    }
    
    return unescaped;
}

- (NSString *)withFnmatch_stringByUnEscaping {
    // nil character set means unescape any character
    return [self withFnmatch_stringByUnEscapingCharactersInSet:nil];
}

- (NSArray *)withFnmatch_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separatorSet
                                                  allowEscape:(BOOL)allowEscape
                                         balanceCharacterPair:(NSString *)pair
                                                   usingBlock:(id (^)(NSString *string))block {
    NSMutableArray *components = [NSMutableArray array];
    NSUInteger length = [self length];
    NSUInteger nextCompStartIndex = 0;
    unichar startChar = 0;
    unichar stopChar = 0;
    NSUInteger balance = 0;
    
    if (pair != nil) {
        startChar = [pair characterAtIndex:0];
        stopChar = [pair characterAtIndex:1];
    }
    
    for (NSUInteger i = 0; i < length; i++) {
        if (allowEscape &&
            (i > 0 && [self characterAtIndex:i-1] == '\\')) {
            continue;
        }
        
        unichar c = [self characterAtIndex:i];
        
        if (pair != nil) {
            if (c == startChar) {
                balance++;
            } else if (c == stopChar) {
                balance--;
            }
        }
        
        if ((pair == nil || balance == 0) &&
            [separatorSet characterIsMember:c]) {
            NSString *component = [self substringWithRange:
                                   NSMakeRange(nextCompStartIndex,
                                               i - nextCompStartIndex)];
            if (allowEscape) {
                component = [component withFnmatch_stringByUnEscapingCharactersInSet:separatorSet];
            }
            [components addObject:block(component)];
            // +1 to skip separator
            nextCompStartIndex = i + 1;
            i = nextCompStartIndex;
        }
    }
    
    if (nextCompStartIndex <= length) {
        NSString *component = [self substringFromIndex:nextCompStartIndex];
        if (allowEscape) {
            component = [component withFnmatch_stringByUnEscapingCharactersInSet:separatorSet];
        }
        [components addObject:block(component)];
    }
    
    return components;
}

- (NSArray *)withFnmatch_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separatorSet
                                                  allowEscape:(BOOL)allowEscape
                                         balanceCharacterPair:(NSString *)pair {
    return [self withFnmatch_componentsSeparatedByCharactersInSet:separatorSet
                                                      allowEscape:allowEscape
                                             balanceCharacterPair:pair
                                                       usingBlock:^id(NSString *string) {
                                                           return string;
                                                       }];
}

- (NSArray *)withFnmatch_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separatorSet
                                                  allowEscape:(BOOL)allowEscape {
    return [self withFnmatch_componentsSeparatedByCharactersInSet:separatorSet
                                                      allowEscape:allowEscape
                                             balanceCharacterPair:nil];
}

- (NSArray *)withFnmatch_componentsSeparatedByCharacterPair:(NSString *)pair
                                                allowEscape:(BOOL)allowEscape
                                              shouldBalance:(BOOL)shouldBalance
                                                 usingBlock:(id (^)(NSString *string,
                                                                    BOOL insidePair))block {
    NSMutableArray *components = [NSMutableArray array];
    unichar startChar = [pair characterAtIndex:0];
    unichar stopChar = [pair characterAtIndex:1];
    NSCharacterSet *pairSet = [NSCharacterSet characterSetWithCharactersInString:pair];
    NSUInteger length = [self length];
    NSInteger startIndex = -1;
    NSUInteger afterIndex = 0;
    NSUInteger balance = 0;
    
    for (NSUInteger i = 0; i < length; i++) {
        if (allowEscape &&
            (i > 0 && [self characterAtIndex:i-1] == '\\')) {
            continue;
        }
        
        unichar c = [self characterAtIndex:i];
        
        if (shouldBalance && c == startChar) {
            balance++;
        }
        
        if (startIndex == -1) {
            if (c == startChar) {
                startIndex = i;
            }
        } else if (c == stopChar) {
            if (shouldBalance) {
                balance--;
                
                if (balance > 0) {
                    continue;
                }
            }
            if (startIndex-afterIndex > 0) {
                NSString *before = [self substringWithRange:
                                    NSMakeRange(afterIndex, startIndex-afterIndex)];
                if (allowEscape) {
                    before = [before withFnmatch_stringByUnEscapingCharactersInSet:pairSet];
                }
                [components addObject:block(before, NO)];
            }
            [components addObject:block([self substringWithRange:
                                         NSMakeRange(startIndex+1, i-startIndex-1)],
                                        YES)];
            
            startIndex = -1;
            afterIndex = i+1;
        }
    }
    
    if (afterIndex < length) {
        NSString *after = [self substringFromIndex:afterIndex];
        if (allowEscape) {
            after = [after withFnmatch_stringByUnEscapingCharactersInSet:pairSet];
        }
        [components addObject:block(after, NO)];
    }
    
    return components;
}

- (NSArray *)withFnmatch_componentsSeparatedByCharacterPair:(NSString *)pair
                                                allowEscape:(BOOL)allowEscape
                                                 usingBlock:(id (^)(NSString *string,
                                                                    BOOL insidePair))block {
    return [self withFnmatch_componentsSeparatedByCharacterPair:pair
                                                    allowEscape:allowEscape
                                                  shouldBalance:NO
                                                     usingBlock:block];
}

@end
