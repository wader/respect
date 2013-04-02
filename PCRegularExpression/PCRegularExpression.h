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

void dump_pcre_config();

NSString *const PCRegularExpressionErrorDomain;

@interface PCRegularExpressionException : NSException
@end

@interface PCRegularExpression : NSRegularExpression

+ (PCRegularExpression *)regularExpressionWithPattern:(NSString *)pattern
                                              options:(NSRegularExpressionOptions)options
                                                error:(NSError **)error;

+ (PCRegularExpression *)regularExpressionWithPatternAndFlags:(NSString *)patternAndFlags
                                                      options:(NSRegularExpressionOptions)options
                                                        error:(NSError **)error;

// block will still get ranges that uses codepoints and not bytes
// string is assumed to be valid utf-8
// can throw exception if pcre return error, should be rare
- (void)enumerateMatchesInUTF8CString:(const char *)string
                       withByteLength:(NSUInteger)byteLength
                              options:(NSMatchingOptions)options
                                range:(NSRange)range
                           usingBlock:(void (^)(NSTextCheckingResult *result,
                                                NSMatchingFlags flags,
                                                BOOL *stop))block;

- (void)enumerateMatchesWithLineNumberInUTF8CString:(const char *)string
                                     withByteLength:(NSUInteger)byteLength
                                            options:(NSMatchingOptions)options
                                              range:(NSRange)range
                                         lineRanges:(NSArray *)lineRanges
                                         usingBlock:(void (^)(NSTextCheckingResult *result,
                                                              NSUInteger lineNumber,
                                                              NSRange inLineRange,
                                                              NSMatchingFlags flags,
                                                              BOOL *stop))block;

@end
