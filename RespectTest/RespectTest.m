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

#import "RespectTest.h"
#import "ResourceLinter.h"
#import "ResourceReference.h"
#import "BundleResource.h"
#import "LintWarning.h"
#import "ConfigError.h"
#import "LintError.h"
#import "PBXProject.h"
#import "ResourceLinterXcodeProjectSource.h"
#import "ResourceLinterCliReport.h"
#import "ResourceLinterXcodeReport.h"
#import "ResourceLinterConfigReport.h"
#import "NSString+Respect.h"

static BOOL test(NSString *path) {
    BOOL success = YES;
    PBXProject *pbxProject = [PBXProject pbxProjectFromPath:path environment:nil];
    
    for (PBXNativeTarget *nativeTarget in pbxProject.targets) {
        if (![nativeTarget.name hasPrefix:@"Test"]) {
            continue;
        }
        
        [SenTestLog testLogWithFormat:@"Testing target %@\n", nativeTarget.name];
        
        id<ResourceLinterSource> linterSource = [[[ResourceLinterXcodeProjectSource alloc]
                                                  initWithPBXProject:pbxProject
                                                  targetName:nativeTarget.name
                                                  configurationName:[[nativeTarget configurationNames]
                                                                     objectAtIndex:0]]
                                                 autorelease];
        ResourceLinter *linter = [[[ResourceLinter alloc]
                                   initWithResourceLinterSource:linterSource
                                   configPath:nil
                                   parseDefaultConfig:YES]
                                  autorelease];
        
        NSMutableSet *expectedUnused = [NSMutableSet set];
        NSMutableSet *expectedMissing = [NSMutableSet set];
        NSMutableDictionary *expectedWarnings = [NSMutableDictionary dictionary];
        NSMutableDictionary *expectedConfigErrors = [NSMutableDictionary dictionary];
        NSMutableDictionary *expectedLintErrors = [NSMutableDictionary dictionary];

        for (TextFile *sourceTextFile in [[linterSource sourceTextFiles] objectEnumerator]) {
            [[NSRegularExpression
              regularExpressionWithPattern:
              @"@Expected(Unused|Missing|Warning|ConfigError|LintError):(.*)"
              options:0
              error:NULL]
             enumerateMatchesInString:sourceTextFile.text
             options:0
             range:NSMakeRange(0, [sourceTextFile.text length])
             usingBlock:
             ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                 NSString *type = [[sourceTextFile.text substringWithRange:[result rangeAtIndex:1]]
                                   respect_stringByTrimmingWhitespace];
                 NSString *value = [[sourceTextFile.text substringWithRange:[result rangeAtIndex:2]]
                                    respect_stringByTrimmingWhitespace];
                 
                 if ([type isEqualToString:@"Unused"]) {
                     [expectedUnused addObject:value];
                 } else if ([type isEqualToString:@"Missing"]) {
                     [expectedMissing addObject:value];
                 } else if ([type isEqualToString:@"Warning"] ||
                            [type isEqualToString:@"ConfigError"] ||
                            [type isEqualToString:@"LintError"]) {
                     
                     NSRange colonRange = [value rangeOfString:@":"];
                     if (colonRange.location == NSNotFound) {
                         return;
                     }
                     
                     NSString *filename = [value substringToIndex:colonRange.location];
                     NSString *message = [[value substringFromIndex:colonRange.location+1]
                                          respect_stringByTrimmingWhitespace];
                     
                     NSMutableDictionary *const *fileIssues = nil;
                     if ([type isEqualToString:@"Warning"]) {
                         fileIssues = &expectedWarnings;
                     } else if ([type isEqualToString:@"ConfigError"]) {
                         fileIssues = &expectedConfigErrors;
                     } else if ([type isEqualToString:@"LintError"]) {
                         fileIssues = &expectedLintErrors;
                     } else {
                         NSCAssert(0, @"");
                     }
                     
                     NSMutableSet *issues = [(*fileIssues) objectForKey:filename];
                     if (issues == nil) {
                         issues = [NSMutableSet set];
                         [(*fileIssues) setObject:issues forKey:filename];
                     }
                     [issues addObject:message];
                 }
             }];
        }
        
        NSMutableSet *actualUnused = [NSMutableSet set];
        for (BundleResource *bundleRes in linter.unusedResources) {
            [actualUnused addObject:bundleRes.path];
        }
        
        NSMutableSet *actualMissing = [NSMutableSet set];
        for (ResourceReference *resourceRef in linter.missingReferences) {
            [actualMissing addObject:resourceRef.resourcePath];
        }
        
        NSMutableDictionary *actualWarnings = [NSMutableDictionary dictionary];
        for (LintWarning *lintWarning in linter.lintWarnings) {
            NSString *relativePath = [lintWarning.file respect_stringRelativeToPathPrefix:
                                      [linterSource sourceRoot]];
            
            NSMutableSet *warnings = [actualWarnings objectForKey:relativePath];
            if (warnings == nil) {
                warnings = [NSMutableSet set];
                [actualWarnings setObject:warnings forKey:relativePath];
            }
            [warnings addObject:lintWarning.message];
        }
        
        NSMutableDictionary *actualConfigErrors = [NSMutableDictionary dictionary];
        for (ConfigError *configError in linter.configErrors) {
            NSString *relativePath = [configError.file respect_stringRelativeToPathPrefix:
                                      [linterSource sourceRoot]];
            
            NSMutableSet *errors = [actualConfigErrors objectForKey:relativePath];
            if (errors == nil) {
                errors = [NSMutableSet set];
                [actualConfigErrors setObject:errors forKey:relativePath];
            }
            [errors addObject:configError.message];
        }
        
        NSMutableDictionary *actualLintErrors = [NSMutableDictionary dictionary];
        for (LintError *lintError in linter.lintErrors) {
            NSString *relativePath = [lintError.file respect_stringRelativeToPathPrefix:
                                      [linterSource sourceRoot]];
            
            NSMutableSet *errors = [actualLintErrors objectForKey:relativePath];
            if (errors == nil) {
                errors = [NSMutableSet set];
                [actualLintErrors setObject:errors forKey:relativePath];
            }
            [errors addObject:lintError.message];
        }
        
        if (![expectedUnused isEqualToSet:actualUnused]) {
            [SenTestLog testLogWithFormat:@"Expected unused:\n"];
            for (NSString *unused in expectedUnused) {
                [SenTestLog testLogWithFormat:@"  %@%@\n",
                 unused,
                 [actualUnused containsObject:unused] ? @"" : @" *"];
            }
            
            [SenTestLog testLogWithFormat:@"Actually unused:\n"];
            for (NSString *unused in actualUnused) {
                [SenTestLog testLogWithFormat:@"  %@%@\n",
                 unused,
                 [expectedUnused containsObject:unused] ? @"" : @" *"];
            }
        }
        
        if (![expectedMissing isEqualToSet:actualMissing]) {
            [SenTestLog testLogWithFormat:@"Expected missing:\n"];
            for (NSString *missing in expectedMissing) {
                [SenTestLog testLogWithFormat:@"  %@%@\n",
                 missing,
                 [actualMissing containsObject:missing] ? @"" : @" *"];
            }
            
            [SenTestLog testLogWithFormat:@"Actually missing:\n"];
            for (NSString *missing in actualMissing) {
                [SenTestLog testLogWithFormat:@"  %@%@\n",
                 missing,
                 [expectedMissing containsObject:missing] ? @"" : @" *"];
            }
        }
        
        if (![expectedWarnings isEqualToDictionary:actualWarnings]) {
            [SenTestLog testLogWithFormat:@"Expected warnings:\n"];
            for (NSString *resourcePath in expectedWarnings) {
                for (NSString *warning in [expectedWarnings objectForKey:resourcePath]) {
                    [SenTestLog testLogWithFormat:@"  %@: %@\n",
                     resourcePath, warning];
                }
            }
            [SenTestLog testLogWithFormat:@"Actual warnings:\n"];
            for (NSString *resourcePath in actualWarnings) {
                for (NSString *warning in [actualWarnings objectForKey:resourcePath]) {
                    [SenTestLog testLogWithFormat:@"  %@: %@\n",
                     resourcePath, warning];
                }
            }
        }
        
        if (![expectedConfigErrors isEqualToDictionary:actualConfigErrors]) {
            [SenTestLog testLogWithFormat:@"Expected config errors:\n"];
            for (NSString *resourcePath in expectedConfigErrors) {
                for (NSString *error in [expectedConfigErrors objectForKey:resourcePath]) {
                    [SenTestLog testLogWithFormat:@"  %@: %@\n",
                     resourcePath, error];
                }
            }
            [SenTestLog testLogWithFormat:@"Actual config errors:\n"];
            for (NSString *resourcePath in actualConfigErrors) {
                for (NSString *error in [actualConfigErrors objectForKey:resourcePath]) {
                    [SenTestLog testLogWithFormat:@"  %@: %@\n",
                     resourcePath, error];
                }
            }
        }
        
        if (![expectedLintErrors isEqualToDictionary:actualLintErrors]) {
            [SenTestLog testLogWithFormat:@"Expected lint errors:\n"];
            for (NSString *resourcePath in expectedLintErrors) {
                for (NSString *error in [expectedLintErrors objectForKey:resourcePath]) {
                    [SenTestLog testLogWithFormat:@"  %@: %@\n",
                     resourcePath, error];
                }
            }
            [SenTestLog testLogWithFormat:@"Actual lint errors:\n"];
            for (NSString *resourcePath in actualLintErrors) {
                for (NSString *error in [actualLintErrors objectForKey:resourcePath]) {
                    [SenTestLog testLogWithFormat:@"  %@: %@\n",
                     resourcePath, error];
                }
            }
        }
        
        // TODO: no tests for now but run and see that we dont crash at least
        for (Class reportClass in [NSArray arrayWithObjects:
                                   [ResourceLinterCliReport class],
                                   [ResourceLinterXcodeReport class],
                                   [ResourceLinterConfigReport class],
                                   nil]) {
            ResourceLinterAbstractReport *reporter = [[[reportClass alloc]
                                                       initWithLinter:linter]
                                                      autorelease];
            (void)reporter;
        }
        
        success &= ([expectedUnused isEqualToSet:actualUnused] &&
                    [expectedMissing isEqualToSet:actualMissing] &&
                    [expectedWarnings isEqualToDictionary:actualWarnings] &&
                    [expectedConfigErrors isEqualToDictionary:actualConfigErrors] &&
                    [expectedLintErrors isEqualToDictionary:actualLintErrors]);
        
    }
    
    return success;
}

@implementation RespectTest

- (void)testRespect {
    NSString *testsPath = [[NSBundle bundleForClass:[self class]] resourcePath];
    
    STAssertTrue(test([testsPath stringByAppendingPathComponent:@"RespectTestProject/RespectTestProject.xcodeproj"]), nil);
}

@end
