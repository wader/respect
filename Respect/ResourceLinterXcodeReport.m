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

#import "ResourceLinterXcodeReport.h"
#import "LintError.h"
#import "ConfigError.h"
#import "ResourceReference.h"
#import "BundleResource.h"
#import "LintWarning.h"

static NSComparator pathStringComparator = ^NSComparisonResult(id a, id b) {
    return [a compare:b options:NSCaseInsensitiveSearch|NSNumericSearch];
};

@interface ResourceLinterXcodeReport ()
@property(nonatomic, strong, readwrite) NSMutableDictionary *fileIssues;

- (void)addIssue:(id)issue forFile:(NSString *)file;
- (void)addXcodeWarning:(NSString *)file
           textLocation:(TextLocation)textLocation
                 format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);
@end

@implementation ResourceLinterXcodeReport

- (id)initWithLinter:(ResourceLinter *)linter {
    self = [super initWithLinter:linter];
    if (self == nil) {
        return nil;
    }

    // Xcode run script warning/error messages seems to need to be
    // grouped per file to work properly so collect issues per file.

    self.fileIssues = [NSMutableDictionary dictionary];

    for (LintError *lintError in linter.lintErrors) {
        [self addIssue:lintError forFile:lintError.file];
    }

    for (ConfigError *configError in linter.configErrors) {
        [self addIssue:configError forFile:configError.file];
    }

    for (ResourceReference *resourceRef in linter.missingReferences) {
        [self addIssue:resourceRef forFile:resourceRef.resourcePath];
    }

    for (BundleResource *bundleRes in linter.unusedResources) {
        [self addIssue:bundleRes forFile:bundleRes.buildSourcePath];
    }

    for (LintWarning *lintWarning in linter.lintWarnings) {
        [self addIssue:lintWarning forFile:lintWarning.file];
    }

    for (NSString *file in [(self.fileIssues).allKeys
                            sortedArrayUsingComparator:pathStringComparator]) {
        for (id issue in self.fileIssues[file]) {
            if ([issue isKindOfClass:[ResourceReference class]]) {
                ResourceReference *resourceRef = issue;

                [self addXcodeWarning:resourceRef.referencePath
                         textLocation:resourceRef.referenceLocation
                               format:
                 @"Missing resource \"%@\"%@%@",
                 resourceRef.resourcePath,
                 resourceRef.missingResourceHint == nil ? @"" :
                 [NSString stringWithFormat:@", did you mean \"%@\"?",
                  resourceRef.missingResourceHint],
                 resourceRef.referenceHint == nil ? @"" :
                 [NSString stringWithFormat:@" (%@)", resourceRef.referenceHint]];
            } else if ([issue isKindOfClass:[BundleResource class]]) {
                BundleResource *bundleRes = issue;
                [self addXcodeWarning:bundleRes.buildSourcePath
                         textLocation:MakeTextLineLocation(1)
                               format:
                 @"Unused resource \"%@\"",
                 bundleRes.path];
            } else if ([issue isKindOfClass:[LintWarning class]]) {
                LintWarning *lintWarning = issue;
                [self addXcodeWarning:lintWarning.file
                         textLocation:lintWarning.textLocation
                               format:@"%@", lintWarning.message];
            } else if ([issue isKindOfClass:[ConfigError class]]) {
                ConfigError *configError = issue;
                [self addXcodeWarning:configError.file
                         textLocation:configError.textLocation
                               format:@"%@", configError.message];
            } else if ([issue isKindOfClass:[LintError class]]) {
                LintError *lintError = issue;
                [self addXcodeWarning:lintError.file
                         textLocation:lintError.textLocation
                               format:@"%@", lintError.message];
            } else {
                NSAssert(0, @"");
            }
        }
    }

    return self;
}


- (void)addIssue:(id)issue forFile:(NSString *)file {
    NSMutableArray *issues = self.fileIssues[file];
    if (issues == nil) {
        issues = [NSMutableArray array];
        self.fileIssues[file] = issues;
    }

    [issues addObject:issue];
}

- (void)addXcodeWarning:(NSString *)file
           textLocation:(TextLocation)textLocation
                 format:(NSString *)format, ... {
    va_list va;
    va_start(va, format);
    [self addLine:[NSString stringWithFormat:@"%@:%@: warning: %@",
                   file, NSStringFromTextLocation(textLocation), format]
        arguments:va];
    va_end(va);
}

@end
