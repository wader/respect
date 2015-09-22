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

#import "ResourceLinterXcodeProjectSource.h"
#import "TextFile.h"
#import "LintError.h"
#import "LintWarning.h"
#import "NSString+Respect.h"
#import "NSString+PBXProject.h"
#import "NSArray+Respect.h"


@interface ResourceLinterXcodeProjectSource ()
@property(nonatomic, strong, readwrite) PBXProject *pbxProject;
@property(nonatomic, strong, readwrite) PBXNativeTarget *nativeTarget;
@property(nonatomic, strong, readwrite) XCBuildConfiguration *buildConfiguration;
@property(nonatomic, strong, readwrite) NSMutableDictionary *sourceTextFiles;
@property(nonatomic, strong, readwrite) NSMutableDictionary *resources;
@property(nonatomic, strong, readwrite) NSMutableArray *lintWarnings;
@property(nonatomic, strong, readwrite) NSMutableArray *lintErrors;

- (void)parseAndAddImportAndIncludesInTextFile:(TextFile *)textFile
                             headerSearchPaths:(NSArray *)headerSearchPaths;

@end

@implementation ResourceLinterXcodeProjectSource

- (id)initWithPBXProject:(PBXProject *)pbxProject
            nativeTarget:(PBXNativeTarget *)nativeTarget
      buildConfiguration:(XCBuildConfiguration *)buildConfiguration {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.pbxProject = pbxProject;
    self.nativeTarget = nativeTarget;
    self.buildConfiguration = buildConfiguration;
    self.sourceTextFiles = [NSMutableDictionary dictionary];
    self.resources = [NSMutableDictionary dictionary];
    self.lintWarnings = [NSMutableArray array];
    self.lintErrors = [NSMutableArray array];
    
    NSArray *headerSearchPaths = [self.buildConfiguration
                                  resolveConfigPathsNamed:@"HEADER_SEARCH_PATHS"
                                  usingWorkingDirectory:[self sourceRoot]];
    
    // add precompiled header as source if found
    NSString *precompiledHeaderPath = [self.buildConfiguration
                                       resolveConfigValueNamed:@"GCC_PREFIX_HEADER"];
    if (precompiledHeaderPath != nil) {
        NSString *absPrecompiledHeaderPath = [[self sourceRoot]
                                              stringByAppendingPathComponent:precompiledHeaderPath];
        TextFile *headerTextFile = [TextFile textFileWithContentOfFile:absPrecompiledHeaderPath];
        if (headerTextFile != nil) {
            [self.sourceTextFiles setObject:headerTextFile
                                     forKey:absPrecompiledHeaderPath];
        } else {
            [self.lintErrors addObject:
             [LintError lintErrorWithFile:absPrecompiledHeaderPath
                                 location:MakeTextLineLocation(1)
                                  message:@"Failed to read precompiled header"]];
        }
    }
    
    // add Info.plist to resources
    NSString *infoPlistBuildPath = [self.buildConfiguration
                                    resolveConfigValueNamed:@"INFOPLIST_FILE"];
    if (infoPlistBuildPath != nil) {
        NSString *absInfoPlistBuildPath = [[self sourceRoot]
                                           stringByAppendingPathComponent:infoPlistBuildPath];
        [self.resources setObject:absInfoPlistBuildPath forKey:@"Info.plist"];
    }
    
    for (id buildPhase in self.nativeTarget.buildPhases) {
        // TODO: copy phase?
        
        if ([buildPhase isKindOfClass:[PBXSourcesBuildPhase class]]) {
            [self addSourcesBuildPhase:buildPhase
                     headerSearchPaths:headerSearchPaths];
        } else if ([buildPhase isKindOfClass:[PBXResourcesBuildPhase class]]) {
            [self addResourcesBuildPhase:buildPhase];
        }
    }
    
    return self;
}


- (void)addSourcesBuildPhase:(PBXSourcesBuildPhase *)sourcesBuildPhase
           headerSearchPaths:(NSArray *)headerSearchPaths {
    for (PBXBuildFile *buildFile in sourcesBuildPhase.files) {
        NSString *buildPath = [buildFile.fileRef buildPath];
        if (buildPath == nil) {
            [self.lintErrors addObject:
             [LintError lintErrorWithFile:buildPath
                                  message:[NSString stringWithFormat:
                                           @"Failed to resolve path (souceTree=%@ path=%@)",
                                           buildFile.fileRef.sourceTree,
                                           buildFile.fileRef.path]]];
            continue;
        }
        
        // A build file can have a file ref that points to a directoary and
        // not a source file (e.g. wrapper.xcmappingmodel). Just ignore if so.
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:buildPath
                                                 isDirectory:&isDir] &&
            isDir) {
            continue;
        }
        
        TextFile *sourceTextFile = [TextFile textFileWithContentOfFile:buildPath];
        if (sourceTextFile == nil) {
            [self.lintErrors addObject:
             [LintError lintErrorWithFile:buildPath
                                  message:@"Failed to read source file"]];
            continue;
        }
        
        [self.sourceTextFiles setObject:sourceTextFile forKey:buildPath];
        [self parseAndAddImportAndIncludesInTextFile:sourceTextFile
                                   headerSearchPaths:headerSearchPaths];
    }
}

- (void)addResourcesBuildPhase:(PBXResourcesBuildPhase *)resourcesBuildPhase {
    for (PBXBuildFile *buildFile in resourcesBuildPhase.files) {
        NSDictionary *buildResources = nil;
        
        // use name if present (relative path etc?), otherwise use path
        
        if ([buildFile.fileRef isKindOfClass:[PBXVariantGroup class]]) {
            PBXVariantGroup *variantGroup = (id)buildFile.fileRef;
            
            NSMutableDictionary *variantResources = [NSMutableDictionary dictionary];
            for (PBXFileReference *fileRef in variantGroup.children) {
                NSString *bundlePath = fileRef.path;
                [variantResources setObject:[fileRef buildPath]
                                     forKey:bundlePath];
            }
            buildResources = variantResources;
            
        } else if ([buildFile.fileRef isKindOfClass:[PBXFileReference class]]) {
            PBXFileReference *fileRef = (id)buildFile.fileRef;
            NSString *bundlePath = fileRef.name ?: fileRef.path;
            NSString *buildPath = [fileRef buildPath];
            
            if ([fileRef isFolderReference]) {
                NSMutableDictionary *folderResources = [NSMutableDictionary dictionary];
                NSArray *folderSubPahts = [fileRef subPathsForFolderReference];
                
                if (folderSubPahts == nil) {
                    [self.lintErrors addObject:
                     [LintError lintErrorWithFile:buildPath
                                          message:@"Failed to read folder reference"]];
                    continue;
                }
                
                for (NSString *folderSubPath in folderSubPahts) {
                    [folderResources setObject:[buildPath stringByAppendingPathComponent:folderSubPath]
                                        forKey:[bundlePath stringByAppendingPathComponent:folderSubPath]];
                }
                buildResources = folderResources;
                
            } else {
                if (![[NSFileManager defaultManager] isReadableFileAtPath:buildPath]) {
                    [self.lintErrors addObject:
                     [LintError lintErrorWithFile:buildPath
                                          message:@"Failed to open file or folder reference"]];
                    continue;
                }
                
                buildResources = [NSDictionary
                                  dictionaryWithObject:buildPath
                                  forKey:bundlePath];
            }
        }
        
        [self addBuildResourcesDict:buildResources];
    }
}

- (void)addBuildResourcesDict:(NSDictionary *)buildResources {
    for (__strong NSString *resourcePath in buildResources) {
        NSString *buildPath = [buildResources objectForKey:resourcePath];
        
        // TODO: more proper way? xib -> nib
        if ([resourcePath hasSuffix:@"xib"]) {
            resourcePath = [[resourcePath stringByDeletingPathExtension]
                            stringByAppendingPathExtension:@"nib"];
        }
        
        NSString *collisionBuildPath = [self.resources objectForKey:resourcePath];
        if (collisionBuildPath != nil) {
            NSString *relativeCollisionPath = [collisionBuildPath
                                               respect_stringRelativeToPathPrefix:self.sourceRoot];
            
            if ([buildPath isEqualToString:collisionBuildPath]) {
                [self.lintWarnings addObject:
                 [LintWarning lintWarningWithFile:buildPath
                                          message:[NSString stringWithFormat:
                                                   @"Bundle path \"%@\" copied multiple times",
                                                   resourcePath]]];
            } else {
                [self.lintWarnings addObject:
                 [LintWarning lintWarningWithFile:buildPath
                                          message:[NSString stringWithFormat:
                                                   @"Bundle path \"%@\" collides with %@",
                                                   resourcePath, relativeCollisionPath]]];
            }
            
            continue;
        }
        
        [self.resources setObject:buildPath forKey:resourcePath];
    }
}

- (NSString *)projectName {
    return [self.pbxProject projectName];
}

- (NSString *)projectPath {
    return [self.pbxProject projectPath];
}

- (NSString *)sourceRoot {
    return [self.pbxProject sourceRoot];
}

- (NSString *)targetName {
    return self.nativeTarget.name;
}

- (NSString *)configurationName {
    return self.buildConfiguration.name;
}

- (NSArray *)knownRegions {
    return [self.pbxProject knownRegions];
}

- (ResourceLinterSourceTargetType)targetType {
    NSString *sdkRoot = [self.buildConfiguration resolveConfigValueNamed:@"SDKROOT"];
    if (sdkRoot == nil) {
        return ResourceLinterSourceTargetTypeUnknown;
    }
    
    if ([sdkRoot isEqualToString:@"iphoneos"]) {
        return ResourceLinterSourceTargetTypeIOS;
    }
    
    return ResourceLinterSourceTargetTypeUnknown;
}

- (NSString *)deploymentTarget {
    if ([self targetType] == ResourceLinterSourceTargetTypeIOS) {
        return [self.buildConfiguration resolveConfigValueNamed:@"IPHONEOS_DEPLOYMENT_TARGET"];
    }
    
    return @"";
}

+ (NSString *)IOSDefultConfigString {
    // auto generated by run script from IOSDefault.config
#include "IOSDefault.config.generated.c"
    
    return [[NSString alloc] initWithBytes:IOSDefault_config
                                     length:IOSDefault_config_len
                                   encoding:NSUTF8StringEncoding];
}

- (TextFile *)defaultConfigTextFile {
    if ([self targetType] == ResourceLinterSourceTargetTypeIOS) {
        return [TextFile
                textFileWithText:
                [[[self class] IOSDefultConfigString]
                 pbx_stringByReplacingVariablesFromDict:
                 [NSDictionary dictionaryWithObjectsAndKeys:
                  [[NSArray respect_arrayWithIOSImageDeviceNames]
                   componentsJoinedByString:@"|"],
                  @"DEVICES_RE",
                  [[NSArray respect_arrayWithIOSImageExtensionNames]
                   componentsJoinedByString:@"|"],
                  @"EXTS_RE",
                  nil]]
                path:@"IOSDefault.config"];
    } else {
        // TODO: OS X project etc
        return [TextFile textFileWithText:@"" path:@""];
    }
}

- (void)_parseAndAddImportAndIncludesInTextFile:(TextFile *)textFile
                              headerSearchPaths:(NSArray *)headerSearchPaths
                                       maxDepth:(NSUInteger)maxDepth {
    static NSRegularExpression *re = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        re = [[NSRegularExpression alloc]
              initWithPattern:
              // match #include "..." or #import "..."
              // capture group 1 is filename
              @"#\\s*(?:import|include)\\s*\"([^\"]*)\""
              options:0
              error:NULL];
    });
    
    // TODO: maxDepth limit needed?
    if (maxDepth == 0) {
        return;
    }
    
    NSString *pathDir = [textFile.path stringByDeletingLastPathComponent];
    
    [re enumerateMatchesInString:textFile.text
                         options:0
                           range:NSMakeRange(0, [textFile.text length])
                      usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         NSString *includePath = [textFile.text substringWithRange:[result rangeAtIndex:1]];
         
         NSString *absIncludePath = [includePath respect_stringByResolvingPathRealtiveTo:pathDir];
         // skip if already added
         if ([self.sourceTextFiles objectForKey:absIncludePath]) {
             return;
         }
         
         TextFile *includeTextFile = [TextFile textFileWithContentOfFile:absIncludePath];
         if (includeTextFile == nil) {
             // TODO: refactor code. but keep in mind that we might dont want to
             // refactor by building a an array with all search paths for each iteration
             for (NSString *headerSearchPath in headerSearchPaths) {
                 absIncludePath = [includePath respect_stringByResolvingPathRealtiveTo:headerSearchPath];
                 
                 // already added
                 if ([self.sourceTextFiles objectForKey:absIncludePath]) {
                     return;
                 }
                 
                 includeTextFile = [TextFile textFileWithContentOfFile:absIncludePath];
                 if (includeTextFile != nil) {
                     break;
                 }
             }
         }
         
         if (includeTextFile == nil) {
             // ignore include errors for now
             /*
              [self.lintErrors addObject:
              [LintError lintErrorWithFile:absImportPath
              message:[NSString stringWithFormat:
              @"Failed to read source file (included from %@)",
              [textFile.path stringRelativeToPathPrefix:
              [self sourceRoot]]]]];
              */
             return;
         }
         
         [self.sourceTextFiles setObject:includeTextFile forKey:absIncludePath];
         [self _parseAndAddImportAndIncludesInTextFile:includeTextFile
                                     headerSearchPaths:headerSearchPaths
                                              maxDepth:maxDepth-1];
     }];
}

- (void)parseAndAddImportAndIncludesInTextFile:(TextFile *)textFile
                             headerSearchPaths:(NSArray *)headerSearchPaths {
    [self _parseAndAddImportAndIncludesInTextFile:textFile
                                headerSearchPaths:headerSearchPaths
                                         maxDepth:20];
}

// Spotify feature framework specific code below

- (void)addSpotifyFeatureProjectWithPath:(NSString *)featureProjectPath {
    NSError *error = nil;
    PBXProject *featurePbxProject = [PBXProject pbxProjectFromPath:featureProjectPath
                                                             error:&error];
    if (featurePbxProject == nil) {
        [self.lintErrors addObject:
         [LintError lintErrorWithFile:featureProjectPath
                             location:MakeTextLineLocation(1)
                              message:[NSString stringWithFormat:
                                       @"Failed to open Spotify feature project (%@)",
                                       [error localizedDescription]]]];
        return;
    }
    
    NSArray *featureNativeTargets = [featurePbxProject nativeTargets];
    if ([featureNativeTargets count] == 0) {
        [self.lintErrors addObject:
         [LintError lintErrorWithFile:featureProjectPath
                             location:MakeTextLineLocation(1)
                              message:@"No native tagets found in Spotify feature project"]];
        return;
    }
    
    PBXNativeTarget *featureNativeTarget = [featureNativeTargets objectAtIndex:0];
    XCBuildConfiguration *featureBuildConfiguration = [featureNativeTarget
                                                       configurationNamed:self.buildConfiguration.name];
    if (![featurePbxProject prepareWithEnvironment:nil
                                      nativeTarget:featureNativeTarget
                                buildConfiguration:featureBuildConfiguration
                                             error:&error]) {
        [self.lintErrors addObject:
         [LintError lintErrorWithFile:featureProjectPath
                             location:MakeTextLineLocation(1)
                              message:[NSString stringWithFormat:
                                       @"Failed to open Spotify feature project (%@)",
                                       [error localizedDescription]]]];
        return;
    }
    
    NSArray *headerSearchPaths = [featureBuildConfiguration
                                  resolveConfigPathsNamed:@"HEADER_SEARCH_PATHS"
                                  usingWorkingDirectory:[featurePbxProject sourceRoot]];
    
    // add precompiled header as source if found
    NSString *precompiledHeaderPath = [featureBuildConfiguration
                                       resolveConfigValueNamed:@"GCC_PREFIX_HEADER"];
    if (precompiledHeaderPath != nil) {
        NSString *absPrecompiledHeaderPath = [[featurePbxProject sourceRoot]
                                              stringByAppendingPathComponent:precompiledHeaderPath];
        TextFile *headerTextFile = [TextFile textFileWithContentOfFile:absPrecompiledHeaderPath];
        if (headerTextFile != nil) {
            [self.sourceTextFiles setObject:headerTextFile
                                     forKey:absPrecompiledHeaderPath];
        } else {
            [self.lintErrors addObject:
             [LintError lintErrorWithFile:absPrecompiledHeaderPath
                                 location:MakeTextLineLocation(1)
                                  message:@"Failed to read precompiled header"]];
        }
    }
    
    for (id buildPhase in featureNativeTarget.buildPhases) {
        if ([buildPhase isKindOfClass:[PBXSourcesBuildPhase class]]) {
            [self addSourcesBuildPhase:buildPhase
                     headerSearchPaths:headerSearchPaths];
        }
    }
    
    NSString *buildResourcesPath = [[featurePbxProject sourceRoot]
                                    stringByAppendingPathComponent:@"Resources"];
    NSArray *bundleSubpaths = [[NSFileManager defaultManager]
                               subpathsOfDirectoryAtPath:buildResourcesPath
                               error:NULL];
    
    if (bundleSubpaths != nil) {
        NSMutableDictionary *buildResources = [NSMutableDictionary dictionary];
        for (NSString *bundleSubpath in bundleSubpaths) {
            NSString *buildPath = [buildResourcesPath
                                   stringByAppendingPathComponent:bundleSubpath];
            
            BOOL isDir = NO;
            // skip dot files and directories
            if ([[bundleSubpath lastPathComponent] hasPrefix:@"."] ||
                ![[NSFileManager defaultManager] fileExistsAtPath:buildPath
                                                      isDirectory:&isDir] ||
                isDir) {
                continue;
            }
            
            [buildResources setObject:buildPath forKey:bundleSubpath];
        }
        
        [self addBuildResourcesDict:buildResources];
    }
}

- (void)addSpotifyFeaturesAtPath:(NSString *)featuresPath {
    NSArray *featuresSubpaths = [[NSFileManager defaultManager]
                                 subpathsOfDirectoryAtPath:featuresPath error:NULL];
    if (featuresSubpaths == nil) {
        [self.lintErrors addObject:
         [LintError lintErrorWithFile:featuresPath
                             location:MakeTextLineLocation(1)
                              message:@"Failed to access Spotify features path"]];
        return;
    }
    
    for (NSString *featureSubpath in featuresSubpaths) {
        if (![[featureSubpath lastPathComponent] hasSuffix:@"Feature.xcodeproj"]) {
            continue;
        }
        
        NSString *fullFeaturePath = [featuresPath
                                     stringByAppendingPathComponent:featureSubpath];
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullFeaturePath
                                                  isDirectory:&isDir] ||
            !isDir) {
            continue;
        }
        
        [self addSpotifyFeatureProjectWithPath:fullFeaturePath];
    }
}

@end
