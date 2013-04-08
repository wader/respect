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
@property(nonatomic, retain, readwrite) PBXProject *pbxProject;
@property(nonatomic, retain, readwrite) PBXNativeTarget *nativeTarget;
@property(nonatomic, retain, readwrite) XCBuildConfiguration *buildConfiguration;
@property(nonatomic, retain, readwrite) NSMutableDictionary *sourceTextFiles;
@property(nonatomic, retain, readwrite) NSMutableDictionary *resources;
@property(nonatomic, retain, readwrite) NSMutableArray *lintWarnings;
@property(nonatomic, retain, readwrite) NSMutableArray *lintErrors;
@property(nonatomic, retain, readwrite) NSArray *headerSearchPaths;

- (void)parseAndAddImportAndIncludesInTextFile:(TextFile *)textFile;
@end

@implementation ResourceLinterXcodeProjectSource
@synthesize pbxProject = _pbxProject;
@synthesize nativeTarget = _nativeTarget;
@synthesize buildConfiguration = _buildConfiguration;
@synthesize sourceTextFiles = _sourceTextFiles;
@synthesize resources = _resources;
@synthesize lintWarnings = _lintWarnings;
@synthesize lintErrors = _lintErrors;
@synthesize headerSearchPaths = _headerSearchPaths;

- (id)initWithPBXProject:(PBXProject *)pbxProject
              targetName:(NSString *)targetName
       configurationName:(NSString *)configurationName {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.pbxProject = pbxProject;
    self.nativeTarget = [pbxProject nativeTargetNamed:targetName];
    self.buildConfiguration = [self.nativeTarget configurationNamed:configurationName];
    self.sourceTextFiles = [NSMutableDictionary dictionary];
    self.resources = [NSMutableDictionary dictionary];
    self.lintWarnings = [NSMutableArray array];
    self.lintErrors = [NSMutableArray array];
    
    // fallback environmentis used if a variable find't be found in the normal
    // environment which normally is based on the current process environment.
    // this it to support running from CLI where Xcode has not exported things for us.
    self.pbxProject.fallbackEnvironment = [pbxProject
                                           buildFallbackEnvironmentWithTarget:self.nativeTarget
                                           buildConfiguration:self.buildConfiguration];
    
    self.headerSearchPaths = [self.buildConfiguration
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
            [self addSourcesBuildPhase:buildPhase];
        } else if ([buildPhase isKindOfClass:[PBXResourcesBuildPhase class]]) {
            [self addResourcesBuildPhase:buildPhase];
        }
    }
    
    return self;
}

- (void)dealloc {
    self.pbxProject = nil;
    self.nativeTarget = nil;
    self.buildConfiguration = nil;
    self.sourceTextFiles = nil;
    self.resources = nil;
    self.lintWarnings = nil;
    self.lintErrors = nil;
    
    [super dealloc];
}

- (void)addSourcesBuildPhase:(PBXSourcesBuildPhase *)sourcesBuildPhase {
    for (PBXBuildFile *buildFile in sourcesBuildPhase.files) {
        // TODO: can there be variant groups in sources build?
        if (![buildFile.fileRef isKindOfClass:[PBXFileReference class]]) {
            continue;
        }
        
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
        
        TextFile *sourceTextFile = [TextFile textFileWithContentOfFile:buildPath];
        if (sourceTextFile == nil) {
            [self.lintErrors addObject:
             [LintError lintErrorWithFile:buildPath
                                  message:@"Failed to read source file"]];
            continue;
        }
        
        [self.sourceTextFiles setObject:sourceTextFile forKey:buildPath];
        [self parseAndAddImportAndIncludesInTextFile:sourceTextFile];
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
    for (NSString *resourcePath in buildResources) {
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
            [self.lintWarnings addObject:
             [LintWarning lintWarningWithFile:buildPath
                                      message:[NSString stringWithFormat:
                                               @"Bundle path \"%@\" collides with %@",
                                               resourcePath, relativeCollisionPath]]];
            return;
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
    
    return [[[NSString alloc] initWithBytes:IOSDefault_config
                                     length:IOSDefault_config_len
                                   encoding:NSUTF8StringEncoding]
            autorelease];
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
             for (NSString *headerSearchPath in self.headerSearchPaths) {
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
                                              maxDepth:maxDepth-1];
     }];
}

- (void)parseAndAddImportAndIncludesInTextFile:(TextFile *)textFile {
    [self _parseAndAddImportAndIncludesInTextFile:textFile maxDepth:20];
}

// Spotify feature framework specific code below

- (void)addSpotifyFeatureProjectWithPath:(NSString *)featureProjectPath {
    PBXProject *featurePbxProject = [PBXProject pbxProjectFromPath:featureProjectPath
                                                       environment:nil];
    if (featurePbxProject == nil) {
        [self.lintErrors addObject:
         [LintError lintErrorWithFile:featureProjectPath
                             location:MakeTextLineLocation(1)
                              message:@"Failed to open Spotify feature project"]];
        return;
    }
    
    for (NSString *featureNativeTargetName in [featurePbxProject nativeTargetNames]) {
        PBXNativeTarget *featureNativeTarget = [featurePbxProject
                                                nativeTargetNamed:featureNativeTargetName];
        XCBuildConfiguration *featureBuildConfiguration = [featureNativeTarget
                                                           configurationNamed:self.buildConfiguration.name];
        
        featurePbxProject.fallbackEnvironment = [featurePbxProject
                                                 buildFallbackEnvironmentWithTarget:featureNativeTarget
                                                 buildConfiguration:featureBuildConfiguration];
        
        for (id buildPhase in featureNativeTarget.buildPhases) {
            if ([buildPhase isKindOfClass:[PBXSourcesBuildPhase class]]) {
                [self addSourcesBuildPhase:buildPhase];
            }
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
            if (![[NSFileManager defaultManager] fileExistsAtPath:buildPath
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
        if (![[featureSubpath pathExtension] isEqualToString:@"xcodeproj"]) {
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