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

#import "ExpressionSignatureTest.h"
#import "ExpressionSignature.h"

static BOOL ExpressionSignatureTestCase(NSString *signature,
                                        NSArray *expectedStrings,
                                        NSArray *tests) {
    NSError *error = nil;

    NSRegularExpression *re = [ExpressionSignature stringToRegEx:signature error:&error];
    if (re == nil) {
        // should fail
        if (expectedStrings == nil) {
            return YES;
        }

        return NO;
    }

    for (NSString *test in tests) {
        NSMutableArray *matchedStrings = [NSMutableArray array];
        for (NSTextCheckingResult *result in [re matchesInString:test
                                                         options:0
                                                           range:NSMakeRange(0, test.length)]) {
            for (NSUInteger i = 1; i < result.numberOfRanges; i++) {
                [matchedStrings addObject:[test substringWithRange:[result rangeAtIndex:i]]];
            }
        }

        if (![expectedStrings isEqual:matchedStrings]) {
            return NO;
        }
    }

    return YES;
}

@implementation ExpressionSignatureTest

- (void)testExpressionSignature {
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(@,)",
                                              @[@"test"],
                                              @[@"p(\"test\",d)"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(,@)",
                                              @[@"test"],
                                              @[@"p(d,\"test\")"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(@)",
                                              @[@"test"],
                                              @[@"p(\"test\")"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(,@,,,)",
                                              @[@"test"],
                                              @[@"p(d,\"test\",d,d,d)"]));

    XCTAssertTrue(ExpressionSignatureTestCase(@"p*(@)",
                                              @[@"test"],
                                              @[@"pa(\"test\")"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"*p(@)",
                                              @[@"test"],
                                              @[@"ap(\"test\")"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"*p*(@)",
                                              @[@"test"],
                                              @[@"apa(\"test\")"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p*p(@)",
                                              @[@"test"],
                                              @[@"pap(\"test\")"]));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[*r m:@]",
                                              @[@"test"],
                                              @[@"[ar m:\"test\"]"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"[r* m:@]",
                                              @[@"test"],
                                              @[@"[ra m:\"test\"]"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"[*r* m:@]",
                                              @[@"test"],
                                              @[@"[ara m:\"test\"]"]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"[r*r m:@]",
                                              @[@"test"],
                                              @[@"[rar m:\"test\"]"]));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[tjo bla:p(@)]",
                                              @[@"test"],
                                              @[@"[tjo bla:p(\"test\")]",
                                                @"[tjo bla:p(@\"test\")]"]),
                  @"");

    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b:@]",
                                              @[@"test"],
                                              @[@"[a b:@\"test\"]"]),
                  @"");
    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b:@ c: d:@]",
                                              @[@"b", @"d"],
                                              @[@"[a b:@\"b\" c:c d:@\"d\"]"]),
                  @"");
    XCTAssertTrue(ExpressionSignatureTestCase(@"[[Appearance sharedAppearance] buttonWithImageNamed:@]",
                                              @[@"test"],
                                              @[@"[[Appearance sharedAppearance]buttonWithImageNamed:@\"test\"]",
                                                @"\t\n [\t\n [\t\n Appearance\t\n sharedAppearance\t\n ]\t\n buttonWithImageNamed:\t\n @\"test\"\t\n ]\t\n "]),
                  @"");
    XCTAssertTrue(ExpressionSignatureTestCase(@"[[[[a a:@] b:] c:@] d:[e e:@]]",
                                              @[@"a", @"c", @"e"],
                                              @[@"[[[[a a:@\"a\"] b:b] c:@\"c\"] d:[e e:@\"e\"]]"]),
                  @"");

    // TODO: verify actual error instead of just making sure we give an
    // error and dont crash

    XCTAssertTrue(ExpressionSignatureTestCase(@"", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"-", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[@", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b)", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b-", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b c]", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b c:]", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"p(", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"p(a", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"p(a,b", nil, nil));

    XCTAssertTrue(ExpressionSignatureTestCase(@"p(@) trailing", nil, nil));
}
@end
