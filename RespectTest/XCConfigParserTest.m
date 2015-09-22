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

#import "XCConfigParserTest.h"
#import "XCConfigParser.h"


static BOOL XCConfigParserTestCase(NSString *testName) {
    NSString *testPath = [[NSBundle bundleForClass:[XCConfigParserTest class]].resourcePath
                          stringByAppendingPathComponent:testName];
    NSString *testString = [NSString stringWithContentsOfFile:testPath
                                                 usedEncoding:nil
                                                        error:NULL];

    NSMutableDictionary *expectedDictionary = [NSMutableDictionary dictionary];
    NSMutableString *expectedError = [NSMutableString string];
    [testString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if (![line hasPrefix:@"// EXPECT: "]) {
            return;
        }

        NSString *expect = [line substringFromIndex:11];

        if ([expect rangeOfString:@"="].location == NSNotFound) {
            [expectedError setString:expect];
        } else {
            NSArray *keyValue = [expect componentsSeparatedByString:@"="];
            expectedDictionary[keyValue[0]] = keyValue[1];
        }
    }];

    NSError *actualError = nil;
    NSDictionary *actualDictionary = [XCConfigParser dictionaryFromFile:testPath
                                                                  error:&actualError];
    NSError *actualError2 = nil;
    NSDictionary *actualDictionary2 = [XCConfigParser dictionaryFromString:testString
                                                           includeBasePath:testPath.stringByDeletingLastPathComponent
                                                                     error:&actualError2];

    if (expectedError.length > 0) {
        return (actualDictionary == nil &&
                actualDictionary2 == nil &&
                [actualError.localizedDescription
                 rangeOfString:expectedError].location != NSNotFound &&
                [actualError2.localizedDescription
                 rangeOfString:expectedError].location != NSNotFound);
    } else {
        return (actualDictionary != nil &&
                actualDictionary2 != nil &&
                expectedDictionary != nil &&
                [expectedDictionary isEqualToDictionary:actualDictionary] &&
                [expectedDictionary isEqualToDictionary:actualDictionary2]);
    }

}

@implementation XCConfigParserTest

- (void)test_XConfigParser {
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test1.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test2.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test3.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test4.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test5.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test6.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test7.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test8.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test9.xcconfig"), @"");
    XCTAssertTrue(XCConfigParserTestCase(@"xcconfig_test10.xcconfig"), @"");
}

@end
