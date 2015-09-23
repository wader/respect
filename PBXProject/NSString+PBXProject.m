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

#import "NSString+PBXProject.h"

@implementation NSString (PBXProject)
- (NSString *)pbx_stringByReplacingVariablesNestedUsingBlock:(NSString * (^)
                                                              (NSString *variableName))block {
    NSString *template = self;
    NSString *replaced = nil;
    const NSUInteger maxDepth = 10;

    for (NSUInteger i = 0 ; i < maxDepth; i++) {
        replaced = [template pbx_stringByReplacingVariablesUsingBlock:block];
        if ([replaced isEqualToString:template]) {
            break;
        }

        template = replaced;
    }

    return replaced;
}

- (NSString *)pbx_stringByReplacingVariablesUsingBlock:(NSString * (^)
                                                        (NSString *variableName))block {
    NSMutableString *replaced = [NSMutableString stringWithString:self];
    NSUInteger displace = 0;

    NSRegularExpression *re = [NSRegularExpression
                               regularExpressionWithPattern:
                               // match $ (...) or ...
                               @"\\$(?:"
                               // match (variable name) capture group 1
                               @"\\(([\\w_]*)\\)"
                               // or
                               @"|"
                               // match variable name capture group 2
                               @"([\\w_]*)"
                               @")"
                               options:0
                               error:NULL];
    NSArray *results = [re matchesInString:self
                                   options:0
                                     range:NSMakeRange(0, self.length)];
    for (NSTextCheckingResult *result in results) {
        NSRange r = result.range;
        NSString *varaibleName = nil;
        if ([result rangeAtIndex:1].location != NSNotFound) {
            varaibleName = [self substringWithRange:[result rangeAtIndex:1]];
        } else {
            varaibleName = [self substringWithRange:[result rangeAtIndex:2]];
        }

        NSString *replacement = block(varaibleName);
        if (replacement == nil) {
            continue;
        }

        r.location -= displace;
        [replaced replaceCharactersInRange:r withString:replacement];
        displace += r.length - replacement.length;
    }

    return replaced;
}

- (NSString *)pbx_stringByReplacingVariablesFromDict:(NSDictionary *)variables {
    return [self pbx_stringByReplacingVariablesUsingBlock:
            ^NSString *(NSString *name) {
                return variables[name];
            }];
}

- (NSString *)pbx_stringByStandardizingAbsolutePath:(NSString *)path {
    if (self.absolutePath) {
        return self.stringByStandardizingPath;
    }

    // current work directory + realtive path
    return [NSString pathWithComponents:
            @[path, self]].stringByStandardizingPath;
}
@end
