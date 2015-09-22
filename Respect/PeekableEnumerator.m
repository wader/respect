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

#import "PeekableEnumerator.h"

@interface PeekableEnumerator ()
@property(nonatomic, strong, readwrite) NSEnumerator *enumerator;
@property(nonatomic, strong, readwrite) NSMutableArray *peekedObjects;
@end

@implementation PeekableEnumerator

- (id)initWithEnumerator:(NSEnumerator *)enumerator {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.enumerator = enumerator;
    self.peekedObjects = [NSMutableArray array];

    return self;
}


- (id)nextObject {
    if ((self.peekedObjects).count == 0) {
        return [self.enumerator nextObject];
    }

    id object = self.peekedObjects[0];
    [self.peekedObjects removeObjectAtIndex:0];

    return object;
}

- (id)peekObjectAtOffset:(NSUInteger)offset {
    for (NSUInteger delta = (offset+1) - (self.peekedObjects).count;
         delta > 0; delta--) {
        id object = [self.enumerator nextObject];
        if (object == nil) {
            break;
        }

        [self.peekedObjects addObject:object];
    }

    if (offset < (self.peekedObjects).count) {
        return self.peekedObjects[offset];
    }

    return nil;
}

- (id)peekObject {
    return [self peekObjectAtOffset:0];
}

- (NSArray *)allObjects {
    NSMutableArray *objects = [NSMutableArray array];

    // this will call our nextObject and drain peekedObjects first
    for (id object in self) {
        [objects addObject:object];
    }
    
    return objects;
}

@end
