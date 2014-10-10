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
    
    XCTAssertEqualObjects(expected, content, @"");
}

- (void)test_respect_stringByStripSuffix {
    XCTAssertEqualObjects([@"" respect_stringByStripSuffix:@""], @"", @"");
    XCTAssertEqualObjects([@"x" respect_stringByStripSuffix:@"x"], @"", @"");
    XCTAssertEqualObjects([@"xa" respect_stringByStripSuffix:@"a"], @"x", @"");
    XCTAssertEqualObjects([@"a" respect_stringByStripSuffix:@""], @"a", @"");
}

- (void)test_respect_stringByStripSuffixes {
    NSArray *testSuffixes = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    XCTAssertEqualObjects([@"" respect_stringByStripSuffixes:testSuffixes], @"", @"");
    XCTAssertEqualObjects([@"aa" respect_stringByStripSuffixes:testSuffixes], @"a", @"");
    XCTAssertEqualObjects([@"ab" respect_stringByStripSuffixes:testSuffixes], @"a", @"");
    XCTAssertEqualObjects([@"bc" respect_stringByStripSuffixes:testSuffixes], @"bc", @"");
}

- (void)test_respect_stringByStripPrefixes {
    NSArray *testPrefixes = [NSArray arrayWithObjects:@"a", @"b", nil];
    
    XCTAssertEqualObjects([@"" respect_stringByStripPrefixes:testPrefixes], @"", @"");
    XCTAssertEqualObjects([@"aa" respect_stringByStripPrefixes:testPrefixes], @"a", @"");
    XCTAssertEqualObjects([@"ba" respect_stringByStripPrefixes:testPrefixes], @"a", @"");
    XCTAssertEqualObjects([@"cb" respect_stringByStripPrefixes:testPrefixes], @"cb", @"");
}

- (void)test_respect_stringSuffixInArray {
    XCTAssertEqualObjects([@"ab" respect_stringSuffixInArray:([NSArray arrayWithObjects:@"a", @"b", nil])],
                         @"b", @"");
    XCTAssertNil([@"ab" respect_stringSuffixInArray:([NSArray arrayWithObjects:@"a", @"c", nil])], @"");
}

- (void)test_respect_stringRelativeToPathPrefix {
    XCTAssertEqualObjects([@"/a/b" respect_stringRelativeToPathPrefix:@"/a"], @"b", @"");
    XCTAssertEqualObjects([@"/a/b" respect_stringRelativeToPathPrefix:@"/a/"], @"b", @"");
    XCTAssertEqualObjects([@"/a/b" respect_stringRelativeToPathPrefix:@"/c"], @"/a/b", @"");
}

- (void)test_respect_stringByUnEscaping {
    XCTAssertEqualObjects([@"\\\\\\a\\" respect_stringByUnEscaping], @"\\a\\", @"");
    XCTAssertEqualObjects([@"\\a\\," respect_stringByUnEscapingCharactersInSet:
                          [NSCharacterSet characterSetWithCharactersInString:@","]],
                         @"\\a,", @"");
    XCTAssertEqualObjects([@"\\" respect_stringByUnEscaping], @"\\", @"");
    XCTAssertEqualObjects([@"a\\" respect_stringByUnEscaping], @"a\\", @"");
}

- (void)test_respect_stringByEscaping {
    XCTAssertEqualObjects([@"ab" respect_stringByEscapingCharactesInSet:
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
    
    XCTAssertTrue(testEscapeUnEscape(@"a", [NSCharacterSet characterSetWithCharactersInString:@"ab"]));
    XCTAssertTrue(testEscapeUnEscape(@"ab", [NSCharacterSet characterSetWithCharactersInString:@"ab"]));
    XCTAssertTrue(testEscapeUnEscape(@"abc", [NSCharacterSet characterSetWithCharactersInString:@"ab"]));
    XCTAssertTrue(testEscapeUnEscape(@"cacbc", [NSCharacterSet characterSetWithCharactersInString:@"ab"]));
}

- (void)test_withFnmach_componentsSeparatedByCharactersInSet {
    NSCharacterSet *sepSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    
    XCTAssertEqualObjects([@"a,b,c" withFnmatch_componentsSeparatedByCharactersInSet:sepSet allowEscape:YES],
                         ([NSArray arrayWithObjects:@"a", @"b", @"c", nil]), @"");
    XCTAssertEqualObjects([@"a,b\\,c" withFnmatch_componentsSeparatedByCharactersInSet:sepSet allowEscape:YES],
                         ([NSArray arrayWithObjects:@"a", @"b,c", nil]), @"");
    XCTAssertEqualObjects([@"a,b\\,c" withFnmatch_componentsSeparatedByCharactersInSet:sepSet allowEscape:NO],
                         ([NSArray arrayWithObjects:@"a", @"b\\", @"c", nil]), @"");
}

- (void)test_withFnmach_componentsSeparatedByCharacterPair {
    id (^testBlock)(NSString *string, BOOL insidePair) = ^id(NSString *string, BOOL insidePair){
        return [NSString stringWithFormat:@"%@,%d", string, insidePair];
    };
    
    XCTAssertEqualObjects([@"[a]bc" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                      allowEscape:YES
                                                                       usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,1", @"bc,0", nil]),
                         @"");
    XCTAssertEqualObjects([@"a[b]c" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                      allowEscape:YES
                                                                       usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,0", @"b,1", @"c,0", nil]),
                         @"");
    XCTAssertEqualObjects([@"a[b][c]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                        allowEscape:YES
                                                                         usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,0", @"b,1", @"c,1", nil]),
                         @"");
    XCTAssertEqualObjects([@"ab[c]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                      allowEscape:YES
                                                                       usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"ab,0", @"c,1", nil]),
                         @"");
    XCTAssertEqualObjects([@"[a]\\[b]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                         allowEscape:YES
                                                                          usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,1", @"[b],0", nil]),
                         @"");
    XCTAssertEqualObjects([@"[a]\\[b]" withFnmatch_componentsSeparatedByCharacterPair:@"[]"
                                                                         allowEscape:NO
                                                                          usingBlock:testBlock],
                         ([NSArray arrayWithObjects:@"a,1", @"\\,0", @"b,1", nil]),
                         @"");
}

- (void)test_respect_stringByReplacingParameters {
    NSArray *testParameters = [NSArray arrayWithObjects:@"ab", @"a", @"b", nil];
    
    XCTAssertEqualObjects([@"$0" respect_stringByReplacingParameters:testParameters], @"ab", @"");
    XCTAssertEqualObjects([@"$1$2" respect_stringByReplacingParameters:testParameters], @"ab", @"");
    XCTAssertEqualObjects([@"$1-$2" respect_stringByReplacingParameters:testParameters], @"a-b", @"");
    XCTAssertEqualObjects([@"c$1$2" respect_stringByReplacingParameters:testParameters], @"cab", @"");
    XCTAssertEqualObjects([@"$0$1$2$3" respect_stringByReplacingParameters:testParameters], @"abab$3", @"");
}

- (void)test_pbx_stringByReplacingVariablesUsingBlock {
    NSString * (^block)(NSString *) = ^NSString * (NSString *variableName) {
        return variableName;
    };
    
    XCTAssertEqualObjects([@"$(test)" pbx_stringByReplacingVariablesUsingBlock:block], @"test", @"");
    XCTAssertEqualObjects([@"c$(a)c$(b)c" pbx_stringByReplacingVariablesUsingBlock:block], @"cacbc", @"");
    XCTAssertEqualObjects([@"$(a)$(b)$(c)$(a)$(b)$(c)" pbx_stringByReplacingVariablesUsingBlock:block], @"abcabc", @"");
    XCTAssertEqualObjects([@"$(a)$(bla)$(a)$(bla)" pbx_stringByReplacingVariablesUsingBlock:block], @"ablaabla", @"");
}

- (void)test_pbx_stringByReplacingVariablesNestedUsingBlock {
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"B", @"B",
                               @"A$(B)", @"A",
                               nil];
    
    NSString * (^block)(NSString *) = ^NSString * (NSString *variableName) {
        return [variables objectForKey:variableName];
    };
    
    XCTAssertEqualObjects([@"$(A)" pbx_stringByReplacingVariablesNestedUsingBlock:block], @"AB", @"");
}

- (void)test_pbx_stringByReplacingVariablesFromDict {
    NSDictionary *testVariables = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"test", @"test",
                                   @"a", @"a",
                                   @"b", @"b",
                                   @"c", @"c",
                                   nil];
    
    XCTAssertEqualObjects([@"$(test)" pbx_stringByReplacingVariablesFromDict:testVariables], @"test", @"");
    XCTAssertEqualObjects([@"$a/$b" pbx_stringByReplacingVariablesFromDict:testVariables], @"a/b", @"");
    XCTAssertEqualObjects([@"$(a)/$b" pbx_stringByReplacingVariablesFromDict:testVariables], @"a/b", @"");
    XCTAssertEqualObjects([@"c$(a)c$(b)c" pbx_stringByReplacingVariablesFromDict:testVariables], @"cacbc", @"");
    XCTAssertEqualObjects([@"$(a)$(b)$(c)$(a)$(b)$(c)" pbx_stringByReplacingVariablesFromDict:testVariables], @"abcabc", @"");
    XCTAssertEqualObjects([@"$(a)$(bla)$(a)$(bla)" pbx_stringByReplacingVariablesFromDict:testVariables], @"a$(bla)a$(bla)", @"");
}

- (void)test_respect_PermutationsUsingGroupCharacterPair {
    XCTAssertEqualObjects([@"a{b,c}" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:@"ab", @"ac", nil]), @"");
    
    XCTAssertEqualObjects([@"a{b{c,d}}" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:
                           @"abc",
                           @"abd",
                           nil]), @"");
    
    XCTAssertEqualObjects([@"a{b{c,d}b}a" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:
                           @"abcba",
                           @"abdba",
                           nil]), @"");
    
    XCTAssertEqualObjects([@"a{b,c}{d,e}" respect_permutationsUsingGroupCharacterPair:@"{}" withSeparators:@","],
                         ([NSArray arrayWithObjects:@"abd", @"abe", @"acd", @"ace", nil]), @"");
}

- (void)test_respect_stringByResolvingPathRealtiveTo {
    XCTAssertEqualObjects([@"file" respect_stringByResolvingPathRealtiveTo:@"/path"], @"/path/file");
    XCTAssertEqualObjects([@"file" respect_stringByResolvingPathRealtiveTo:@"//path"], @"/path/file");
    XCTAssertEqualObjects([@"../file" respect_stringByResolvingPathRealtiveTo:@"/path"], @"/file");
    XCTAssertEqualObjects([@"../../file" respect_stringByResolvingPathRealtiveTo:@"/path/path"], @"/file");
    XCTAssertEqualObjects([@"/file" respect_stringByResolvingPathRealtiveTo:@"/path"], @"/file");
    XCTAssertEqualObjects([@"file" respect_stringByResolvingPathRealtiveTo:@"path"], @"path/file");
}

- (void)test_respect_stringByNormalizingIOSImageName {
    XCTAssertEqualObjects([@"test.png" respect_stringByNormalizingIOSImageName], @"test");
    XCTAssertEqualObjects([@"test~ipad.png" respect_stringByNormalizingIOSImageName], @"test");
    XCTAssertEqualObjects([@"test~iphone.png" respect_stringByNormalizingIOSImageName], @"test");
    XCTAssertEqualObjects([@"test@2x.png" respect_stringByNormalizingIOSImageName], @"test");
    XCTAssertEqualObjects([@"test@2x~ipad.png" respect_stringByNormalizingIOSImageName], @"test");
    XCTAssertEqualObjects([@"test@2x~iphone.png" respect_stringByNormalizingIOSImageName], @"test");
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
    XCTAssertEqualObjects([lines1 lineNumber_lineRanges], exceptedLineRanges1);
    
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
    XCTAssertEqualObjects([lines2 lineNumber_lineRanges], exceptedLineRanges2);
}

- (void)test_respect_stringByReplacingCharactersInSet {
    XCTAssertEqualObjects([@"aba" respect_stringByReplacingCharactersInSet:
                          [NSCharacterSet characterSetWithCharactersInString:@"a"] withCharacter:' '],
                         @" b ");
}

- (void)test_respect_levenshteinDistanceToString {
    XCTAssertTrue([@"test" respect_levenshteinDistanceToString:@"test"] == 0);
    XCTAssertTrue([@"test" respect_levenshteinDistanceToString:@"tst"] == 1);
    XCTAssertTrue([@"test" respect_levenshteinDistanceToString:@"tests"] == 1);
    XCTAssertTrue([@"test" respect_levenshteinDistanceToString:@""] == 4);
    XCTAssertTrue([@"levenshtein" respect_levenshteinDistanceToString:@"distance"] == 10);
}

- (void)test_respect_stringBySuggestingFromArray {
    NSArray *suggestions = [NSArray arrayWithObjects:@"ts", @"t", nil];
    XCTAssertEqualObjects([@"test" respect_stringBySuggestionFromArray:suggestions maxDistanceThreshold:3], @"ts");
    XCTAssertEqualObjects([@"test" respect_stringBySuggestionFromArray:suggestions maxDistanceThreshold:2], @"ts");
    XCTAssertNil([@"test" respect_stringBySuggestionFromArray:suggestions maxDistanceThreshold:1]);
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
    
    XCTAssertEqualObjects([@"" respect_componentsSeparatedByWhitespaceAllowingQuotes],
                         [NSArray array]);
    XCTAssertEqualObjects([@"a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a);
    XCTAssertEqualObjects([@"a b" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_b);
    XCTAssertEqualObjects([@"aa bb" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb);
    XCTAssertEqualObjects([@"  aa   bb  " respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb);
    XCTAssertEqualObjects([@"\"\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], [NSArray arrayWithObject:@""]);
    XCTAssertEqualObjects([@"\"a\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], a);
    XCTAssertEqualObjects([@"aa \"bb\" cc" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb_cc);
    XCTAssertEqualObjects([@"aa \"bb cc\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bbcc);
    XCTAssertEqualObjects([@"\"aa\"\"bb\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aa_bb);
    XCTAssertEqualObjects([@"a\\\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aq);
    XCTAssertEqualObjects([@"\"a\\\"\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], aq);
    XCTAssertEqualObjects([@"a \\\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_q_a);
    XCTAssertEqualObjects([@"a \"\\\"\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_q_a);
    XCTAssertEqualObjects([@"a \\\"\\\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_qq_a);
    XCTAssertEqualObjects([@"a \\\"\\\"\\\" a" respect_componentsSeparatedByWhitespaceAllowingQuotes], a_qqq_a);
    XCTAssertEqualObjects([@"\\\"a a\\\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], qa_aq);
    XCTAssertEqualObjects([@"\"\\\"a\" \"a\\\"\"" respect_componentsSeparatedByWhitespaceAllowingQuotes], qa_aq);
    XCTAssertNil([@"\"a" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"a\"" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"a\"a" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"aa \"bb" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"aa\" bb" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"a a\"a b" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"a \"a b" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
    XCTAssertNil([@"a a\" b" respect_componentsSeparatedByWhitespaceAllowingQuotes]);
}

- (void)test_respect_stringByQuoteAndEscapeIfNeeded {
    XCTAssertEqualObjects([@"a" respect_stringByQuoteAndEscapeIfNeeded], @"a");
    XCTAssertEqualObjects([@" " respect_stringByQuoteAndEscapeIfNeeded], @"\" \"");
    XCTAssertEqualObjects([@"\"" respect_stringByQuoteAndEscapeIfNeeded], @"\\\"");
    XCTAssertEqualObjects([@"\\" respect_stringByQuoteAndEscapeIfNeeded], @"\\\\");
    XCTAssertEqualObjects([@" \\\"" respect_stringByQuoteAndEscapeIfNeeded], @"\" \\\\\\\"\"");
}

- (void)test_respect_stringByTrimming {
    XCTAssertEqualObjects([@"\t\r\n a \n\r\n" respect_stringByTrimmingWhitespace], @"a");
}


@end
