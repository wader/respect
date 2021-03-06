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

#import "ResourceLinter.h"

@interface ResourceLinterAbstractReport : NSObject
@property(nonatomic, strong, readonly) ResourceLinter *linter;
@property(nonatomic, strong, readonly) NSMutableString *outputBuffer;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithLinter:(ResourceLinter *)linter NS_DESIGNATED_INITIALIZER;
- (void)addLine:(NSString *)format arguments:(va_list)va  NS_FORMAT_FUNCTION(1, 0);
- (void)addLine:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void)addLines:(NSArray *)lines;
@end
