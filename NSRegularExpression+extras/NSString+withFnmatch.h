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

#import <Foundation/Foundation.h>

@interface NSString (withFnmatch)

- (NSString *)withFnmatch_stringByEscapingCharactesInSet:(NSCharacterSet *)set;

// "\\ \a" -> "\ a"
- (NSString *)withFnmatch_stringByUnEscapingCharactersInSet:(NSCharacterSet *)set;
- (NSString *)withFnmatch_stringByUnEscaping;

// "a,b,c" -> ["a", "b", "c"]
// allowEscape allows escaping for separator etc, will also unescape components
// balaceCharacterPair only consider component if start/stop are balanced
// usingBlock if you want to map each component in return array
- (NSArray *)withFnmatch_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separatorSet
                                                  allowEscape:(BOOL)allowEscape
                                         balanceCharacterPair:(NSString *)pair
                                                   usingBlock:(id (^)(NSString *string))block;
- (NSArray *)withFnmatch_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separatorSet
                                                  allowEscape:(BOOL)allowEscape
                                         balanceCharacterPair:(NSString *)pair;
- (NSArray *)withFnmatch_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separator
                                                  allowEscape:(BOOL)allowEscape;

// prefix-[a,b] -> [block("prefix", NO), block("a,b", YES)]
// allowEscape allows escaping pair chars, will also unescape strings outside pairs
// shouldBalance only consider pair if start/stop are balanced
// usingBlock if you want to map each component in return array
- (NSArray *)withFnmatch_componentsSeparatedByCharacterPair:(NSString *)pair
                                                allowEscape:(BOOL)allowEscape
                                              shouldBalance:(BOOL)shouldBalance
                                                 usingBlock:(id (^)(NSString *string,
                                                                    BOOL insidePair))block;
- (NSArray *)withFnmatch_componentsSeparatedByCharacterPair:(NSString *)pair
                                                allowEscape:(BOOL)allowEscape
                                                 usingBlock:(id (^)(NSString *string,
                                                                    BOOL insidePair))block;

@end
