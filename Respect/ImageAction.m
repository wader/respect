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

#import "ImageAction.h"
#import "ImageNamedFinder.h"
#import "DefaultConfig.h"
#import "NSString+Respect.h"
#import "NSArray+Respect.h"

@interface ImageAction ()
@property(nonatomic, strong, readwrite) ImageNamedFinder *imageNamedFinder;
@property(nonatomic, strong, readwrite) NSOrderedSet *actionOptions;
@end

@implementation ImageAction

+ (NSString *)name {
    return @"Image";
}

+ (id)defaultConfigValueFromArgument:(NSString *)argument
                        errorMessage:(NSString **)errorMessage {
    NSArray *components = [argument respect_componentsSeparatedByWhitespaceAllowingQuotes];
    if (components == nil) {
        *errorMessage = @"Unbalanced quotes";
        return nil;
    }
    
    NSOrderedSet *options = [NSOrderedSet orderedSetWithArray:components];
    NSOrderedSet *unknownOptions = [ImageNamedOptions unknownOptionsFromOptions:options];
    if ([unknownOptions count] > 0) {
        *errorMessage = [NSString stringWithFormat:@"Unknown options %@",
                         [[unknownOptions array]
                          componentsJoinedByString:@", "]];
        return nil;
    }
    
    return options;
}

- (void)actionOptions:(NSOrderedSet *)options {
    NSOrderedSet *unknownOptions = [ImageNamedOptions unknownOptionsFromOptions:options];
    
    NSMutableOrderedSet *imageOptions = [options mutableCopy];
    [imageOptions minusOrderedSet:unknownOptions];
    self.actionOptions = imageOptions;
    
    [super actionOptions:unknownOptions];
}

- (NSArray *)actionResourcePaths:(NSString *)resourcePath {
    if (self.imageNamedFinder == nil) {
        self.imageNamedFinder = [[ImageNamedFinder alloc] init];
        
        NSOrderedSet *defaultOptions = [self.linter defaultConfigValueForName:[[self class] name]];
        if (defaultOptions != nil) {
            [self.imageNamedFinder.options applyOptions:defaultOptions];
        }
        
        [self.imageNamedFinder.options applyOptions:self.actionOptions];
    }
    
    return [self.imageNamedFinder
            pathsForName:resourcePath
            usingFileExistsBlock:^BOOL(NSString *path) {
                return [self.linter.bundleResources objectForKey:path] != nil;
            }];
}

- (NSString *)actionMissingResourceHint:(NSString *)resourcePath {
    NSArray *resourcePaths = [self.imageNamedFinder
                              pathsForName:resourcePath
                              usingFileExistsBlock:^BOOL(NSString *path) {
                                  return [self.linter.bundleResources objectForKey:path] != nil;
                              }];
    // dont suggest if some image exist
    for (NSString *resourcePath in resourcePaths) {
        if ([self.linter.bundleResources objectForKey:resourcePath]) {
            return nil;
        }
    }
    
    // find existing images that must exist must but incase sensitively that
    // have the same filename minus ext
    NSArray *lowerResourcePaths = [self.imageNamedFinder
                                   pathsForName:resourcePath
                                   usingFileExistsBlock:^BOOL(NSString *path) {
                                       return [self.linter.lowercaseBundleResources
                                               objectForKey:[path lowercaseString]] != nil;
                                   }];
    NSString *resourcePathLowerWihoutExt = [[resourcePath stringByDeletingPathExtension]
                                            lowercaseString];
    NSMutableArray *existinSuggestions = [NSMutableArray array];
    for (NSString *resourcePath in lowerResourcePaths) {
        BundleResource *bundleRef = [self.linter.lowercaseBundleResources
                                     objectForKey:[resourcePath lowercaseString]];
        if (bundleRef == nil ||
            ![[[bundleRef.path stringByDeletingPathExtension] lowercaseString]
              isEqualToString:resourcePathLowerWihoutExt]) {
                continue;
            }
        
        [existinSuggestions addObject:bundleRef.path];
    }
    
    if ([existinSuggestions count] > 0) {
        return [existinSuggestions lastObject];
    }
    
    return nil;
}

- (NSArray *)configLines {
    return [NSArray arrayWithObject:
            [NSString stringWithFormat:@"@Lint%@: %@ %@ %@",
             [[self class] name],
             [self.permutationsPattern respect_stringByQuoteAndEscapeIfNeeded],
             [self conditionName],
             [[self.actionOptions array] respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded]]];
}

@end
