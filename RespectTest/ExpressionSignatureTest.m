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
                                                           range:NSMakeRange(0, [test length])]) {
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
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(\"test\",d)",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(,@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(d,\"test\")",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(\"test\")",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p(,@,,,)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(d,\"test\",d,d,d)",
                                              nil]));
    
    XCTAssertTrue(ExpressionSignatureTestCase(@"p*(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"pa(\"test\")",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"*p(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"ap(\"test\")",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"*p*(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"apa(\"test\")",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"p*p(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"pap(\"test\")",
                                              nil]));
    
    XCTAssertTrue(ExpressionSignatureTestCase(@"[*r m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[ar m:\"test\"]",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"[r* m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[ra m:\"test\"]",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"[*r* m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[ara m:\"test\"]",
                                              nil]));
    XCTAssertTrue(ExpressionSignatureTestCase(@"[r*r m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[rar m:\"test\"]",
                                              nil]));
    
    XCTAssertTrue(ExpressionSignatureTestCase(@"[tjo bla:p(@)]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[tjo bla:p(\"test\")]",
                                              @"[tjo bla:p(@\"test\")]",
                                              nil]),
                 @"");
    
    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[a b:@\"test\"]",
                                              nil]),
                 @"");
    XCTAssertTrue(ExpressionSignatureTestCase(@"[a b:@ c: d:@]",
                                             [NSArray arrayWithObjects:@"b", @"d", nil],
                                             [NSArray arrayWithObjects:
                                              @"[a b:@\"b\" c:c d:@\"d\"]",
                                              nil]),
                 @"");
    XCTAssertTrue(ExpressionSignatureTestCase(@"[[Appearance sharedAppearance] buttonWithImageNamed:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[[Appearance sharedAppearance]buttonWithImageNamed:@\"test\"]",
                                              @"\t\n [\t\n [\t\n Appearance\t\n sharedAppearance\t\n ]\t\n buttonWithImageNamed:\t\n @\"test\"\t\n ]\t\n ",
                                              nil]),
                 @"");
    XCTAssertTrue(ExpressionSignatureTestCase(@"[[[[a a:@] b:] c:@] d:[e e:@]]",
                                             [NSArray arrayWithObjects:@"a", @"c", @"e", nil],
                                             [NSArray arrayWithObjects:
                                              @"[[[[a a:@\"a\"] b:b] c:@\"c\"] d:[e e:@\"e\"]]",
                                              nil]),
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
