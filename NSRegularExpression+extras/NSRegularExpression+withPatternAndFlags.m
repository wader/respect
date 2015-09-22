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

#import "NSRegularExpression+withPatternAndFlags.h"

@implementation NSRegularExpression (withPatternAndFlags)
+ (NSRegularExpression *)regularExpressionWithPatternAndFlags:(NSString *)patternAndFlags
                                                      options:(NSRegularExpressionOptions)options
                                                        error:(NSError **)error {
    error = error ?: &(NSError * __autoreleasing){nil};

    NSRange start = [patternAndFlags rangeOfString:@"/" options:0];
    NSRange end = [patternAndFlags rangeOfString:@"/" options:NSBackwardsSearch];

    if (start.location != 0 ||
        end.location == NSNotFound ||
        start.location == end.location) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:0
                                 userInfo:[NSDictionary
                                           dictionaryWithObject:@"Should be in /regex/[ixsmw] format"
                                           forKey:NSLocalizedDescriptionKey]];
        return nil;
    }

    NSString *pattern = [patternAndFlags substringWithRange:
                         NSMakeRange(NSMaxRange(start),
                                     end.location-NSMaxRange(start))];
    NSString *flags = [patternAndFlags substringFromIndex:NSMaxRange(end)];

    NSRegularExpressionOptions flagsOptions = 0;
    for (NSUInteger i = 0; i < [flags length]; i++) {
        unichar c = [flags characterAtIndex:i];
        if (c == 'i') {
            flagsOptions |= NSRegularExpressionCaseInsensitive;
        } else if (c == 'x') {
            flagsOptions |= NSRegularExpressionAllowCommentsAndWhitespace;
        } else if (c == 's') {
            flagsOptions |= NSRegularExpressionDotMatchesLineSeparators;
        } else if (c == 'm') {
            flagsOptions |= NSRegularExpressionAnchorsMatchLines;
        } else if (c == 'w') {
            flagsOptions |= NSRegularExpressionUseUnicodeWordBoundaries;
        } else {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:0
                                     userInfo:[NSDictionary
                                               dictionaryWithObject:@"Invalid flags, available flags are ixsmw"
                                               forKey:NSLocalizedDescriptionKey]];
            return nil;
        }
    }

    return [NSRegularExpression regularExpressionWithPattern:pattern
                                                     options:flagsOptions|options
                                                       error:error];
}
@end
