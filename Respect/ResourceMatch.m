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

#import "ResourceMatch.h"
#import "ConfigError.h"
#import "BundleResource.h"
#import "NSRegularExpression+withPatternAndFlags.h"
#import "NSRegularExpression+withFnmatch.h"


@interface ResourceMatch ()
@property(nonatomic, copy, readwrite) NSRegularExpression *re;
@property(nonatomic, retain, readwrite) NSError *error;
@end

@implementation ResourceMatch
@synthesize re = _re;
@synthesize error = _error;

+ (NSString *)name {
    return @"ResourceMatch";
}

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
      argumentString:(NSString *)argumentString
     isDefaultConfig:(BOOL)isDefaultConfig {
    self = [super initWithLinter:linter
                            file:file
                    textLocation:textLocation
                  argumentString:argumentString
                 isDefaultConfig:isDefaultConfig];
    if (self == nil) {
        return nil;
    }
    
    NSError *error = nil;
    
    self.error = nil;
    if ([argumentString hasPrefix:@"/"]) {
        self.re = [NSRegularExpression
                   regularExpressionWithPatternAndFlags:argumentString
                   options:0
                   error:&error];
    } else {
        self.re = [NSRegularExpression
                   regularExpressionWithFnmatch:argumentString
                   error:&error];
    }
    
    if (self.re == nil) {
        self.error = error;
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:file
                             textLocation:textLocation
                                  message:[NSString stringWithFormat:
                                           @"Matcher error: %@",
                                           [self.error localizedDescription]]]];
    }
    
    return self;
}

- (void)dealloc {
    self.re = nil;
    self.error = nil;
    
    [super dealloc];
}

- (void)performMatch {
    if (self.error != nil) {
        return;
    }
    
    if ([self.actions count] == 0) {
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:self.file
                             textLocation:self.textLocation
                                  message:@"Resource matcher has no actions"]];
        return;
    }
    
    for (BundleResource *bundleRes in [self.linter.bundleResources objectEnumerator]) {
        NSTextCheckingResult *result = [self.re
                                        firstMatchInString:bundleRes.path
                                        options:0
                                        range:NSMakeRange(0, [bundleRes.path length])];
        if (result == nil || result.range.location == NSNotFound) {
            continue;
        }
        
        NSMutableArray *parameters = [NSMutableArray array];
        for (NSUInteger i = 0; i < result.numberOfRanges; i++) {
            if ([result rangeAtIndex:i].location == NSNotFound) {
                [parameters addObject:@""];
            } else {
                [parameters addObject:[bundleRes.path substringWithRange:[result rangeAtIndex:i]]];
            }
        }
        
        PerformParameters *performParameters = [PerformParameters
                                                performParametersWithParameters:parameters
                                                path:bundleRes.buildSourcePath
                                                textLocation:MakeTextLineLocation(0)];
        [self.performParameters addObject:performParameters];
        
        for (AbstractAction *action in self.actions) {
            [action performWithParameters:performParameters];
        }
    }
    
    if (!self.isDefaultConfig && [self.performParameters count] == 0) {
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:self.file
                             textLocation:self.textLocation
                                  message:@"Resource matcher do not match any bundle files"]];
    }
}

- (NSArray *)configLines {
    NSMutableArray *lines = [NSMutableArray array];
    
    if (self.error == nil) {
        if (![self.argumentString hasPrefix:@"/"]) {
            [lines addObject:[NSString stringWithFormat:@"// Translated to %@", self.re.pattern]];
        }
    } else {
        [lines addObject:[NSString stringWithFormat:@"// %@", [self.error localizedDescription]]];
    }
    
    [lines addObject:[NSString stringWithFormat:@"@Lint%@: %@", [[self class] name], self.argumentString]];
    
    return lines;
}

@end
