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

#import "TextFile.h"


typedef enum {
    ResourceLinterSourceTargetTypeIOS,
    ResourceLinterSourceTargetTypeUnknown
} ResourceLinterSourceTargetType;

@protocol ResourceLinterSource <NSObject>
// filename is key, value is TextFile
- (NSDictionary *)sourceTextFiles;
// bundle path is key, value is build path
- (NSDictionary *)resources;
// warning and errors while reading source
- (NSArray *)lintWarnings;
- (NSArray *)lintErrors;
- (NSString *)projectName;
- (NSString *)projectPath;
- (NSString *)sourceRoot;
- (NSString *)targetName;
- (NSString *)configurationName;
- (NSArray *)knownRegions;
- (ResourceLinterSourceTargetType)targetType;
- (NSString *)deploymentTarget;
- (TextFile *)defaultConfigTextFile;
@end

@interface ResourceLinter : NSObject
@property(nonatomic, strong, readonly) id<ResourceLinterSource> linterSource;
@property(nonatomic, strong, readonly) NSMutableArray *defaultConfigs;
@property(nonatomic, strong, readonly) NSMutableArray *matchers;
@property(nonatomic, strong, readonly) NSMutableDictionary *bundleResources;
@property(nonatomic, strong, readonly) NSMutableDictionary *lowercaseBundleResources;
@property(nonatomic, strong, readonly) NSMutableSet *resourceReferences;
@property(nonatomic, strong, readonly) NSMutableArray *missingReferences;
@property(nonatomic, strong, readonly) NSMutableArray *missingReferencesIgnored;
@property(nonatomic, strong, readonly) NSMutableArray *unusedResources;
@property(nonatomic, strong, readonly) NSMutableArray *unusedResourcesIgnored;
@property(nonatomic, strong, readonly) NSMutableArray *lintWarnings;
@property(nonatomic, strong, readonly) NSMutableArray *lintWarningsIgnored;
@property(nonatomic, strong, readonly) NSMutableArray *lintErrors;
@property(nonatomic, strong, readonly) NSMutableArray *lintErrorsIgnored;
@property(nonatomic, strong, readonly) NSMutableArray *configErrors;
@property(nonatomic, strong, readonly) NSMutableArray *unusedIgnoreConfigs;
@property(nonatomic, strong, readonly) NSMutableArray *missingIgnoreConfigs;
@property(nonatomic, strong, readonly) NSMutableArray *warningIgnoreConfigs;
@property(nonatomic, strong, readonly) NSMutableArray *errorIgnoreConfigs;

- (id)initWithResourceLinterSource:(id<ResourceLinterSource>)linterSource
                        configPath:(NSString *)configPath
                parseDefaultConfig:(BOOL)parseDefaultConfig;
- (id)defaultConfigValueForName:(NSString *)name;
@end
