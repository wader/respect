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

#import "NSRegularExpression+withFnmatchTest.h"
#import "NSRegularExpression+withFnmatch.h"

@implementation NSRegularExpression_withFnmatchTest

- (void)testRegularExpressionWithFnmatchTestStar {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"a*" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"a" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"ab" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"b" options:0 range:NSMakeRange(0, 1)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestQuestionMark {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"a?" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"ab" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"a" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"b" options:0 range:NSMakeRange(0, 1)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestBrace {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"a{b,c}" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"ab" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"ac" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"ad" options:0 range:NSMakeRange(0, 2)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestClass {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"a[a-c]" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"aa" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"ab" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"ac" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"ad" options:0 range:NSMakeRange(0, 2)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestNegClass {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"a[!a-c]" error:NULL];
    XCTAssertFalse([re numberOfMatchesInString:@"aa" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"ad" options:0 range:NSMakeRange(0, 2)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestEscape {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"\\{" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"{" options:0 range:NSMakeRange(0, 1)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestCombined {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"a{a*,b?,c[a-c],d[!a-c],e{a,b}}" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"aa" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"aaa" options:0 range:NSMakeRange(0, 3)] > 0, @"");

    XCTAssertFalse([re numberOfMatchesInString:@"ab" options:0 range:NSMakeRange(0, 2)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"aba" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"abaa" options:0 range:NSMakeRange(0, 4)] > 0, @"");

    XCTAssertTrue([re numberOfMatchesInString:@"aca" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"acb" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"acc" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"accd" options:0 range:NSMakeRange(0, 4)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"acd" options:0 range:NSMakeRange(0, 3)] > 0, @"");

    XCTAssertFalse([re numberOfMatchesInString:@"ada" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"adb" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"adc" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"adcd" options:0 range:NSMakeRange(0, 4)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"add" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"adda" options:0 range:NSMakeRange(0, 4)] > 0, @"");

    XCTAssertTrue([re numberOfMatchesInString:@"aea" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertTrue([re numberOfMatchesInString:@"aeb" options:0 range:NSMakeRange(0, 3)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"aec" options:0 range:NSMakeRange(0, 3)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestPractical1 {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"*.png" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"test.png" options:0 range:NSMakeRange(0, 8)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"testapng" options:0 range:NSMakeRange(0, 8)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"test.txt" options:0 range:NSMakeRange(0, 8)] > 0, @"");
}

- (void)testRegularExpressionWithFnmatchTestPractical2 {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithFnmatch:@"path/*" error:NULL];
    XCTAssertTrue([re numberOfMatchesInString:@"path/a" options:0 range:NSMakeRange(0, 6)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"path2/b" options:0 range:NSMakeRange(0, 7)] > 0, @"");
}

@end
