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
#import "StaticMatch.h"
#import "SourceMatch.h"
#import "ResourceMatch.h"
#import "FileAction.h"
#import "ImageAction.h"
#import "NibAction.h"
#import "InfoPlistAction.h"
#import "WarningAction.h"
#import "ResourceReference.h"
#import "LintWarning.h"
#import "LintError.h"
#import "BundleResource.h"
#import "TextFile.h"
#import "IgnoreConfig.h"
#import "ConfigError.h"
#import "DefaultConfig.h"
#import "NSRegularExpression+lineNumber.h"
#import "NSString+Respect.h"

#import "PCRegularExpression.h"


static NSString * const RespectDefaultProjectConfigName = @".respect";

static NSComparator resourceReferenceComparator = ^NSComparisonResult(id a, id b) {
    ResourceReference *aRef = a;
    ResourceReference *bRef = b;
    NSComparisonResult r = [aRef.referencePath compare:bRef.referencePath
                                               options:NSCaseInsensitiveSearch|NSNumericSearch];
    if (r == NSOrderedSame) {
        r = aRef.referenceLocation.lineNumber - bRef.referenceLocation.lineNumber;
    }
    
    if (r == NSOrderedSame && aRef.referenceHint != nil && bRef.referenceHint != nil) {
        r = [aRef.referenceHint compare:bRef.referenceHint
                                options:NSCaseInsensitiveSearch|NSNumericSearch];
    }
    
    if (r == NSOrderedSame) {
        r = aRef.referenceLocation.inLineRange.location - bRef.referenceLocation.inLineRange.location;
    }
    
    if (r == NSOrderedSame) {
        r = [aRef.resourcePath compare:bRef.resourcePath
                               options:NSCaseInsensitiveSearch|NSNumericSearch];
    }
    
    return r;
};

static NSComparator bundleResourceComparator = ^NSComparisonResult(id a, id b) {
    BundleResource *aRes = a;
    BundleResource *bRes = b;
    return [aRes.path compare:bRes.path
                      options:NSCaseInsensitiveSearch|NSNumericSearch];
    
};

static NSComparator lintWarningComparator = ^NSComparisonResult(id a, id b) {
    LintWarning *aWarn = a;
    LintWarning *bWarn = b;
    return [aWarn.file compare:bWarn.file
                       options:NSCaseInsensitiveSearch|NSNumericSearch];
};

static NSComparator fileSourcedErrorComparator = ^NSComparisonResult(id a, id b) {
    TextFileError *aError = a;
    TextFileError *bError = b;
    return [aError.file compare:bError.file
                        options:NSCaseInsensitiveSearch|NSNumericSearch];
    
};


@interface ResourceLinter ()
@property(nonatomic, copy, readwrite) NSString *configPath;
@property(nonatomic, assign, readwrite) BOOL parseDefaultConfig;
@property(nonatomic, retain, readwrite) StaticMatch *staticMatcher;

@property(nonatomic, retain, readwrite) id<ResourceLinterSource> linterSource;
@property(nonatomic, retain, readwrite) NSMutableArray *defaultConfigs;
@property(nonatomic, retain, readwrite) NSMutableArray *matchers;
@property(nonatomic, retain, readwrite) NSMutableDictionary *bundleResources;
@property(nonatomic, retain, readwrite) NSMutableDictionary *lowercaseBundleResources;
@property(nonatomic, retain, readwrite) NSMutableSet *resourceReferences;
@property(nonatomic, retain, readwrite) NSMutableArray *missingReferences;
@property(nonatomic, retain, readwrite) NSMutableArray *missingReferencesIgnored;
@property(nonatomic, retain, readwrite) NSMutableArray *unusedResources;
@property(nonatomic, retain, readwrite) NSMutableArray *unusedResourcesIgnored;
@property(nonatomic, retain, readwrite) NSMutableArray *lintWarnings;
@property(nonatomic, retain, readwrite) NSMutableArray *lintWarningsIgnored;
@property(nonatomic, retain, readwrite) NSMutableArray *lintErrors;
@property(nonatomic, retain, readwrite) NSMutableArray *lintErrorsIgnored;
@property(nonatomic, retain, readwrite) NSMutableArray *configErrors;
@property(nonatomic, retain, readwrite) NSMutableArray *unusedIgnoreConfigs;
@property(nonatomic, retain, readwrite) NSMutableArray *missingIgnoreConfigs;
@property(nonatomic, retain, readwrite) NSMutableArray *warningIgnoreConfigs;
@property(nonatomic, retain, readwrite) NSMutableArray *errorIgnoreConfigs;
@end

@implementation ResourceLinter
@synthesize configPath = _configPath;
@synthesize parseDefaultConfig = _parseDefaultConfig;
@synthesize staticMatcher = _staticMatcher;

@synthesize linterSource = _linterSource;
@synthesize defaultConfigs = _defaultConfigs;
@synthesize matchers = _matchers;
@synthesize bundleResources = _bundleResources;
@synthesize lowercaseBundleResources = _lowercaseBundleResources;
@synthesize resourceReferences = _resourceReferences;
@synthesize missingReferences = _missingReferences;
@synthesize missingReferencesIgnored = _missingReferencesIgnored;
@synthesize unusedResources = _unusedResources;
@synthesize unusedResourcesIgnored = _unusedResourcesIgnored;
@synthesize lintWarnings = _lintWarnings;
@synthesize lintWarningsIgnored = _lintWarningsIgnored;
@synthesize lintErrors = _lintErrors;
@synthesize lintErrorsIgnored = _lintErrorsIgnored;
@synthesize configErrors = _configErrors;
@synthesize unusedIgnoreConfigs = _unusedIgnoreConfigs;
@synthesize missingIgnoreConfigs = _missingIgnoreConfigs;
@synthesize warningIgnoreConfigs = _warningIgnoreConfigs;
@synthesize errorIgnoreConfigs = _errorIgnoreConfigs;

- (id)initWithResourceLinterSource:(id<ResourceLinterSource>)linterSource
                        configPath:(NSString *)configPath
                parseDefaultConfig:(BOOL)parseDefaultConfig {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.linterSource = linterSource;
    
    self.configPath = configPath;
    self.parseDefaultConfig = parseDefaultConfig;
    self.staticMatcher = [[[StaticMatch alloc] initWithLinter:self] autorelease];
    
    self.defaultConfigs = [NSMutableArray array];
    self.matchers = [NSMutableArray array];
    self.bundleResources = [NSMutableDictionary dictionary];
    self.lowercaseBundleResources = [NSMutableDictionary dictionary];
    self.resourceReferences = [NSMutableSet set];
    self.missingReferences = [NSMutableArray array];
    self.missingReferencesIgnored = [NSMutableArray array];
    self.unusedResources = [NSMutableArray array];
    self.unusedResourcesIgnored = [NSMutableArray array];
    self.lintWarnings = [NSMutableArray array];
    self.lintWarningsIgnored = [NSMutableArray array];
    self.lintErrors = [NSMutableArray array];
    self.lintErrorsIgnored = [NSMutableArray array];
    self.configErrors = [NSMutableArray array];
    self.unusedIgnoreConfigs = [NSMutableArray array];
    self.missingIgnoreConfigs = [NSMutableArray array];
    self.warningIgnoreConfigs = [NSMutableArray array];
    self.errorIgnoreConfigs = [NSMutableArray array];
    
    // used for actions not associated with any matcher
    [self.matchers addObject:self.staticMatcher];
    
    [self lint];
    
    return self;
}

- (void)dealloc {
    self.configPath = nil;
    self.staticMatcher = nil;
    
    self.defaultConfigs = nil;
    self.linterSource = nil;
    self.matchers = nil;
    self.bundleResources = nil;
    self.lowercaseBundleResources = nil;
    self.resourceReferences = nil;
    self.missingReferences = nil;
    self.missingReferencesIgnored = nil;
    self.unusedResources = nil;
    self.unusedResourcesIgnored = nil;
    self.lintWarnings = nil;
    self.lintWarningsIgnored = nil;
    self.lintErrors = nil;
    self.lintErrorsIgnored = nil;
    self.configErrors = nil;
    self.unusedIgnoreConfigs = nil;
    self.missingIgnoreConfigs = nil;
    self.warningIgnoreConfigs = nil;
    self.errorIgnoreConfigs = nil;
    
    // TODO: references between objects in bundleReferences and referencesResources
    //       can cause circular references.
    //       Use non retain arrays in BundleResource and ResourceReference class?
    
    [super dealloc];
}

- (void)parseConfigInTextFile:(TextFile *)textFile
          isDefaultConfigFile:(BOOL)isDefaultConfigFile {
    static PCRegularExpression *re = nil;
    static NSDictionary *nameToClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nameToClass = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [SourceMatch class], [SourceMatch name],
                       [ResourceMatch class], [ResourceMatch name],
                       [FileAction class], [FileAction name],
                       [ImageAction class], [ImageAction name],
                       [NibAction class], [NibAction name],
                       [InfoPlistAction class], [InfoPlistAction name],
                       [WarningAction class], [WarningAction name],
                       [IgnoreConfig class], @"IgnoreMissing",
                       [IgnoreConfig class], @"IgnoreUnused",
                       [IgnoreConfig class], @"IgnoreWarning",
                       [IgnoreConfig class], @"IgnoreError",
                       nil];
        
        re = [[PCRegularExpression
               // capture group 1 is name
               // capture group 2 is "Default" optionally
               // capture group 3 is separator
               // capture group 4 is argument
               regularExpressionWithPattern:@"@Lint([A-Za-z]+?)(Default)?(:| )(.*+)"
               options:0
               error:NULL]
              retain];
    });
    
    __block AbstractMatch *currentMatcher = nil;
    __block NSUInteger prevConfigLine = 0;
    [re enumerateMatchesWithLineNumberInUTF8CString:textFile.textUtf8
                                     withByteLength:textFile.textUtf8ByteLength
                                            options:0
                                              range:NSMakeRange(0, [textFile.text length])
                                         lineRanges:textFile.lineRanges
                                         usingBlock:
     ^(NSTextCheckingResult *result, NSUInteger lineNumber, NSRange inLineRange,
       NSMatchingFlags flags, BOOL *stop) {
         TextLocation textLocation = MakeTextLocation(lineNumber, inLineRange);
         NSString *name = [textFile.text substringWithRange:[result rangeAtIndex:1]];
         BOOL isDefault = [result rangeAtIndex:2].location != NSNotFound;
         NSString *separator = [textFile.text substringWithRange:[result rangeAtIndex:3]];
         NSString *argument = [[textFile.text substringWithRange:[result rangeAtIndex:4]]
                               respect_stringByTrimmingWhitespace];
         
         if (![separator isEqualToString:@":"]) {
             NSString *message = [NSString stringWithFormat:
                                  @"Missing colon, did you mean @Lint%@: %@?",
                                  name, argument];
             [self.configErrors addObject:
              [ConfigError configErrorWithFile:textFile.path
                                  textLocation:textLocation
                                       message:message]];
             return;
         }
         
         Class nameClass = [nameToClass objectForKey:name];
         if (nameClass != nil) {
             if (isDefault) {
                 id defaultValue = nil;
                 NSString *errorMessage = nil;
                 defaultValue = [nameClass defaultConfigValueFromArgument:argument
                                                             errorMessage:&errorMessage];
                 
                 [self.defaultConfigs addObject:[DefaultConfig
                                                 defaultWithLinter:self
                                                 file:textFile.path
                                                 textLocation:textLocation
                                                 name:name
                                                 argumentString:argument
                                                 configValue:defaultValue
                                                 errorMessage:errorMessage]];
             } else {
                 id nameObject = [nameClass alloc];
                 
                 if ([nameObject isKindOfClass:[AbstractMatch class]]) {
                     currentMatcher = [[nameObject
                                        initWithLinter:self
                                        file:textFile.path
                                        textLocation:textLocation
                                        argumentString:argument
                                        isDefaultConfig:isDefaultConfigFile]
                                       autorelease];
                     [self.matchers addObject:currentMatcher];
                 } else if ([nameObject isKindOfClass:[AbstractAction class]]) {
                     AbstractAction *action = [[nameObject
                                                initWithLinter:self
                                                file:textFile.path
                                                textLocation:textLocation
                                                argumentString:argument
                                                isDefaultConfig:isDefaultConfigFile]
                                               autorelease];
                     
                     // if no current matcher or current line is not directly
                     // after a matcher or action line then add as static
                     if (currentMatcher == nil || prevConfigLine != lineNumber-1) {
                         currentMatcher = nil;
                         [self.staticMatcher addAction:action];
                     } else {
                         [currentMatcher addAction:action];
                     }
                 } else {
                     IgnoreConfig *ignoreConfig = [[nameObject
                                                    initWithLinter:self
                                                    file:textFile.path
                                                    textLocation:textLocation
                                                    type:name
                                                    argumentString:argument]
                                                   autorelease];
                     if ([name isEqualToString:@"IgnoreMissing"]) {
                         [self.missingIgnoreConfigs addObject:ignoreConfig];
                     } else if ([name isEqualToString:@"IgnoreUnused"]) {
                         [self.unusedIgnoreConfigs addObject:ignoreConfig];
                     } else if ([name isEqualToString:@"IgnoreWarning"]) {
                         [self.warningIgnoreConfigs addObject:ignoreConfig];
                     } else if ([name isEqualToString:@"IgnoreError"]) {
                         [self.errorIgnoreConfigs addObject:ignoreConfig];
                     } else {
                         NSAssert(0, @"");
                     }
                 }
             }
         } else {
             NSString *suggestedName = [name respect_stringBySuggestionFromArray:[nameToClass allKeys]
                                                            maxDistanceThreshold:3];
             NSString *message = (suggestedName ?
                                  [NSString stringWithFormat:
                                   @"Did you mean @Lint%@?", suggestedName] :
                                  [NSString stringWithFormat:
                                   @"Unknown config @Lint%@", name]);
             [self.configErrors addObject:
              [ConfigError configErrorWithFile:textFile.path
                                  textLocation:textLocation
                                       message:message]];
         }
         
         prevConfigLine = lineNumber;
     }];
}

+ (BOOL)matchesSomeIgnoreConfig:(NSArray *)ignoreConfigs
                    usingString:(NSString *)string {
    for (IgnoreConfig *ignoreConfig in ignoreConfigs) {
        if ([ignoreConfig matchesString:string]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)parseConfig {
    TextFile *configTextFile = nil;
    
    if (self.configPath == nil) {
        configTextFile = [TextFile textFileWithContentOfFile:
                          [[self.linterSource sourceRoot]
                           stringByAppendingPathComponent:RespectDefaultProjectConfigName]];
        if (configTextFile == nil) {
            // project config file is optional
            return;
        }
    } else {
        configTextFile = [TextFile textFileWithContentOfFile:self.configPath];
    }
    
    if (configTextFile == nil) {
        // give error if fail to read specified project config
        [self.lintErrors addObject:
         [LintError lintErrorWithFile:self.configPath
                              message:@"Failed to read config file"]];
        return;
    }
    
    [self parseConfigInTextFile:configTextFile isDefaultConfigFile:NO];
}

- (void)lint {
    NSDictionary *resources = [self.linterSource resources];
    
    // add all bundle resources
    for (NSString *bundlePath in resources) {
        BundleResource *bundleRes = [[[BundleResource alloc]
                                      initWithBuildSourcePath:[resources objectForKey:bundlePath]
                                      path:bundlePath]
                                     autorelease];
        
        [self.bundleResources setObject:bundleRes forKey:bundlePath];
        [self.lowercaseBundleResources setObject:bundleRes
                                          forKey:[bundlePath lowercaseString]];
    }
    
    // find matchers, actions and ignore config
    if (self.parseDefaultConfig) {
        [self parseConfigInTextFile:[self.linterSource defaultConfigTextFile]
                isDefaultConfigFile:YES];
    }
    
    [self parseConfig];
    
    for (TextFile *sourceTextFile in [[self.linterSource sourceTextFiles]
                                      objectEnumerator]) {
        [self parseConfigInTextFile:sourceTextFile isDefaultConfigFile:NO];
    }
    
    // run matchers and trigger actions
    for (AbstractMatch *matcher in self.matchers) {
        [matcher performMatch];
    }
    
    // collect missing references
    for (ResourceReference *resourceRef in self.resourceReferences) {
        if ([resourceRef.bundleResources count] > 0) {
            continue;
        }
        
        if ([[self class] matchesSomeIgnoreConfig:self.missingIgnoreConfigs
                                      usingString:resourceRef.resourcePath]) {
            [self.missingReferencesIgnored addObject:resourceRef];
        } else {
            [self.missingReferences addObject:resourceRef];
        }
    }
    [self.missingReferences sortUsingComparator:resourceReferenceComparator];
    [self.missingReferencesIgnored sortUsingComparator:resourceReferenceComparator];
    
    // collect unused resources
    for (BundleResource *bundleRes in [self.bundleResources objectEnumerator]) {
        if ([bundleRes.resourceReferences count] > 0) {
            continue;
        }
        
        if ([[self class] matchesSomeIgnoreConfig:self.unusedIgnoreConfigs
                                      usingString:bundleRes.path]) {
            [self.unusedResourcesIgnored addObject:bundleRes];
        } else {
            [self.unusedResources addObject:bundleRes];
        }
    }
    [self.unusedResources sortUsingComparator:bundleResourceComparator];
    [self.unusedResourcesIgnored sortUsingComparator:bundleResourceComparator];
    
    // move ignored errors and warnings into *Ignored array
    
    // add lint warnings from source
    [self.lintWarnings addObjectsFromArray:[self.linterSource lintWarnings]];
    for (LintWarning *lintWarning in self.lintWarnings) {
        if ([[self class]
             matchesSomeIgnoreConfig:self.warningIgnoreConfigs
             usingString:[lintWarning.file respect_stringRelativeToPathPrefix:
                          [self.linterSource sourceRoot]]]) {
                 [self.lintWarningsIgnored addObject:lintWarning];
             }
    }
    [self.lintWarnings removeObjectsInArray:self.lintWarningsIgnored];
    [self.lintWarnings sortUsingComparator:lintWarningComparator];
    [self.lintWarningsIgnored sortUsingComparator:lintWarningComparator];
    
    // add lint errors from source
    [self.lintErrors addObjectsFromArray:[self.linterSource lintErrors]];
    for (LintError *lintError in self.lintErrors) {
        if ([[self class]
             matchesSomeIgnoreConfig:self.errorIgnoreConfigs
             usingString:[lintError.file respect_stringRelativeToPathPrefix:
                          [self.linterSource sourceRoot]]]) {
                 [self.lintErrorsIgnored addObject:lintError];
             }
    }
    [self.lintErrors removeObjectsInArray:self.lintErrorsIgnored];
    [self.lintErrors sortUsingComparator:fileSourcedErrorComparator];
    [self.lintErrorsIgnored sortUsingComparator:fileSourcedErrorComparator];
    
    [self.configErrors sortUsingComparator:fileSourcedErrorComparator];
}

- (id)defaultConfigValueForName:(NSString *)name {
    // last added has priority
    for (DefaultConfig *defaultConfig in [self.defaultConfigs reverseObjectEnumerator]) {
        if ([defaultConfig.name isEqualToString:name]) {
            return defaultConfig.configValue;
        }
    }
    
    return nil;
}

@end
