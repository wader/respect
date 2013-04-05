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

#import "NSArray+RespectTest.h"
#import "NSArray+Respect.h"

@implementation NSArray_RespectTest

- (void)test_respect_ComponentsJoinedByWhitespaceQuoteAndEscapeIfNeeded {
    NSArray *t1 = [NSArray arrayWithObjects:@"a", nil];
    NSArray *t2 = [NSArray arrayWithObjects:@"a", @"b", nil];
    NSArray *t3 = [NSArray arrayWithObjects:@"a", @" ", @"c", nil];
    NSArray *t4 = [NSArray arrayWithObjects:@"a", @"\"", @"c", nil];
    NSArray *t5 = [NSArray arrayWithObjects:@"a", @"\\", @"c", nil];
    NSArray *t6 = [NSArray arrayWithObjects:@"a", @" \\\"", @"c", nil];
    
    STAssertEqualObjects([t1 respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded], @"a", nil);
    STAssertEqualObjects([t2 respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded], @"a b", nil);
    STAssertEqualObjects([t3 respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded], @"a \" \" c", nil);
    STAssertEqualObjects([t4 respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded], @"a \\\" c", nil);
    STAssertEqualObjects([t5 respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded], @"a \\\\ c", nil);
    STAssertEqualObjects([t6 respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded], @"a \" \\\\\\\"\" c", nil);
}

@end
