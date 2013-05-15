// Copyright (c) 2013 <mattias.wadman@gmail.com>
//
// MIT License:
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PBXProject.h"
#import "PBXUnarchiver.h"
#import "XCConfigParser.h"
#import "NSString+PBXProject.h"


NSString * const PBXProjectErrorDomain = @"PBXProjectErrorDomain";

static NSError *makePBXError(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSString *description = [[[NSString alloc]
                              initWithFormat:format arguments:ap]
                             autorelease];
    va_end(ap);
    
    return [NSError errorWithDomain:PBXProjectErrorDomain
                               code:0
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                     description,
                                     NSLocalizedDescriptionKey,
                                     nil]];
}

@interface PBXNode ()
@property(nonatomic, retain, readwrite) NSString *path;
@property(nonatomic, retain, readwrite) NSString *sourceTree;
@property(nonatomic, assign, readwrite) PBXNode *parent;
@property(nonatomic, assign, readwrite) PBXProject *project;
- (BOOL)isValid:(NSError **)error;
@end

@interface PBXFileReference ()
@property(nonatomic, retain, readwrite) NSString *name;
@end

@interface PBXGroup ()
@property(nonatomic, retain, readwrite) NSArray *children;
@end

@interface PBXBuildFile ()
@property(nonatomic, retain, readwrite) PBXFileReference *fileRef;
- (BOOL)isValid:(NSError **)error;
@end

@interface PBXBuildPhase ()
@property(nonatomic, retain, readwrite) NSArray *files;
- (BOOL)isValid:(NSError **)error;
@end

@interface PBXNativeTarget ()
@property(nonatomic, retain, readwrite) NSString *name;
@property(nonatomic, retain, readwrite) NSArray *buildPhases;
@property(nonatomic, retain, readwrite) XCConfigurationList *buildConfigurationList;
@end

@interface XCBuildConfiguration ()
@property(nonatomic, retain, readwrite) NSString *name;
@property(nonatomic, retain, readwrite) PBXFileReference *baseConfigurationReference;
@property(nonatomic, retain, readwrite) NSDictionary *buildSettings;
@property(nonatomic, assign, readwrite) XCBuildConfiguration *parent;
@property(nonatomic, assign, readwrite) PBXProject *project;

@property(nonatomic, retain, readwrite) NSDictionary *baseConfiguration;

- (BOOL)isValid:(NSError **)error;
@end

@interface XCConfigurationList ()
@property(nonatomic, retain, readwrite) NSArray *buildConfigurations;
- (BOOL)isValid:(NSError **)error;
@end

@interface PBXProject ()
@property(nonatomic, retain, readwrite) XCConfigurationList *buildConfigurationList;
@property(nonatomic, retain, readwrite) NSArray *targets;
@property(nonatomic, retain, readwrite) NSArray *knownRegions;
@property(nonatomic, retain, readwrite) PBXGroup *mainGroup;
@property(nonatomic, retain, readwrite) NSDictionary *environment;
@property(nonatomic, retain, readwrite) NSString *pbxFilePath;

@property(nonatomic, retain, readwrite) NSDictionary *fallbackEnvironment;

- (NSDictionary *)buildFallbackEnvironmentWithTarget:(PBXNativeTarget *)target
                                  buildConfiguration:(XCBuildConfiguration *)buildConfiguration;

@end


@implementation PBXNode
@synthesize path = _path;
@synthesize sourceTree = _sourceTree;
@synthesize parent = _parent;
@synthesize project = _project;

- (void)dealloc {
    self.path = nil;
    self.sourceTree = nil;
    
    [super dealloc];
}

- (NSString *)buildPath {
    NSString *absPath = nil;
    if ([self.sourceTree isEqualToString:@"<group>"]) {
        absPath = [self.parent buildPath];
    } else {
        absPath = [[self.project pathForSourceTree:self.sourceTree]
                   stringByStandardizingPath];
    }
    
    if (self.path) {
        absPath = [[absPath stringByAppendingPathComponent:self.path]
                   stringByStandardizingPath];
    }
    
    return absPath;
}

- (BOOL)isValid:(NSError **)error {
    // self.path can be nil
    return ((self.path == nil || [self.path isKindOfClass:[NSString class]]) &&
            self.sourceTree &&
            [self.sourceTree isKindOfClass:[NSString class]]);
}

@end


@implementation PBXFileReference
@synthesize name = _name;

- (void)dealloc {
    self.name = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (!([super isValid:error] &&
          (self.name == nil || [self.name isKindOfClass:[NSString class]]))) {
        *error = *error ?: makePBXError(@"Invalid %@", NSStringFromClass([self class]));
        return NO;
    }
    
    return YES;
}

- (BOOL)isFolderReference {
    BOOL isDir = NO;
    return ([[NSFileManager defaultManager] fileExistsAtPath:[self buildPath]
                                                 isDirectory:&isDir] &&
            isDir);
}

- (NSArray *)subPathsForFolderReference {
    NSString *folderAbsPath = [self buildPath];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:folderAbsPath];
    if (subpaths == nil) {
        return nil;
    }
    
    NSMutableArray *paths = [NSMutableArray array];
    for (NSString *subpath in subpaths) {
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager]
              fileExistsAtPath:[folderAbsPath stringByAppendingPathComponent:subpath]
              isDirectory:&isDir] ||
            isDir) {
            continue;
        }
        
        [paths addObject:subpath];
    }
    
    return paths;
}
@end


@implementation PBXGroup
@synthesize children = _children;

- (void)dealloc {
    self.children = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (![super isValid:error]) {
        return NO;
    }
    
    if (!(self.children &&
          [self.children isKindOfClass:[NSArray class]])) {
        *error = makePBXError(@"Invalid %@ (children)",
                              NSStringFromClass([self class]));
        return NO;
    }
    
    for (id child in self.children) {
        if ([child isKindOfClass:[PBXGroup class]]) {
            PBXGroup *group = child;
            if (![group isValid:error]) {
                return NO;
            }
        } else if ([child isKindOfClass:[PBXFileReference class]]) {
            PBXFileReference *fileRef = child;
            if (![fileRef isValid:error]) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)recursivelySetParent:(PBXNode *)parent andProject:(PBXProject *)project {
    self.project = project;
    self.parent = parent;
    
    for (PBXNode *child in self.children) {
        child.project = project;
        child.parent = self;
        
        if ([child isKindOfClass:[PBXGroup class]]) {
            [(PBXGroup *)child recursivelySetParent:self andProject:project];
        }
    }
    
}

/*
 + (NSString *)spaceWidth:(NSUInteger)width {
 NSMutableString *s = [NSMutableString string];
 for (NSUInteger i = 0; i < width; i++) {
 [s appendString:@" "];
 }
 return s;
 }
 
 - (void)dumpWithIndent:(NSUInteger)indent {
 NSLog(@"%@%@ sourceTree=%@ project=%@ parent=%@ path=%@",
 [[self class] spaceWidth:indent],
 self, self.sourceTree, self.project, self.parent, self.path);
 
 for (id child in self.children) {
 if ([child isKindOfClass:[PBXGroup class]]) {
 [child dumpWithIndent:indent+2];
 } else if ([child isKindOfClass:[PBXFileReference class]]) {
 NSLog(@"  %@%@", [[self class] spaceWidth:indent], ((PBXFileReference *)child).path);
 } else {
 NSLog(@"  %@%@", [[self class] spaceWidth:indent], child);
 }
 }
 }
 
 - (void)dump {
 [self dumpWithIndent:0];
 }
 */

@end


@implementation PBXVariantGroup
@end


@implementation PBXBuildFile
@synthesize fileRef = _fileRef;

- (void)dealloc {
    self.fileRef = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (!(self.fileRef &&
          [self.fileRef isKindOfClass:[PBXNode class]] &&
          [self.fileRef isValid:error])) {
        *error = *error ?: makePBXError(@"Invalid %@", NSStringFromClass([self class]));
        return NO;
    }
    
    return YES;
}
@end


@implementation PBXBuildPhase
@synthesize files = _files;

- (void)dealloc {
    self.files = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (!(self.files &&
          [self.files isKindOfClass:[NSArray class]])) {
        *error = makePBXError(@"Invalid %@ (files)",
                              NSStringFromClass([self class]));
        return NO;
    }
    
    for (PBXBuildFile *buildFile in self.files) {
        if (!([buildFile isKindOfClass:[PBXBuildFile class]] &&
              [buildFile isValid:error])) {
            *error = *error ?: makePBXError(@"Invalid %@ (buildFile)",
                                            NSStringFromClass([self class]));
            return NO;
        }
    }
    
    return YES;
}
@end


@implementation PBXSourcesBuildPhase
@end


@implementation PBXResourcesBuildPhase
@end


@implementation PBXNativeTarget
@synthesize name = _name;
@synthesize buildPhases = _buildPhases;
@synthesize buildConfigurationList = _buildConfigurationList;

- (void)dealloc {
    self.name = nil;
    self.buildPhases = nil;
    self.buildConfigurationList = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (!(self.name &&
          [self.name isKindOfClass:[NSString class]])) {
        *error = makePBXError(@"Invalid %@ (name)", NSStringFromClass([self class]));
        return NO;
    }
    
    if (!(self.buildConfigurationList &&
          [self.buildConfigurationList isKindOfClass:[XCConfigurationList class]] &&
          [self.buildConfigurationList isValid:error])) {
        *error = *error ?: makePBXError(@"Invalid %@ (buildConfigurationList)",
                                        NSStringFromClass([self class]));
        return NO;
    }
    
    if (!(self.buildPhases &&
          [self.buildPhases isKindOfClass:[NSArray class]])) {
        *error = makePBXError(@"Invalid %@ (buildPhases)",
                              NSStringFromClass([self class]));
        return NO;
    }
    
    for (id buildPhase in self.buildPhases) {
        if ([buildPhase isKindOfClass:[PBXSourcesBuildPhase class]]) {
            PBXSourcesBuildPhase *sourceBuildPhase = buildPhase;
            if (![sourceBuildPhase isValid:error]) {
                return NO;
            }
        } else if ([buildPhase isKindOfClass:[PBXResourcesBuildPhase class]]) {
            PBXResourcesBuildPhase *resourceBuildPhase = buildPhase;
            if (![resourceBuildPhase isValid:error]) {
                return NO;
            }
        } else {
            *error = makePBXError(@"Invalid %@ (buildConfigurationList)",
                                  NSStringFromClass([self class]));
            return NO;
        }
    }
    
    return YES;
}

- (NSArray *)configurationNames {
    NSMutableArray *names = [NSMutableArray array];
    
    for (XCBuildConfiguration *buildConfig in self.buildConfigurationList.buildConfigurations) {
        [names addObject:buildConfig.name];
    }
    
    return names;
}

- (XCBuildConfiguration *)configurationNamed:(NSString *)buildConfigName {
    for (XCBuildConfiguration *buildConfig in self.buildConfigurationList.buildConfigurations) {
        if ([buildConfig.name isEqualToString:buildConfigName]) {
            return buildConfig;
        }
    }
    
    return nil;
}

@end


@implementation XCBuildConfiguration
@synthesize name = _name;
@synthesize baseConfigurationReference = _baseConfigurationReference;
@synthesize buildSettings = _buildSettings;
@synthesize parent = _parent;
@synthesize project = _project;

@synthesize baseConfiguration = _baseConfiguration;

- (void)dealloc {
    self.name = nil;
    self.baseConfigurationReference = nil;
    self.buildSettings = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (!(self.buildSettings &&
          [self.buildSettings isKindOfClass:[NSDictionary class]])) {
        *error = makePBXError(@"Invalid %@ (buildSettings)",
                              NSStringFromClass([self class]));
        return NO;
    }
    
    if (!(!self.baseConfigurationReference ||
          [self.baseConfigurationReference isKindOfClass:[PBXFileReference class]])) {
        *error = makePBXError(@"Invalid %@ (baseConfigurationReference)",
                              NSStringFromClass([self class]));
        return NO;
    }
    
    return YES;
}

- (BOOL)prepareBaseConfiguration:(NSError **)error {
    
    if (self.baseConfigurationReference) {
        self.baseConfiguration = [XCConfigParser
                                  dictionaryFromFile:[self.baseConfigurationReference buildPath]
                                  error:error];
        if (self.baseConfiguration == nil) {
            NSNumber *lineNumber = [[*error userInfo] objectForKey:XCConfigParserLineNumberKey];
            *error = makePBXError(@"%@:%@ %@",
                                  [[*error userInfo] objectForKey:XCConfigParserFileKey] ?:
                                  [self.baseConfigurationReference name],
                                  lineNumber ? [NSString stringWithFormat:@"%@:", lineNumber] : @"",
                                  [*error localizedDescription]);
            
            return NO;
        }
    }
    
    if (self.parent &&
        ![self.parent prepareBaseConfiguration:error]) {
        return NO;
    }
    
    return YES;
}

- (id)resolveConfigValueNamed:(NSString *)configName {
    NSString *value = nil;
    
    if ([self.buildSettings objectForKey:configName]) {
        value = [self.buildSettings objectForKey:configName];
    } else if (self.baseConfiguration &&
               [self.baseConfiguration objectForKey:configName]) {
        value = [self.baseConfiguration objectForKey:configName];
    }
    
    if (value != nil) {
        return [value
                pbx_stringByReplacingVariablesNestedUsingBlock:
                ^NSString *(NSString *variableName) {
                    // TODO: lookup in build config first?
                    return [self.project lookupEnvironmentName:variableName];
                }];
    } else if (self.parent != nil) {
        return [self.parent resolveConfigValueNamed:configName];
    }
    
    return nil;
}

- (NSArray *)resolveConfigPathsNamed:(NSString *)configName
               usingWorkingDirectory:(NSString *)workingDirectory {
    NSMutableOrderedSet *paths = [NSMutableOrderedSet orderedSet];
    
    NSArray *templatePaths = [self.buildSettings objectForKey:configName];
    if (templatePaths == nil) {
        if (self.parent != nil) {
            return [self.parent resolveConfigPathsNamed:configName
                                  usingWorkingDirectory:workingDirectory];
        }
        
        return [NSArray array];
    }
    
    // convert string to array with string
    if ([templatePaths isKindOfClass:[NSString class]]) {
        templatePaths = [NSArray arrayWithObject:templatePaths];
    }
    
    for (NSString *templatePath in templatePaths) {
        if ([[templatePath stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"$(inherited)"]) {
            if (self.parent != nil) {
                [paths addObjectsFromArray:[self.parent resolveConfigPathsNamed:configName
                                                          usingWorkingDirectory:workingDirectory]];
            }
        } else {
            NSString *path = [[templatePath
                               pbx_stringByReplacingVariablesNestedUsingBlock:
                               ^NSString *(NSString *variableName) {
                                   return [self.project lookupEnvironmentName:variableName];
                               }]
                              pbx_stringByStandardizingAbsolutePath:workingDirectory];
            
            // ending with "/**" means recursive path
            if ([[path lastPathComponent] isEqualToString:@"**"]) {
                NSString *recursePath = [path stringByDeletingLastPathComponent];
                [paths addObject:recursePath];
                // uses subpathsAtPath instead of subpathsOfDirectoryAtPath as it
                // does not traverse if path is a symlink (unless you add a "/" to the path)
                NSArray *subpaths = [[NSFileManager defaultManager] subpathsAtPath:recursePath];
                if (subpaths != nil) {
                    for (NSString *subpath in subpaths) {
                        BOOL isDir = NO;
                        NSString *absSubpath = [recursePath stringByAppendingPathComponent:subpath];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:absSubpath
                                                                 isDirectory:&isDir] &&
                            isDir) {
                            [paths addObject:absSubpath];
                        }
                    }
                }
            } else {
                [paths addObject:path];
            }
        }
    }
    
    return [paths array];
}

@end


@implementation XCConfigurationList
@synthesize buildConfigurations = _buildConfigurations;

- (void)dealloc {
    self.buildConfigurations = nil;
    
    [super dealloc];
}

- (BOOL)isValid:(NSError **)error {
    if (!(self.buildConfigurations &&
          [self.buildConfigurations isKindOfClass:[NSArray class]])) {
        *error = makePBXError(@"Invalid %@ (buildConfigurations)",
                              NSStringFromClass([self class]));
        return NO;
    }
    
    for (XCBuildConfiguration *buildConfiguration in self.buildConfigurations) {
        if (!([buildConfiguration isKindOfClass:[XCBuildConfiguration class]] &&
              [buildConfiguration isValid:error])) {
            *error = *error ?: makePBXError(@"Invalid %@ (buildConfiguration)",
                                            NSStringFromClass([self class]));
            return NO;
        }
    }
    
    return YES;
}
@end


@implementation PBXProject
@synthesize buildConfigurationList = _buildConfigurationList;
@synthesize targets = _targets;
@synthesize knownRegions = _knownRegions;
@synthesize mainGroup = _mainGroup;
@synthesize environment = _environment;
@synthesize pbxFilePath = _pbxFilePath;

@synthesize fallbackEnvironment = _fallbackEnvironment;

+ (PBXProject *)pbxProjectFromPath:(NSString *)path
                             error:(NSError **)error {
    error = error ?: &(NSError *){nil};
    
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path
                                             isDirectory:&isDir] &&
        isDir) {
        // project dir + project.pbxproj
        path = [path stringByAppendingPathComponent:@"project.pbxproj"];
    }
    
    path = [path pbx_stringByStandardizingAbsolutePath:
            [[NSFileManager defaultManager] currentDirectoryPath]];
    
    PBXUnarchiver *pbxUnarchiver = [[[PBXUnarchiver alloc] initWithFile:path]
                                    autorelease];
    if (pbxUnarchiver == nil) {
        *error = *error ?: makePBXError(@"Could not open pbxproj file");
        return nil;
    }
    pbxUnarchiver.allowedClasses = [NSSet setWithObjects:
                                    [XCConfigurationList class],
                                    [XCBuildConfiguration  class],
                                    [PBXProject class],
                                    [PBXNativeTarget class],
                                    [PBXSourcesBuildPhase class],
                                    [PBXResourcesBuildPhase class],
                                    [PBXBuildFile class],
                                    [PBXFileReference class],
                                    [PBXGroup class],
                                    [PBXVariantGroup class],
                                    nil];
    
    PBXProject *pbxProject = [pbxUnarchiver decodeObject];
    if (!(pbxProject &&
          [pbxProject isKindOfClass:[PBXProject class]] &&
          [pbxProject isValid:error])) {
        *error = *error ?: makePBXError(@"Invalid PBXProject");
        return nil;
    }
    
    [pbxProject.mainGroup recursivelySetParent:pbxProject andProject:pbxProject];
    
    // TODO: connect pbxProject.buildConfigurationList.buildConfigurations[*].parent
    
    // set project for build configurations
    for (XCBuildConfiguration *projectBuildConfiguration in
         pbxProject.buildConfigurationList.buildConfigurations) {
        projectBuildConfiguration.project = pbxProject;
    }
    for (PBXNativeTarget *nativeTarget in pbxProject.targets) {
        for (XCBuildConfiguration *targetBuildConfiguration in
             nativeTarget.buildConfigurationList.buildConfigurations) {
            targetBuildConfiguration.project = pbxProject;
        }
    }
    
    // connect target and project build configurations
    for (XCBuildConfiguration *projectBuildConfiguration in
         pbxProject.buildConfigurationList.buildConfigurations) {
        for (PBXNativeTarget *nativeTarget in pbxProject.targets) {
            for (XCBuildConfiguration *targetBuildConfiguration in
                 nativeTarget.buildConfigurationList.buildConfigurations) {
                if (![projectBuildConfiguration.name
                      isEqualToString:targetBuildConfiguration.name]) {
                    continue;
                }
                
                targetBuildConfiguration.parent = projectBuildConfiguration;
            }
        }
    }
    
    pbxProject.pbxFilePath = path;
    
    return pbxProject;
}

- (void)dealloc {
    self.buildConfigurationList = nil;
    self.targets = nil;
    self.knownRegions = nil;
    self.mainGroup = nil;
    self.environment = nil;
    self.pbxFilePath = nil;
    self.fallbackEnvironment = nil;
    
    [super dealloc];
}

- (BOOL)prepareWithEnvironment:(NSDictionary *)environment
                  nativeTarget:(PBXNativeTarget *)nativeTarget
            buildConfiguration:(XCBuildConfiguration *)buildConfiguration
                         error:(NSError **)error {
    self.environment = environment;
    self.fallbackEnvironment = [self buildFallbackEnvironmentWithTarget:nativeTarget
                                                     buildConfiguration:buildConfiguration];
    
    
    if (![buildConfiguration prepareBaseConfiguration:error]) {
        return NO;
    }
    
    return YES;
}

- (NSDictionary *)buildFallbackEnvironmentWithTarget:(PBXNativeTarget *)target
                                  buildConfiguration:(XCBuildConfiguration *)buildConfiguration {
    NSString *sourceRoot = [[self.pbxFilePath
                             stringByDeletingLastPathComponent]
                            stringByDeletingLastPathComponent];
    
    // TODO: lookup more things from Xcode somehow? based on SDKROOT etc
    // http://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html
    
    // paths below as just guesses when not running in a Xcode run script environment.
    // Hopefully they are mostly used to resovle relative paths so they don't need
    // to be exactly right
    return [NSDictionary dictionaryWithObjectsAndKeys:
            sourceRoot,
            @"SOURCE_ROOT",
            [NSString pathWithComponents:
             [NSArray arrayWithObjects:sourceRoot, @"build", @"dummy", nil]],
            @"BUILT_PRODUCTS_DIR",
            @"/Applications/Xcode.app/Contents/Developer",
            @"DEVELOPER_DIR",
            @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk",
            @"SDKROOT",
            target.name,
            @"TARGET_NAME",
            buildConfiguration.name,
            @"CONFIGURATION",
            self.pbxFilePath,
            @"PROJECT_FILE_PATH",
            nil];
}

- (NSString *)buildPath {
    // TODO: project dir
    return [self pathForSourceTree:@"SOURCE_ROOT"];
}

- (BOOL)isValid:(NSError **)error {
    if (!(self.buildConfigurationList &&
          [self.buildConfigurationList isKindOfClass:[XCConfigurationList class]] &&
          self.targets &&
          [self.targets isKindOfClass:[NSArray class]] &&
          self.knownRegions &&
          [self.targets isKindOfClass:[NSArray class]] &&
          self.mainGroup &&
          [self.mainGroup isKindOfClass:[PBXGroup class]])) {
        *error = makePBXError(@"Invalid %@", NSStringFromClass([self class]));
        return NO;
    }
    
    if (![self.buildConfigurationList isValid:error]) {
        return NO;
    }
    
    for (PBXNativeTarget *target in self.targets) {
        if (!([target isKindOfClass:[PBXNativeTarget class]] &&
              target.name)) {
            *error = makePBXError(@"Invalid %@ (target)",
                                  NSStringFromClass([self class]));
            return NO;;
        }
        
        if (![target isValid:error]) {
            return NO;
        }
    }
    
    for (NSString *knownRegion in self.knownRegions) {
        if (![knownRegion isKindOfClass:[NSString class]]) {
            *error = makePBXError(@"Invalid %@ (knownRegion)",
                                  NSStringFromClass([self class]));
            return NO;;
        }
    }
    
    if (![self.mainGroup isValid:error]) {
        return NO;
    }
    
    return YES;
}

- (NSString *)lookupEnvironmentName:(NSString *)name {
    if (self.environment != nil &&
        [self.environment objectForKey:name] != nil) {
        return [self.environment objectForKey:name];
    }
    
    if (self.fallbackEnvironment != nil &&
        [self.fallbackEnvironment objectForKey:name] != nil) {
        return [self.fallbackEnvironment objectForKey:name];
    }
    
    return nil;
}

- (NSString *)pathForSourceTree:(NSString *)sourceTree {
    if ([sourceTree isEqualToString:@"<absolute>"]) {
        return @"/";
    }
    
    return [self lookupEnvironmentName:sourceTree];
}

- (NSString *)projectName {
    NSArray *components = [self.pbxFilePath pathComponents];
    if ([components count] > 1) {
        // "path/to/projectName/project.pbxproj" -> "projectName"
        return [[components objectAtIndex:[components count] - 2]
                stringByDeletingPathExtension];
    } else {
        return self.pbxFilePath;
    }
}

- (NSString *)projectPath {
    return [self.pbxFilePath stringByDeletingLastPathComponent];
}

- (NSString *)sourceRoot {
    return [self pathForSourceTree:@"SOURCE_ROOT"];
}

- (NSArray *)nativeTargetNames {
    NSMutableArray *names = [NSMutableArray array];
    
    for (PBXNativeTarget *target in self.targets) {
        [names addObject:target.name];
    }
    
    return names;
}

- (NSArray *)nativeTargets {
    NSMutableArray *targets = [NSMutableArray array];
    
    for (PBXNativeTarget *target in self.targets) {
        [targets addObject:target];
    }
    
    return targets;
}

- (PBXNativeTarget *)nativeTargetNamed:(NSString *)targetName {
    for (PBXNativeTarget *target in self.targets) {
        if ([target.name isEqualToString:targetName]) {
            return target;
        }
    }
    
    return nil;
}

@end
