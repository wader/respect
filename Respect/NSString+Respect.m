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

#import "NSString+Respect.h"
#import "NSArray+Respect.h"
#import "NSString+withFnmatch.h"

@implementation NSString (Respect)

- (NSString *)respect_stringByEscapingCharactesInSet:(NSCharacterSet *)set {
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

- (NSString *)respect_stringByUnEscapingCharactersInSet:(NSCharacterSet *)set {
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

- (NSString *)respect_stringByUnEscaping {
    // nil character set means unescape any character
    return [self respect_stringByUnEscapingCharactersInSet:nil];
}


// apples usedEncoding: seems to have some problem with latin1 files
// so do our own fallback first and then use the apple one
+ (NSString *)respect_stringWithContentsOfFileTryingEncodings:(NSString *)path
                                                        error:(NSError **)error {
    for (NSNumber *encodingNumber in (@[
                                      @(NSUTF8StringEncoding),
                                      @(NSISOLatin1StringEncoding)
                                      ])) {
        NSString *source = [NSString stringWithContentsOfFile:path
                                                     encoding:[encodingNumber intValue]
                                                        error:error];
        if (source != nil) {
            return source;
        }
    }
    
    return [NSString stringWithContentsOfFile:path
                                 usedEncoding:NULL
                                        error:error];
}

- (NSString *)respect_stringByStripSuffix:(NSString *)suffix {
    if ([self hasSuffix:suffix]) {
        return [self substringToIndex:[self length] - [suffix length]];
    } else {
        return self;
    }
}

- (NSString *)respect_stringByStripSuffixes:(NSArray *)suffixes {
    for (NSString *suffix in suffixes) {
        if ([self hasSuffix:suffix]) {
            return [self substringToIndex:[self length] - [suffix length]];
        }
    }
    
    return self;
}

- (NSString *)respect_stringByStripPrefixes:(NSArray *)prefixes {
    for (NSString *prefix in prefixes) {
        if ([self hasPrefix:prefix]) {
            return [self substringFromIndex:[prefix length]];
        }
    }
    
    return self;
}

- (NSString *)respect_stringSuffixInArray:(NSArray *)suffixes {
    for (NSString *suffix in suffixes) {
        if ([self hasSuffix:suffix]) {
            return suffix;
        }
    }
    
    return nil;
}

- (NSString *)respect_stringRelativeToPathPrefix:(NSString *)pathPrefix {
    NSString *relPath = [self respect_stringByStripPrefixes:@[pathPrefix]];
    if (relPath != self && [relPath hasPrefix:@"/"]) {
        return [relPath substringFromIndex:1];
    }
    
    return relPath;
}

- (NSString *)respect_stringByReplacingParameters:(NSArray *)parameters {
    NSMutableString *replaced = [NSMutableString stringWithString:self];
    NSUInteger displace = 0;
    
    NSRegularExpression *re = [NSRegularExpression
                               regularExpressionWithPattern:@"\\$(\\d+)"
                               options:0
                               error:NULL];
    NSArray *results = [re matchesInString:self
                                   options:0
                                     range:NSMakeRange(0, [self length])];
    for (NSTextCheckingResult *result in results) {
        NSRange r = result.range;
        NSString *paramString = [self substringWithRange:[result rangeAtIndex:1]];
        NSUInteger paramNumber = [paramString intValue];
        if (paramNumber >= [parameters count]) {
            continue;
        }
        
        NSString *replacement = parameters[paramNumber];
        
        r.location -= displace;
        [replaced replaceCharactersInRange:r withString:replacement];
        displace += r.length - [replacement length];
    }
    
    return replaced;
}

+ (void)respect_permutationsCollectWithParts:(NSArray *)parts
                                permutations:(NSMutableArray *)permutations
                                      prefix:(NSString *)prefix
                                currentIndex:(int)currentIndex {
    if (currentIndex >= [parts count]) {
        [permutations addObject:prefix];
        return;
    }
    
    for (NSString *part in parts[currentIndex]) {
        [self respect_permutationsCollectWithParts:parts
                                      permutations:permutations
                                            prefix:[prefix stringByAppendingString:part]
                                      currentIndex:currentIndex + 1];
    }
}

- (NSArray *)respect_permutationsUsingGroupCharacterPair:(NSString *)pair
                                          withSeparators:(NSString *)separators {
    NSCharacterSet *separatorSet = [NSCharacterSet
                                    characterSetWithCharactersInString:separators];
    
    NSArray *parts = [self
                      withFnmatch_componentsSeparatedByCharacterPair:pair
                      allowEscape:YES
                      shouldBalance:YES
                      usingBlock:
                      ^id(NSString *string, BOOL insidePair) {
                          if (insidePair) {
                              NSMutableArray *permutations = [NSMutableArray array];
                              NSArray *components = [string
                                                     withFnmatch_componentsSeparatedByCharactersInSet:separatorSet
                                                     allowEscape:YES
                                                     balanceCharacterPair:pair];
                              
                              for (NSString *component in components) {
                                  [permutations addObjectsFromArray:
                                   [component respect_permutationsUsingGroupCharacterPair:pair
                                                                           withSeparators:separators]];
                              }
                              
                              return permutations;
                          } else {
                              return @[string];
                          }
                      }];
    
    NSMutableArray *permutations = [NSMutableArray array];
    [[self class] respect_permutationsCollectWithParts:parts
                                          permutations:permutations
                                                prefix:@""
                                          currentIndex:0];
    
    return permutations;
}

- (NSString *)respect_stringByResolvingPathRealtiveTo:(NSString *)path {
    if ([self isAbsolutePath]) {
        return self;
    } else {
        return [[NSString pathWithComponents:@[path, self]]
                stringByStandardizingPath];
    }
}

- (NSString *)respect_stringByNormalizingIOSImageName {
    return [[[self respect_stringByStripSuffixes:[NSArray respect_arrayWithIOSImageDotExtensionNames]]
             respect_stringByStripSuffixes:[NSArray respect_arrayWithIOSImageDeviceNames]]
            respect_stringByStripSuffixes:[NSArray respect_arrayWithIOSImageScaleNames]];
}

- (NSString *)respect_stringByReplacingCharactersInSet:(NSCharacterSet *)set
                                         withCharacter:(unichar)character {
    NSMutableString *replaced = [self mutableCopy];
    NSString *replaceString = [NSString stringWithFormat:@"%C", character];
    NSUInteger len = [replaced length];
    
    for (NSUInteger i = 0; i < len; i++) {
        if ([set characterIsMember:[replaced characterAtIndex:i]]) {
            [replaced replaceCharactersInRange:NSMakeRange(i, 1)
                                    withString:replaceString];
        }
    }
    
    return replaced;
}

- (NSUInteger)respect_levenshteinDistanceToString:(NSString *)string {
    NSUInteger sl = [self length];
    NSUInteger tl = [string length];
    NSUInteger *d = calloc(sizeof(*d), (sl+1) * (tl+1));
    
#define d(i, j) d[((j) * sl) + (i)]
    for (NSUInteger i = 0; i <= sl; i++) {
        d(i, 0) = i;
    }
    for (NSUInteger j = 0; j <= tl; j++) {
        d(0, j) = j;
    }
    for (NSUInteger j = 1; j <= tl; j++) {
        for (NSUInteger i = 1; i <= sl; i++) {
            if ([self characterAtIndex:i-1] == [string characterAtIndex:j-1]) {
                d(i, j) = d(i-1, j-1);
            } else {
                d(i, j) = MIN(d(i-1, j), MIN(d(i, j-1), d(i-1, j-1))) + 1;
            }
        }
    }
    
    NSUInteger r = d(sl, tl);
#undef d
    
    free(d);
    
    return r;
}

- (NSString *)respect_stringBySuggestionFromArray:(NSArray *)suggestions
                             maxDistanceThreshold:(NSUInteger)maxDistanceThreshold {
    NSString *bestSuggestion = nil;
    NSString *lowercased = [self lowercaseString];
    NSUInteger lowestDistance = NSUIntegerMax;
    
    for (NSString *suggestion in suggestions) {
        NSUInteger distance = [lowercased respect_levenshteinDistanceToString:
                               [suggestion lowercaseString]];
        if (distance <= maxDistanceThreshold && distance < lowestDistance) {
            bestSuggestion = suggestion;
            lowestDistance = distance;
        }
    }
    
    return bestSuggestion;
}

- (NSArray *)respect_componentsSeparatedByWhitespaceAllowingQuotes {
    NSMutableArray *components = [NSMutableArray array];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    NSUInteger length = [self length];
    NSUInteger startIndex = -1;
    BOOL inArgument = NO;
    BOOL inQuote = NO;
    unichar c = 0;
    unichar prev = 0;
    
    for (NSUInteger i = 0; i < length; i++, prev = c) {
        c = [self characterAtIndex:i];
        
        if (inArgument) {
            if (prev == '\\' && c == '"') {
                continue;
            }
            
            if ((!inQuote && [whitespaceSet characterIsMember:c]) ||
                (inQuote && c == '"')) {
                
                NSString *component = [self substringWithRange:
                                       NSMakeRange(startIndex, i - startIndex)];
                [components addObject:[component respect_stringByUnEscaping]];
                
                inQuote = NO;
                inArgument = NO;
                startIndex = -1;
            } else if (!inQuote && c == '"') {
                // quote inside argument
                return nil;
            }
        } else {
            if ([whitespaceSet characterIsMember:c]) {
                continue;
            }
            
            inArgument = YES;
            startIndex = i;
            
            if (prev != '\\' && c == '"') {
                inQuote = YES;
                startIndex++;
            }
        }
    }
    
    if (inQuote) {
        // quote not ended
        return nil;
    }
    
    if (inArgument) {
        NSString *component = [self substringFromIndex:startIndex];
        [components addObject:[component respect_stringByUnEscaping]];
    }
    
    return components;
}

- (NSString *)respect_stringByQuoteAndEscapeIfNeeded {
    NSCharacterSet *escapeSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\\"];
    BOOL hasEscaped = [self rangeOfCharacterFromSet:escapeSet].location != NSNotFound;
    BOOL hasSpace = [self rangeOfCharacterFromSet:
                     [NSCharacterSet whitespaceCharacterSet]].location != NSNotFound;
    
    if (!hasSpace && !hasEscaped) {
        return self;
    }
    
    NSString *escaped = [self respect_stringByEscapingCharactesInSet:escapeSet];
    if (!hasSpace) {
        return escaped;
    }
    
    return [NSString stringWithFormat:@"\"%@\"", escaped];
}

- (NSString *)respect_stringByTrimmingWhitespace {
    return [self stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
