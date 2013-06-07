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

#import "PeekableEnumeratorTest.h"
#import "PeekableEnumerator.h"

@implementation PeekableEnumeratorTest

- (void)testPeekableEnumerator {
    NSArray *testArray3 = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *testArray2 = [NSArray arrayWithObjects:@"b", @"c", nil];
    
    PeekableEnumerator *peekable = nil;
    
    peekable = [[PeekableEnumerator alloc]
                initWithEnumerator:[testArray3 objectEnumerator]];
    
    STAssertEqualObjects([peekable nextObject], @"a", @"");
    STAssertEqualObjects([peekable nextObject], @"b", @"");
    STAssertEqualObjects([peekable nextObject], @"c", @"");
    STAssertNil([peekable nextObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                initWithEnumerator:[testArray3 objectEnumerator]];
    
    STAssertNil([peekable peekObjectAtOffset:3], @"");
    STAssertEqualObjects([peekable peekObjectAtOffset:2], @"c", @"");
    STAssertEqualObjects([peekable peekObjectAtOffset:1], @"b", @"");
    STAssertEqualObjects([peekable peekObjectAtOffset:0], @"a", @"");
    STAssertEqualObjects([peekable nextObject], @"a", @"");
    STAssertEqualObjects([peekable nextObject], @"b", @"");
    STAssertEqualObjects([peekable nextObject], @"c", @"");
    STAssertNil([peekable nextObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                initWithEnumerator:[testArray3 objectEnumerator]];
    
    STAssertEqualObjects([peekable allObjects], testArray3, @"");
    STAssertNil([peekable nextObject], @"");
    STAssertNil([peekable peekObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                initWithEnumerator:[testArray3 objectEnumerator]];
    
    STAssertEqualObjects([peekable peekObject], @"a", @"");
    STAssertEqualObjects([peekable allObjects], testArray3, @"");
    STAssertNil([peekable nextObject], @"");
    STAssertNil([peekable peekObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                initWithEnumerator:[testArray3 objectEnumerator]];
    
    STAssertEqualObjects([peekable nextObject], @"a", @"");
    STAssertEqualObjects([peekable allObjects], testArray2, @"");
    STAssertNil([peekable nextObject], @"");
    STAssertNil([peekable peekObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                initWithEnumerator:[testArray3 objectEnumerator]];
    
    STAssertEqualObjects([peekable peekObject], @"a", @"");
    STAssertEqualObjects([peekable nextObject], @"a", @"");
    STAssertEqualObjects([peekable peekObject], @"b", @"");
    STAssertEqualObjects([peekable peekObjectAtOffset:1], @"c", @"");
    STAssertNil([peekable peekObjectAtOffset:2], @"");
    
    STAssertEqualObjects([peekable nextObject], @"b", @"");
    STAssertEqualObjects([peekable peekObject], @"c", @"");
    STAssertNil([peekable peekObjectAtOffset:2], @"");
    
    STAssertEqualObjects([peekable nextObject], @"c", @"");
    STAssertNil([peekable peekObject], @"");
}

@end
