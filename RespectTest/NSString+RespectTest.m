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

#import "NSString+RespectTest.h"
#import "NSString+Respect.h"

// test some of the string methods also
#import "NSString+PBXProject.h"
#import "NSString+withFnmatch.h"
#import "NSString+lineNumber.h"

@implementation NSString_RespectTest

- (void)test_respect_stringWithContentsOfFileTryingEncodings {
    NSString *testPath = [[[[NSProcessInfo processInfo] environment]
                           objectForKey:@"TMPDIR"]
                          stringByAppendingPathComponent:@"StringWithContentOfLine"];
    NSString *expected = @"åäö";
    [[expected dataUsingEncoding:NSISOLatin1StringEncoding] writeToFile:testPath
                                                             atomically:YES];
    NSString *content = [NSString respect_stringWithContentsOfFileTryingEncodings:testPath
                                                                            error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:testPath error:NULL];
    
    STAssertEqualObjects(expected, content, @"");
}

- (void)test_respect_stringByStripSuffix {
    STAssertEqualObjects([@"" respect_stringByStripSuffix:@""], @"", @"");
    STAssertEqualObjects([@"x" respect_stringByStripSuffix:@"x"], @"", @"");
    STAssertEqualObjects([@"xa" respect_stringByStripSuffix:@"a"], @"x", @"");
    STAssertEqualObjects([@"a" respect_stringByStripSuffix:@""], @"a", @"");
}

- (void)test_respect_stringByStripSuffixes {
    NSArray *testSuffixes = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    STAssertEqualObjects([@"" respect_stringByStripSuffixes:testSuffixes], @"", @"");
    STAssertEqualObjects([@"aa" respect_stringByStripSuffixes:testSuffixes], @"a", @"");
    STAssertEqualObjects([@"ab" respect_stringByStripSuffixes:testSuffixes], @"a", @"");
    STAssertEqualObjects([@"bc" respect_stringByStripSuffixes:testSuffixes], @"bc", @"");
}

- (void)test_respect_stringByStripPrefixes {
    NSArray *testPrefixes = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    STAssertEqualObjects([@"" respect_stringByStripPrefixes:testPrefixes], @"", @"");
    STAssertEqualObjects([@"aa" respect_stringByStripPrefixes:testPrefixes], @"a", @"");
    STAssertEqualObjects([@"ba" respect_stringByStripPrefixes:testPrefixes], @"a", @"");
    STAssertEqualObjects([@"cb" respect_stringByStripPrefixes:testPrefixes], @"cb", @"");
}

- (void)test_respect_stringSuffixInArray {
    STAssertEqualObjects([@"ab" respect_stringSuffixInArray:([NSArray arrayWithObjects:@"a", @"b", nil])],
                         @"b", @"");
    STAssertNil([@"ab" respect_stringSuffixInArray:([NSArray arrayWithObjects:@"a", @"c", nil])], @"");
}

- (void)test_respect_stringRelativeToPathPrefix {
    STAssertEqualObjects([@"/a/b" respect_stringRelativeToPathPrefix:@"/a"], @"b", @"");
    STAssertEqualObjects([@"/a/b" respect_stringRelativeToPathPrefix:@"/a/"], @"b", @"");
    STAssertEqualObjects([@"/a/b" respect_stringRelativeToPathPrefix:@"/c"], @"/a/b", @"");
}

- (void)test_respect_stringByUnEscaping {
    STAssertEqualObjects([@"\\\\\\a\\" respect_stringByUnEscaping], @"\\a\\", @"");
    STAssertEqualObjects([@"\\a\\," respect_stringByUnEscapingCharactersInSet:
                          [NSCharacterSet characterSetWithCharactersInString:@","]],
                         @"\\a,", @"");
    STAssertEqualObjects([@"\\" respect_stringByUnEscaping], @"\\", @"");
    STAssertEqualObjects([@"a\\" respect_stringByUnEscaping], @"a\\", @"");
}

- (void)test_respect_stringByEscaping {
    STAssertEqualObjects([@"ab" respect_stringByEscapingCharactesInSet:
                          [NSCharacterSet characterSetWithCharactersInString:@"a"]],
                         @"\\ab", @"");
}

- (void)test_respect_stringByEscapingAndUnEscaping {
    BOOL (^testEscapeUnEscape)(NSString *string, NSCharacterSet *escapeSet) =
    ^BOOL(NSString *string, NSCharacterSet *escapeSet) {
        return [[[string respect_stringByEscapingCharactesInSet:escapeSet]
                 respect_stringByUnEscapingCharactersInSet:escapeSet]
                isEqualToString:string];
    };
    
    STAssertTrue(testEscapeUnEscape(@"a", [NSCharacterSet characterSetWithCharactersInString:@"ab"]), nil);
    STAssertTrue(testEscapeUnEscape(@"ab", [NSCharacterSet characterSetWithCharactersInString:@"ab"]), nil);
    STAssertTrue(testEscapeUnEscape(@"abc", [NSCharacterSet characterSetWithCharactersInString:@"ab"]), nil);
    STAssertTrue(testEscapeUnEscape(@"cacbc", [NSCharacterSet characterSetWithCharactersInString:@"ab"]), nil);
}

- (void)test_withFnmach_componentsSeparatedByCharactersInSet {
    NSCharacterSet *sepSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    
    STAssertEqualObjects([@"a,b,c" withFnmatch_componentsSeparatedByCharactersInSet:sepSet allowEscape:YES],
                         ([NSArray arrayWithObjects:@"a", @"b", @"c", nil]), @"");
    STAssertEqualObjects([@"a,b\\,c" withFnmatch_componentsSeparatedByCharactersInSet:sepSet allowEscape:YES],
                         ([NSArray arrayWithObjects:@"a", @"b,c", nil]), @"");
    STAssertEqualObjects([@"a,b\\,c" withFnmatch_componentsSeparatedByCharactersInSet:sepSet allowEscape:NO],
                         ([NSArray arrayWithObjects:@"a", @"b\\", @"c", nil]), @"");
}

- (void)test_withFnmach_componentsSeparatedByCharacterPair {
    id (^testBlock)(NSString *string, BOOL insidePair) = ^id(NSString *string, BOOL insidePair){
        return [NSString stringWithFormat:@"%@,%d", string, insidePair];
    };
    
    STAssertEqualObjects([@"[a]bc" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                      allowEscape:YES
                                                                       usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,1", @"bc,0", nil]),
                         @"");
    STAssertEqualObjects([@"a[b]c" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                      allowEscape:YES
                                                                       usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,0", @"b,1", @"c,0", nil]),
                         @"");
    STAssertEqualObjects([@"a[b][c]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                        allowEscape:YES
                                                                         usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,0", @"b,1", @"c,1", nil]),
                         @"");
    STAssertEqualObjects([@"ab[c]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                      allowEscape:YES
                                                                       usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"ab,0", @"c,1", nil]),
                         @"");
    STAssertEqualObjects([@"[a]\\[b]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                         allowEscape:YES
                                                                          usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,1", @"[b],0", nil]),
                         @"");
    STAssertEqualObjects([@"[a]\\[b]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                         allowEscape:NO
                                                                          usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,1", @"\\,0", @"b,1", nil]),
                         @"");
}

- (void)test_respect_stringByReplacingParameters {
    NSArray *testParameters = [NSArray arrayWithObjects:@"ab", @"a", @"b", nil];
    
    STAssertEqualObjects([@"$0" respect_stringByReplacingParameters:testParameters], @"ab", @"");
    STAssertEqualObjects([@"$1$2" respect_stringByReplacingParameters:testParameters], @"ab", @"");
    STAssertEqualObjects([@"$1-$2" respect_stringByReplacingParameters:testParameters], @"a-b", @"");
    STAssertEqualObjects([@"c$1$2" respect_stringByReplacingParameters:testParameters], @"cab", @"");
    STAssertEqualObjects([@"$0$1$2$3" respect_stringByReplacingParameters:testParameters], @"abab$3", @"");
}

- (void)test_pbx_stringByReplacingVariablesUsingBlock {
    NSString * (^block)(NSString *) = ^NSString * (NSString *variableName) {
        return variableName;
    };
    
    STAssertEqualObjects([@"$(test)" pbx_stringByReplacingVariablesUsingBlock:block], @"test", @"");
    STAssertEqualObjects([@"c$(a)c$(b)c" pbx_stringByReplacingVariablesUsingBlock:block], @"cacbc", @"");
    STAssertEqualObjects([@"$(a)$(b)$(c)$(a)$(b)$(c)" pbx_stringByReplacingVariablesUsingBlock:block], @"abcabc", @"");
    STAssertEqualObjects([@"$(a)$(bla)$(a)$(bla)" pbx_stringByReplacingVariablesUsingBlock:block], @"ablaabla", @"");
}

- (void)test_pbx_stringByReplacingVariablesNestedUsingBlock {
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"B", @"B",
                               @"A$(B)", @"A",
                               nil];
    
    NSString * (^block)(NSString *) = ^NSString * (NSString *variableName) {
        return [variables objectForKey:variableName];
    };
    
    STAssertEqualObjects([@"$(A)" pbx_stringByReplacingVariablesNestedUsingBlock:block], @"AB", @"");
}

- (void)test_pbx_stringByReplacingVariablesFromDict {
    NSDictionary *testVariables = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"test", @"test",
                                   @"a", @"a",
                                   @"b", @"b",
                                   @"c", @"c",
                                   nil];
    
    STAssertEqualObjects([@"$(test)" pbx_stringByReplacingVariablesFromDict:testVariables], @"test", @"");
    STAssertEqualObjects([@"$a/$b" pbx_stringByReplacingVariablesFromDict:testVariables], @"a/b", @"");
    STAssertEqualObjects([@"$(a)/$b" pbx_stringByReplacingVariablesFromDict:testVariables], @"a/b", @"");
    STAssertEqualObjects([@"c$(a)c$(b)c" pbx_stringByReplacingVariablesFromDict:testVariables], @"cacbc", @"");
    STAssertEqualObjects([@"$(a)$(b)$(c)$(a)$(b)$(c)" pbx_stringByReplacingVariablesFromDict:testVariables], @"abcabc", @"");
    STAssertEqualObjects([@"$(a)$(bla)$(a)$(bla)" pbx_stringByReplacingVariablesFromDict:testVariables], @"a$(bla)a$(bla)", @"");
}

- (void)test_respect_PermutationsUsingGroupCharacterPair {
    STAssertEqualObjects([@"a{b,c}" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:@"ab", @"ac", nil]), @"");
    
    STAssertEqualObjects([@"a{b{c,d}}" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:
                           @"abc",
                           @"abd",
                           nil]), @"");
    
    STAssertEqualObjects([@"a{b{c,d}b}a" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:
                           @"abcba",
                           @"abdba",
                           nil]), @"");
    
    STAssertEqualObjects([@"a{b,c}{d,e}" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:@"abd", @"abe", @"acd", @"ace", nil]), @"");
}

- (void)test_respect_stringByResolvingPathRealtiveTo {
    STAssertEqualObjects([@"file" respect_stringByResolvingPathRealtiveTo:@"/path"], @"/path/file", nil);
    STAssertEqualObjects([@"file" respect_stringByResolvingPathRealtiveTo:@"//path"], @"/path/file", nil);
    STAssertEqualObjects([@"../file" respect_stringByResolvingPathRealtiveTo:@"/path"], @"/file", nil);
    STAssertEqualObjects([@"../../file" respect_stringByResolvingPathRealtiveTo:@"/path/path"], @"/file", nil);
    STAssertEqualObjects([@"/file" respect_stringByResolvingPathRealtiveTo:@"/path"], @"/file", nil);
    STAssertEqualObjects([@"file" respect_stringByResolvingPathRealtiveTo:@"path"], @"path/file", nil);
}

- (void)test_respect_stringByNormalizingIOSImageName {
    STAssertEqualObjects([@"test.png" respect_stringByNormalizingIOSImageName], @"test", nil);
    STAssertEqualObjects([@"test~ipad.png" respect_stringByNormalizingIOSImageName], @"test", nil);
    STAssertEqualObjects([@"test~iphone.png" respect_stringByNormalizingIOSImageName], @"test", nil);
    STAssertEqualObjects([@"test@2x.png" respect_stringByNormalizingIOSImageName], @"test", nil);
    STAssertEqualObjects([@"test@2x~ipad.png" respect_stringByNormalizingIOSImageName], @"test", nil);
    STAssertEqualObjects([@"test@2x~iphone.png" respect_stringByNormalizingIOSImageName], @"test", nil);
}

- (void)test_lineNumber_lineRanges {
    NSString *lines1 =
    @"1\n"
    @" 2\n"
    @"  3\n"
    @"";
    NSArray *exceptedLineRanges1 = [NSArray arrayWithObjects:
                                    [NSValue valueWithRange:NSMakeRange(0, 2)],
                                    [NSValue valueWithRange:NSMakeRange(2, 3)],
                                    [NSValue valueWithRange:NSMakeRange(5, 4)],
                                    nil];
    STAssertEqualObjects([lines1 lineNumber_lineRanges], exceptedLineRanges1, nil);
    
    NSString *lines2 =
    @"1\n"
    @" 2\n"
    @"  3\n"
    @"     "
    @"";
    
    NSArray *exceptedLineRanges2 = [NSArray arrayWithObjects:
                                    [NSValue valueWithRange:NSMakeRange(0, 2)],
                                    [NSValue valueWithRange:NSMakeRange(2, 3)],
                                    [NSValue valueWithRange:NSMakeRange(5, 4)],
                                    [NSValue valueWithRange:NSMakeRange(9, 5)],
                                    nil];
    STAssertEqualObjects([lines2 lineNumber_lineRanges], exceptedLineRanges2, nil);
}

- (void)test_respect_stringByReplacingCharactersInSet {
    STAssertEqualObjects([@"aba" respect_stringByReplacingCharactersInSet:
                          [NSCharacterSet characterSetWithCharactersInString:@"a"] withCharacter:' '],
                         @" b ", nil);
}

- (void)test_respect_levenshteinDistanceToString {
    STAssertTrue([@"test" respect_levenshteinDistanceToString:@"test"] == 0, nil);
    STAssertTrue([@"test" respect_levenshteinDistanceToString:@"tst"] == 1, nil);
    STAssertTrue([@"test" respect_levenshteinDistanceToString:@"tests"] == 1, nil);
    STAssertTrue([@"test" respect_levenshteinDistanceToString:@""] == 4, nil);
    STAssertTrue([@"levenshtein" respect_levenshteinDistanceToString:@"distance"] == 10, nil);
}

- (void)test_respect_stringBySuggestingFromArray {
    NSArray *suggestions = [NSArray arrayWithObjects:@"ts", @"t", nil];
    STAssertEqualObjects([@"test" respect_stringBySuggestionFromArray:suggestions maxDistanceThreshold:3], @"ts", nil);
    STAssertEqualObjects([@"test" respect_stringBySuggestionFromArray:suggestions maxDistanceThreshold:2], @"ts", nil);
    STAssertNil([@"test" respect_stringBySuggestionFromArray:suggestions maxDistanceThreshold:1], nil);
}

- (void)test_respect_componentsSeparatedByWhitespaceAllowingQuotes {
    NSArray *a = [NSArray arrayWithObjects:@"a", nil];
    NSArray *aq = [NSArray arrayWithObjects:@"a\"", nil];
    NSArray *a_b = [NSArray arrayWithObjects:@"a", @"b", nil];
    NSArray *aa_bb = [NSArray arrayWithObjects:@"aa", @"bb", nil];
    NSArray *aa_bb_cc = [NSArray arrayWithObjects:@"aa", @"bb", @"cc", nil];
    NSArray *aa_bbcc = [NSArray arrayWithObjects:@"aa", @"bb cc", nil];
    NSArray *a_q_a = [NSArray arrayWithObjects:@"a", @"\"", @"a", nil];
    NSArray *a_qq_a = [NSArray arrayWithObjects:@"a", @"\"\"", @"a", nil];
    NSArray *a_qqq_a = [NSArray arrayWithObjects:@"a", @"\"\"\"", @"a", nil];
    NSArray *qa_aq = [NSArray arrayWithObjects:@"\"a", @"a\"", nil];
    
    STAssertEqualObjects([@"" respect_componentsSeparatedByWhitespaceAllowingQuotes],
                         [NSArray array], nil);
    STAssertEqualObjects([@"a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a, nil);
    STAssertEqualObjects([@"a b" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_b, nil);
    STAssertEqualObjects([@"aa bb" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb, nil);
    STAssertEqualObjects([@"  aa   bb  " respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb, nil);
    STAssertEqualObjects([@"\"\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], [NSArray arrayWithObject:@""], nil);
    STAssertEqualObjects([@"\"a\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], a, nil);
    STAssertEqualObjects([@"aa \"bb\" cc" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb_cc, nil);
    STAssertEqualObjects([@"aa \"bb cc\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bbcc, nil);
    STAssertEqualObjects([@"\"aa\"\"bb\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb, nil);
    STAssertEqualObjects([@"a\\\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aq, nil);
    STAssertEqualObjects([@"\"a\\\"\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aq, nil);
    STAssertEqualObjects([@"a \\\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_q_a, nil);
    STAssertEqualObjects([@"a \"\\\"\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_q_a, nil);
    STAssertEqualObjects([@"a \\\"\\\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_qq_a, nil);
    STAssertEqualObjects([@"a \\\"\\\"\\\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_qqq_a, nil);
    STAssertEqualObjects([@"\\\"a a\\\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], qa_aq, nil);
    STAssertEqualObjects([@"\"\\\"a\" \"a\\\"\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], qa_aq, nil);
    STAssertNil([@"\"a" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"a\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"a\"a" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"aa \"bb" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"aa\" bb" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"a a\"a b" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"a \"a b" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
    STAssertNil([@"a a\" b" respect_componentsSeparatedByWhitespaceAllowingQuotes], nil);
}

- (void)test_respect_stringByQuoteAndEscapeIfNeeded {
    STAssertEqualObjects([@"a" respect_stringByQuoteAndEscapeIfNeeded], @"a", nil);
    STAssertEqualObjects([@" " respect_stringByQuoteAndEscapeIfNeeded], @"\" \"", nil);
    STAssertEqualObjects([@"\"" respect_stringByQuoteAndEscapeIfNeeded], @"\\\"", nil);
    STAssertEqualObjects([@"\\" respect_stringByQuoteAndEscapeIfNeeded], @"\\\\", nil);
    STAssertEqualObjects([@" \\\"" respect_stringByQuoteAndEscapeIfNeeded], @"\" \\\\\\\"\"", nil);
}

- (void)test_respect_stringByTrimming {
    STAssertEqualObjects([@"\t\r\n a \n\r\n" respect_stringByTrimmingWhitespace], @"a", nil);
}


@end
