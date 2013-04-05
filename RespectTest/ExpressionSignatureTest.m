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
    STAssertTrue(ExpressionSignatureTestCase(@"p(@,)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(\"test\",d)",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"p(,@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(d,\"test\")",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"p(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(\"test\")",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"p(,@,,,)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"p(d,\"test\",d,d,d)",
                                              nil]), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"p*(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"pa(\"test\")",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"*p(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"ap(\"test\")",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"*p*(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"apa(\"test\")",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"p*p(@)",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"pap(\"test\")",
                                              nil]), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[*r m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[ar m:\"test\"]",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"[r* m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[ra m:\"test\"]",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"[*r* m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[ara m:\"test\"]",
                                              nil]), nil);
    STAssertTrue(ExpressionSignatureTestCase(@"[r*r m:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[rar m:\"test\"]",
                                              nil]), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[tjo bla:p(@)]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[tjo bla:p(\"test\")]",
                                              @"[tjo bla:p(@\"test\")]",
                                              nil]),
                 @"");
    
    STAssertTrue(ExpressionSignatureTestCase(@"[a b:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[a b:@\"test\"]",
                                              nil]),
                 @"");
    STAssertTrue(ExpressionSignatureTestCase(@"[a b:@ c: d:@]",
                                             [NSArray arrayWithObjects:@"b", @"d", nil],
                                             [NSArray arrayWithObjects:
                                              @"[a b:@\"b\" c:c d:@\"d\"]",
                                              nil]),
                 @"");
    STAssertTrue(ExpressionSignatureTestCase(@"[[Appearance sharedAppearance] buttonWithImageNamed:@]",
                                             [NSArray arrayWithObject:@"test"],
                                             [NSArray arrayWithObjects:
                                              @"[[Appearance sharedAppearance]buttonWithImageNamed:@\"test\"]",
                                              @"\t\n [\t\n [\t\n Appearance\t\n sharedAppearance\t\n ]\t\n buttonWithImageNamed:\t\n @\"test\"\t\n ]\t\n ",
                                              nil]),
                 @"");
    STAssertTrue(ExpressionSignatureTestCase(@"[[[[a a:@] b:] c:@] d:[e e:@]]",
                                             [NSArray arrayWithObjects:@"a", @"c", @"e", nil],
                                             [NSArray arrayWithObjects:
                                              @"[[[[a a:@\"a\"] b:b] c:@\"c\"] d:[e e:@\"e\"]]",
                                              nil]),
                 @"");
    
    // TODO: verify actual error instead of just making sure we give an
    // error and dont crash
    
    STAssertTrue(ExpressionSignatureTestCase(@"", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"-", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[@", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[a b", nil, nil), nil);

    STAssertTrue(ExpressionSignatureTestCase(@"[a b)", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[a b-", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[a b c]", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"[a b c:]", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"p(", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"p(a", nil, nil), nil);
    
    STAssertTrue(ExpressionSignatureTestCase(@"p(a,b", nil, nil), nil);

    STAssertTrue(ExpressionSignatureTestCase(@"p(@) trailing", nil, nil), nil);
}
@end
