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

typedef struct _TextLocation {
    NSUInteger lineNumber;
    NSRange inLineRange;
} TextLocation;

NS_INLINE TextLocation MakeTextLocation(NSUInteger lineNumber, NSRange inLineRange) {
    return (TextLocation){
        .lineNumber = lineNumber,
        .inLineRange = inLineRange
    };
}

NS_INLINE TextLocation MakeTextLineLocation(NSUInteger lineNumber) {
    return MakeTextLocation(lineNumber, NSMakeRange(0, 0));
}

NS_INLINE NSString *NSStringFromTextLocation(TextLocation textLocation) {
    if (textLocation.inLineRange.location == 0) {
        return [NSString stringWithFormat:@"%ld", textLocation.lineNumber];
    } else {
        return [NSString stringWithFormat:@"%ld:%ld",
                textLocation.lineNumber,
                textLocation.inLineRange.location];
    }
}
