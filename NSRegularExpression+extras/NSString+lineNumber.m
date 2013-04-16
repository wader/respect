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

#import "NSString+lineNumber.h"

@implementation NSString (lineNumber)
- (NSArray *)lineNumber_lineRanges {
    static NSCharacterSet *newlineCharacterSet= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // \n should work for both \r\n and \n line breaks
        newlineCharacterSet = [[NSCharacterSet
                                characterSetWithCharactersInString:@"\n"]
                               retain];
    });
    
    NSMutableArray *lineRanges = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, [self length]);
    
    // about twice as fast as using NSStringEnumerationByLines/enumerateSubstringsInRange
    for (;;) {
        NSRange lineEndRange = [self rangeOfCharacterFromSet:newlineCharacterSet
                                                     options:NSLiteralSearch
                                                       range:searchRange];
        if (lineEndRange.location == NSNotFound) {
            break;
        }
        
        NSRange lineRange = NSMakeRange(searchRange.location,
                                        NSMaxRange(lineEndRange) - searchRange.location);
        searchRange.location = NSMaxRange(lineEndRange);
        searchRange.length = [self length] - searchRange.location;
        
        [lineRanges addObject:[NSValue valueWithRange:lineRange]];
    }
    
    if (searchRange.length > 0) {
        [lineRanges addObject:[NSValue valueWithRange:searchRange]];
    }
    
    return lineRanges;
}
@end
