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

#import "FileAction.h"
#import "ResourceReference.h"
#import "BundleResource.h"
#import "ConfigError.h"
#import "NSString+Respect.h"


@interface FileAction ()
@property(nonatomic, assign, readwrite) BOOL hasError;
@property(nonatomic, strong, readwrite) NSArray *resourcePathTemplates;
@end

@implementation FileAction

+ (NSString *)name {
    return @"File";
}

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
      argumentString:(NSString *)argumentString
     isDefaultConfig:(BOOL)isDefaultConfig
           condition:(FileReferenceCondition)condition
             options:(NSOrderedSet *)options
 permutationsPattern:(NSString *)permutationsPattern {
    self = [super initWithLinter:linter
                            file:file
                    textLocation:textLocation
                  argumentString:argumentString
                 isDefaultConfig:isDefaultConfig];
    if (self == nil) {
        return nil;
    }
    
    self.condition = condition;
    self.permutationsPattern = permutationsPattern;
    self.resourcePathTemplates = [permutationsPattern
                                  respect_permutationsUsingGroupCharacterPair:@"{}"
                                  withSeparators:@","];
    
    [self actionOptions:options];
    
    return self;
}

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
      argumentString:(NSString *)argumentString
     isDefaultConfig:(BOOL)isDefaultConfig {
    NSString *argPermutationsPattern = @"";
    NSOrderedSet *argOptions = [NSOrderedSet orderedSet];
    NSArray *components = [argumentString respect_componentsSeparatedByWhitespaceAllowingQuotes];
    
    if (components == nil) {
        self.hasError = YES;
        [linter.configErrors addObject:
         [ConfigError configErrorWithFile:file
                             textLocation:textLocation
                                  message:@"Unbalanced quotes"]];
    } else if ([components count] == 0 ||
               [[components objectAtIndex:0] length] == 0) {
        self.hasError = YES;
        [linter.configErrors addObject:
         [ConfigError configErrorWithFile:file
                             textLocation:textLocation
                                  message:@"No arguments"]];
    } else {
        argPermutationsPattern = [components objectAtIndex:0];
        argOptions = [NSMutableOrderedSet orderedSetWithArray:
                      [components subarrayWithRange:
                       NSMakeRange(1, [components count]-1)]];
    }
    
    self = [self initWithLinter:linter
                           file:file
                   textLocation:textLocation
                 argumentString:argumentString
                isDefaultConfig:isDefaultConfig
                      condition:FileReferenceConditionAll
                        options:argOptions
            permutationsPattern:argPermutationsPattern];
    if (self == nil) {
        return nil;
    }
    
    return self;
}


- (NSString *)conditionName {
    if (self.condition == FileReferenceConditionAll) {
        return @"all";
    } else if (self.condition == FileReferenceConditionAny) {
        return @"any";
    } else if (self.condition == FileReferenceConditionOptional) {
        return @"optional";
    } else {
        NSAssert(0, @"");
        return nil;
    }
}

- (void)actionOptions:(NSOrderedSet *)options {
    NSMutableOrderedSet *conditionOptions = [NSMutableOrderedSet orderedSetWithObjects:
                                             @"all", @"any", @"optional", nil];
    [conditionOptions intersectOrderedSet:options];
    
    if ([conditionOptions count] == 1) {
        if ([conditionOptions containsObject:@"all"]) {
            self.condition = FileReferenceConditionAll;
        } else if ([conditionOptions containsObject:@"any"]) {
            self.condition = FileReferenceConditionAny;
        } else if ([conditionOptions containsObject:@"optional"]) {
            self.condition = FileReferenceConditionOptional;
        } else {
            NSAssert(0, @"");
        }
    } else if ([conditionOptions count] > 1) {
        self.hasError = YES;
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:self.file
                             textLocation:self.textLocation
                                  message:@"Only one of all, any or optional can be specified"]];
    }
    
    NSMutableOrderedSet *unknownOptions = [options mutableCopy];
    [unknownOptions minusOrderedSet:conditionOptions];
    
    if ([unknownOptions count] > 0) {
        self.hasError = YES;
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:self.file
                             textLocation:self.textLocation
                                  message:[NSString stringWithFormat:@"Unknown options %@",
                                           [[unknownOptions array]
                                            componentsJoinedByString:@", "]]]];
    }
}

- (NSArray *)actionResourcePaths:(NSString *)resourcePath {
    return [NSArray arrayWithObject:resourcePath];
}

- (NSString *)actionMissingResourceHint:(NSString *)resourcePath {
    BundleResource *bundlRef =  [self.linter.lowercaseBundleResources objectForKey:
                                 [resourcePath lowercaseString]];
    if (bundlRef == nil) {
        return nil;
    }
    
    return bundlRef.path;
}

- (void)actionForMatchedBundleResource:(BundleResource *)bundleRes {
}

- (void)performWithParameters:(PerformParameters *)parameters {
    if (self.hasError) {
        return;
    }
    
    NSMutableArray *missingRefs = [NSMutableArray array];
    NSUInteger templatesMatchCount = 0;
    
    for (NSString *pathTemplate in self.resourcePathTemplates) {
        NSUInteger resourcePathsMatchCount = 0;
        
        NSArray *resourcePaths = [self actionResourcePaths:
                                  [pathTemplate respect_stringByReplacingParameters:parameters.parameters]];
        
        for (NSString *resourcePath in resourcePaths) {
            BundleResource *bundleRes = [self.linter.bundleResources objectForKey:resourcePath];
            ResourceReference *resourceRef = nil;
            
            if (bundleRes == nil) {
                resourceRef = [[ResourceReference alloc]
                                initWithResourcePath:resourcePath
                                referencePath:parameters.path
                                referenceLocation:parameters.textLocation
                                missingResourceHint:[self actionMissingResourceHint:resourcePath]];
                
                [missingRefs addObject:resourceRef];
                
                continue;
            }
            
            resourcePathsMatchCount++;
            
            resourceRef = [[ResourceReference alloc]
                            initWithResourcePath:resourcePath
                            referencePath:parameters.path
                            referenceLocation:parameters.textLocation
                            missingResourceHint:nil];
            
            [bundleRes.resourceReferences addObject:resourceRef];
            [resourceRef.bundleResources addObject:bundleRes];
            
            [self.linter.resourceReferences addObject:resourceRef];
            
            [self actionForMatchedBundleResource:bundleRes];
        }
        
        if ([resourcePaths count] == resourcePathsMatchCount) {
            templatesMatchCount++;
        }
    }
    
    // optional, dont care about missing
    if (self.condition == FileReferenceConditionOptional) {
        return;
    }
    
    // any, at least one must have been matched
    if (self.condition == FileReferenceConditionAny &&
        templatesMatchCount > 0) {
        return;
    }
    
    // all, add any missing references
    [self.linter.resourceReferences addObjectsFromArray:missingRefs];
}

- (NSArray *)configLines {
    return [NSArray arrayWithObject:
            [NSString stringWithFormat:@"@Lint%@: %@ %@",
             [[self class] name],
             [self.permutationsPattern respect_stringByQuoteAndEscapeIfNeeded],
             [self conditionName]]];
}

@end
