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

#import "ResourceLinterCliReport.h"
#import "LintError.h"
#import "ConfigError.h"
#import "ResourceReference.h"
#import "BundleResource.h"
#import "LintWarning.h"
#import "NSString+Respect.h"

@implementation ResourceLinterCliReport

- (id)initWithLinter:(ResourceLinter *)linter {
    self = [super initWithLinter:linter];
    if (self == nil) {
        return nil;
    }

    [self addLine:
     @"Report for project %@ target %@ using build configuration %@",
     [self.linter.linterSource projectName],
     [self.linter.linterSource targetName],
     [self.linter.linterSource configurationName]];

    if ((self.linter.lintErrors).count > 0) {
        [self addLine:@"Lint errors:"];
        for (LintError *lintError in self.linter.lintErrors) {
            [self addLine:
             @"  %@: %@",
             [lintError.file respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
             lintError.message];
        }
    }

    if ((self.linter.configErrors).count > 0) {
        [self addLine:@"Config errors:"];
        for (ConfigError *configError in self.linter.configErrors) {
            [self addLine:
             @"  %@:%ld: %@",
             [configError.file respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
             configError.textLocation.lineNumber,
             configError.message];
        }
    }

    if ((self.linter.missingReferences).count > 0) {
        [self addLine:@"Missing resources:"];
        for (ResourceReference *resourceRef in self.linter.missingReferences) {
            [self addLine:
             @"  %@%@%@: %@%@",
             [resourceRef.referencePath respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
             resourceRef.referenceLocation.lineNumber == 0 ? @"" :
             [NSString stringWithFormat:@":%ld", resourceRef.referenceLocation.lineNumber],
             resourceRef.referenceHint == nil ? @"" :
             [NSString stringWithFormat:@":%@", resourceRef.referenceHint],
             resourceRef.resourcePath,
             resourceRef.missingResourceHint == nil ? @"" :
             [NSString stringWithFormat:@" (did you mean %@?)",
              resourceRef.missingResourceHint]];
        }
    }

    if ((self.linter.unusedResources).count > 0) {
        [self addLine:@"Unused resources:"];
        for (BundleResource *bundleRes in self.linter.unusedResources) {
            [self addLine:@"  %@", bundleRes.path];
        }
    }

    if ((self.linter.lintWarnings).count > 0) {
        [self addLine:@"Resource warnings:"];
        for (LintWarning *lintWarning in self.linter.lintWarnings) {
            [self addLine:@"  %@%@: %@",
             [lintWarning.file respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
             lintWarning.textLocation.lineNumber == 0 ? @"" :
             [NSString stringWithFormat:@":%ld", lintWarning.textLocation.lineNumber],
             lintWarning.message];
        }
    }

    if ((self.linter.lintErrors).count +
        (self.linter.configErrors).count +
        (self.linter.missingReferences).count +
        (self.linter.unusedResources).count +
        (self.linter.lintWarnings).count > 0) {
        [self addLine:@""];
    } else {
        [self addLine:@"No issues found."];
    }

    [self addLine:@"%ld source files scanned",
     [self.linter.linterSource sourceTextFiles].count];
    [self addLine:@"%ld resources, %ld unused (%ld ignored)",
     (self.linter.bundleResources).count,
     (self.linter.unusedResources).count,
     (self.linter.unusedResourcesIgnored).count];
    [self addLine:@"%ld references, %ld missing (%ld ignored)",
     (self.linter.resourceReferences).count,
     (self.linter.missingReferences).count,
     (self.linter.missingReferencesIgnored).count];
    [self addLine:@"%ld errors (%ld ignored), %ld warnings (%ld ignored)",
     (self.linter.lintErrors).count,
     (self.linter.lintErrorsIgnored).count,
     (self.linter.lintWarnings).count,
     (self.linter.lintWarningsIgnored).count];
    
    return self;
}
@end
