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

#import "NSRegularExpression+withPatternAndFlags.h"
#import "NSRegularExpression+withPatternAndFlagsTest.h"

@implementation NSRegularExpression_withPatternAndFlagsTest
- (void)testRegularExpressionWithPatternAndFlags {
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression
                               regularExpressionWithPatternAndFlags:@"/a/"
                               options:0
                               error:&error];
    NSRegularExpression *rei = [NSRegularExpression
                                regularExpressionWithPatternAndFlags:@"/a/i"
                                options:0
                                error:&error];
    
    XCTAssertTrue([re numberOfMatchesInString:@"a" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertFalse([re numberOfMatchesInString:@"A" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertTrue([rei numberOfMatchesInString:@"a" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertTrue([rei numberOfMatchesInString:@"A" options:0 range:NSMakeRange(0, 1)] > 0, @"");
    XCTAssertFalse([rei numberOfMatchesInString:@"b" options:0 range:NSMakeRange(0, 1)] > 0, @"");
}

@end
