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

#import "ResourceLinterConfigReport.h"
#import "AbstractMatch.h"
#import "AbstractAction.h"
#import "IgnoreConfig.h"
#import "NSString+Respect.h"

// TODO: include used/missing/ignored refereces in output

@implementation ResourceLinterConfigReport

- (id)initWithLinter:(ResourceLinter *)linter {
    self = [super initWithLinter:linter];
    if (self == nil) {
        return nil;
    }
    
    [self addLine:
     @"// Interpreted config for %@ ",
     [self.linter.linterSource projectPath]];
    [self addLine:
     @"// Target %@ using build configuration %@",
     [self.linter.linterSource targetName],
     [self.linter.linterSource configurationName]];
    [self addLine:@""];
    
    // collect unique names and include config for last added per name
    for (NSString *defaultConfigName in
         [NSSet setWithArray:[self.linter.defaultConfigs valueForKey:@"name"]]) {
        
        for (DefaultConfig *defaultConfig in
             [self.linter.defaultConfigs reverseObjectEnumerator]) {
            if (![defaultConfig.name isEqualToString:defaultConfigName]) {
                continue;
            }
            
            [self addLines:[defaultConfig configLines]];
            [self addLine:@""];
            break;
        }
    }
    
    for (AbstractMatch *matcher in self.linter.matchers) {
        if (matcher.file != nil) {
            [self addLine:
             @"// %@:%@",
             [matcher.file respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
             NSStringFromTextLocation(matcher.textLocation)];
        }
        
        [self addLines:[matcher configLines]];
        for (AbstractAction *action in matcher.actions) {
            [self addLines:[action configLines]];
        }
        
        if ([matcher.actions count] > 0) {
            [self addLine:@""];
        }
    }
    
    for (NSArray *ignoreConfigs in [NSArray arrayWithObjects:
                                    self.linter.missingIgnoreConfigs,
                                    self.linter.unusedIgnoreConfigs,
                                    self.linter.warningIgnoreConfigs,
                                    self.linter.errorIgnoreConfigs,
                                    nil]) {
        for (IgnoreConfig *ignoreConfig in ignoreConfigs) {
            [self addLines:[ignoreConfig configLines]];
        }
        
        if ([ignoreConfigs count] > 0) {
            [self addLine:@""];
        }
    }
    
    return self;
}

@end
