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
    
    XCTAssertEqualObjects([peekable nextObject], @"a", @"");
    XCTAssertEqualObjects([peekable nextObject], @"b", @"");
    XCTAssertEqualObjects([peekable nextObject], @"c", @"");
    XCTAssertNil([peekable nextObject], @"");
    

    peekable = [[PeekableEnumerator alloc]
                 initWithEnumerator:[testArray3 objectEnumerator]];
    
    XCTAssertNil([peekable peekObjectAtOffset:3], @"");
    XCTAssertEqualObjects([peekable peekObjectAtOffset:2], @"c", @"");
    XCTAssertEqualObjects([peekable peekObjectAtOffset:1], @"b", @"");
    XCTAssertEqualObjects([peekable peekObjectAtOffset:0], @"a", @"");
    XCTAssertEqualObjects([peekable nextObject], @"a", @"");
    XCTAssertEqualObjects([peekable nextObject], @"b", @"");
    XCTAssertEqualObjects([peekable nextObject], @"c", @"");
    XCTAssertNil([peekable nextObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                 initWithEnumerator:[testArray3 objectEnumerator]];
    
    XCTAssertEqualObjects([peekable allObjects], testArray3, @"");
    XCTAssertNil([peekable nextObject], @"");
    XCTAssertNil([peekable peekObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                 initWithEnumerator:[testArray3 objectEnumerator]];
    
    XCTAssertEqualObjects([peekable peekObject], @"a", @"");
    XCTAssertEqualObjects([peekable allObjects], testArray3, @"");
    XCTAssertNil([peekable nextObject], @"");
    XCTAssertNil([peekable peekObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                 initWithEnumerator:[testArray3 objectEnumerator]];
    
    XCTAssertEqualObjects([peekable nextObject], @"a", @"");
    XCTAssertEqualObjects([peekable allObjects], testArray2, @"");
    XCTAssertNil([peekable nextObject], @"");
    XCTAssertNil([peekable peekObject], @"");
    
    
    peekable = [[PeekableEnumerator alloc]
                 initWithEnumerator:[testArray3 objectEnumerator]];
    
    XCTAssertEqualObjects([peekable peekObject], @"a", @"");
    XCTAssertEqualObjects([peekable nextObject], @"a", @"");
    XCTAssertEqualObjects([peekable peekObject], @"b", @"");
    XCTAssertEqualObjects([peekable peekObjectAtOffset:1], @"c", @"");
    XCTAssertNil([peekable peekObjectAtOffset:2], @"");
    
    XCTAssertEqualObjects([peekable nextObject], @"b", @"");
    XCTAssertEqualObjects([peekable peekObject], @"c", @"");
    XCTAssertNil([peekable peekObjectAtOffset:2], @"");
    
    XCTAssertEqualObjects([peekable nextObject], @"c", @"");
    XCTAssertNil([peekable peekObject], @"");
}

@end
