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
@property(nonatomic, retain, readonly) id<ResourceLinterSource> linterSource;
@property(nonatomic, retain, readonly) NSMutableArray *defaultConfigs;
@property(nonatomic, retain, readonly) NSMutableArray *matchers;
@property(nonatomic, retain, readonly) NSMutableDictionary *bundleResources;
@property(nonatomic, retain, readonly) NSMutableDictionary *lowercaseBundleResources;
@property(nonatomic, retain, readonly) NSMutableSet *resourceReferences;
@property(nonatomic, retain, readonly) NSMutableArray *missingReferences;
@property(nonatomic, retain, readonly) NSMutableArray *missingReferencesIgnored;
@property(nonatomic, retain, readonly) NSMutableArray *unusedResources;
@property(nonatomic, retain, readonly) NSMutableArray *unusedResourcesIgnored;
@property(nonatomic, retain, readonly) NSMutableArray *lintWarnings;
@property(nonatomic, retain, readonly) NSMutableArray *lintWarningsIgnored;
@property(nonatomic, retain, readonly) NSMutableArray *lintErrors;
@property(nonatomic, retain, readonly) NSMutableArray *lintErrorsIgnored;
@property(nonatomic, retain, readonly) NSMutableArray *configErrors;
@property(nonatomic, retain, readonly) NSMutableArray *unusedIgnoreConfigs;
@property(nonatomic, retain, readonly) NSMutableArray *missingIgnoreConfigs;
@property(nonatomic, retain, readonly) NSMutableArray *warningIgnoreConfigs;
@property(nonatomic, retain, readonly) NSMutableArray *errorIgnoreConfigs;

- (id)initWithResourceLinterSource:(id<ResourceLinterSource>)linterSource
                        configPath:(NSString *)configPath
                parseDefaultConfig:(BOOL)parseDefaultConfig;
- (id)defaultConfigValueForName:(NSString *)name;
@end
