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

#import "NSRegularExpression+lineNumber.h"
#import "NSString+lineNumber.h"

@implementation NSRegularExpression (lineNumber)
- (void)enumerateMatchesWithLineNumberInString:(NSString *)string
                                       options:(NSMatchingOptions)options
                                         range:(NSRange)range
                                    lineRanges:(NSArray *)lineRanges
                                    usingBlock:(void (^)(NSTextCheckingResult *result,
                                                         NSUInteger lineNumber,
                                                         NSRange inLineRange,
                                                         NSMatchingFlags flags,
                                                         BOOL *stop))block {
    NSEnumerator *lineRangesEnumerator = [lineRanges objectEnumerator];
    __block NSValue *lineRangeValue = [lineRangesEnumerator nextObject];
    __block NSUInteger lineNumber = 1;
    
    [self enumerateMatchesInString:string
                           options:options
                             range:range
                        usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         while(lineRangeValue != nil &&
               !NSLocationInRange(result.range.location, [lineRangeValue rangeValue])) {
             lineRangeValue = [lineRangesEnumerator nextObject];
             lineNumber++;
         }
         
         NSRange inLineRange = result.range;
         // range inside current line starting from 1
         inLineRange.location -= [lineRangeValue rangeValue].location-1;
         
         block(result, lineNumber, inLineRange, flags, stop);
     }];
}

- (void)enumerateMatchesWithLineNumberInString:(NSString *)string
                                       options:(NSMatchingOptions)options
                                         range:(NSRange)range
                                    usingBlock:(void (^)(NSTextCheckingResult *result,
                                                         NSUInteger lineNumber,
                                                         NSRange inLineRange,
                                                         NSMatchingFlags flags,
                                                         BOOL *stop))block {
    [self enumerateMatchesWithLineNumberInString:string
                                         options:options
                                           range:range
                                      lineRanges:[string lineNumber_lineRanges]
                                      usingBlock:block];
}
@end
