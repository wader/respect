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

#import "BundleResource.h"
#import "TextLocation.h"

@interface ResourceReference : NSObject
@property(nonatomic, copy, readonly) NSString *resourcePath;
@property(nonatomic, copy, readonly) NSString *referencePath;
@property(nonatomic, assign, readonly) TextLocation referenceLocation;
@property(nonatomic, copy, readonly) NSString *referenceHint;
@property(nonatomic, strong, readonly) NSMutableArray *bundleResources;
@property(nonatomic, copy, readonly) NSString *missingResourceHint;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResourcePath:(NSString *)resourcePath
                       referencePath:(NSString *)referencePath
                   referenceLocation:(TextLocation)referenceLocation
                       referenceHint:(NSString *)referenceHint
                 missingResourceHint:(NSString *)missingResourceHint NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithResourcePath:(NSString *)resourcePath
                       referencePath:(NSString *)referencePath
                   referenceLocation:(TextLocation)referenceLocation
                 missingResourceHint:(NSString *)missingResourceHint;
@end
