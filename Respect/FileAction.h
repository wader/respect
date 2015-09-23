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

// Implements @LintFile: path

#import "ResourceLinter.h"
#import "BundleResource.h"
#import "AbstractAction.h"
#import "TextLocation.h"

typedef NS_ENUM(NSInteger, FileReferenceCondition) {
    FileReferenceConditionAll,
    FileReferenceConditionAny,
    FileReferenceConditionOptional
};

@interface FileAction : AbstractAction
@property(nonatomic, assign, readwrite) FileReferenceCondition condition;
@property(nonatomic, copy, readwrite) NSString  *permutationsPattern;

- (NSString *)conditionName;
- (void)actionOptions:(NSOrderedSet *)options;
- (NSArray *)actionResourcePaths:(NSString *)resourcePath;
- (NSString *)actionMissingResourceHint:(NSString *)resourcePath;
- (void)actionForMatchedBundleResource:(BundleResource *)bundleRes;

@end
