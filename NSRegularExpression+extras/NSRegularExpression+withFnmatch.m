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

#import "NSRegularExpression+withFnmatch.h"
#import "NSString+withFnmatch.h"

static NSString *fnmatchRePatternBrace(NSString *fnmatchBrace);
static NSString *fnmatchRePatternSeq(NSString *fnmatchSeq);
static NSString *fnmatchRePatternNested(NSString *fnmatch);
static NSString *fnmatchRePattern(NSString *fnmatch);

// a,b,... -> (a,b,...)
// will be called recursivly thru fnmatchRePatternNested for nested braces, that
// is also the reason for only separate on balancing {} pairs
static NSString *fnmatchRePatternBrace(NSString *fnmatchBrace) {
    NSMutableString *braceRePattern = [NSMutableString string];

    NSArray *braceParts = [fnmatchBrace withFnmatch_componentsSeparatedByCharactersInSet:
                           [NSCharacterSet characterSetWithCharactersInString:@","]
                                                                             allowEscape:YES
                                                                    balanceCharacterPair:@"{}"];
    [braceRePattern appendString:@"("];
    for (NSUInteger i = 0; i < braceParts.count; i++) {
        [braceRePattern appendString:fnmatchRePatternNested(braceParts[i])];
        if (i < braceParts.count-1) {
            [braceRePattern appendString:@"|"];
        }
    }
    [braceRePattern appendString:@")"];

    return braceRePattern;
}

// prefix*[!ab]suffix? -> prefix.*[^ab]suffix.+
// fnmatch seq are close to a regular experssion but needs some escaping
// of regular expression syntax characters, character class syntax change and
// translate * and ?
static NSString *fnmatchRePatternSeq(NSString *fnmatchSeq) {
    return [[fnmatchSeq
             withFnmatch_componentsSeparatedByCharacterPair:@"[]"
             allowEscape:YES
             usingBlock:
             ^id(NSString *string, BOOL insidePair) {
                 if (insidePair) {
                     NSMutableString *seqRePattern = [NSMutableString string];
                     NSUInteger skipFromIndex = 0;
                     [seqRePattern appendString:@"["];
                     if (string.length > 0 &&
                         [string characterAtIndex:0] == '!') {
                         skipFromIndex = 1;
                         [seqRePattern appendString:@"^"];
                     }
                     [seqRePattern appendString:
                      [[string substringFromIndex:skipFromIndex]
                       withFnmatch_stringByEscapingCharactesInSet:
                       [NSCharacterSet characterSetWithCharactersInString:@"[]^"]]];
                     [seqRePattern appendString:@"]"];

                     return seqRePattern;
                 } else {
                     return [[[string withFnmatch_stringByEscapingCharactesInSet:
                               [NSCharacterSet characterSetWithCharactersInString:@"+.|(){}[]^$"]]
                              stringByReplacingOccurrencesOfString:@"*" withString:@".*"]
                             stringByReplacingOccurrencesOfString:@"?" withString:@"."];
                 }
             }]
            componentsJoinedByString:@""];
}

static NSString *fnmatchRePatternNested(NSString *fnmatch) {
    return [[fnmatch
             withFnmatch_componentsSeparatedByCharacterPair:@"{}"
             allowEscape:YES
             shouldBalance:YES
             usingBlock:
             ^id(NSString *string, BOOL insidePair) {
                 if (insidePair) {
                     return fnmatchRePatternBrace(string);
                 } else {
                     return fnmatchRePatternSeq(string);
                 }
             }]
            componentsJoinedByString:@""];
}

static NSString *fnmatchRePattern(NSString *fnmatch) {
    // anchor re pattern, fnmatch a*b matches a filename start with a ending with b
    return [NSString stringWithFormat:@"^%@$", fnmatchRePatternNested(fnmatch)];
}

@implementation NSRegularExpression (withFnmatch)

+ (NSRegularExpression *)regularExpressionWithFnmatch:(NSString *)fnmatch
                                                error:(NSError **)error {
    NSRegularExpression *fnmatchRe = [self
                                      regularExpressionWithPattern:fnmatchRePattern(fnmatch)
                                      options:0
                                      error:error];
    // no real error handling at the moment, if re pattern fails to compile the fnmatch
    // pattern is probably invalid too.
    if (fnmatchRe == nil && error != nil) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:0
                                 userInfo:@{NSLocalizedDescriptionKey: @"Invalid fnmatch pattern"}];
    }

    return fnmatchRe;
}

@end
