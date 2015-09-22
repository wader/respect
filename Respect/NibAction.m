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

#import "NibAction.h"
#import "ImageAction.h"
#import "ResourceReference.h"
#import "BundleResource.h"
#import "LintError.h"
#import "ImageNamedFinder.h"
#import "NSArray+Respect.h"
#import "NSString+Respect.h"

// TODO: add a BundleFile subclass?
// TODO: non main bundle
// TODO: iOS: found as non-localized?
// TODO: OSX: check Resources?
// TODO: xml path hint?
// TODO: image suggest smartness?

@interface NibAction ()
@property(nonatomic, strong, readwrite) ImageNamedFinder *imageNamedFinder;
@end

@implementation NibAction

+ (NSString *)name {
    return @"Nib";
}


- (void)parseResourceReferencesInXib:(NSString *)path {
    NSData *xibContent = [NSData dataWithContentsOfFile:path];
    if (xibContent == nil) {
        [self.linter.lintErrors addObject:
         [LintError lintErrorWithFile:path
                              message:@"Failed to read file"]];
        return;
    }
    
    NSXMLDocument *dom = [[NSXMLDocument alloc]
                           initWithData:xibContent options:0 error:NULL];
    if (dom == nil) {
        [self.linter.lintErrors addObject:
         [LintError lintErrorWithFile:path
                              message:@"Failed to parse file"]];
        return;
    }
    
    if (self.imageNamedFinder == nil) {
        self.imageNamedFinder = [[ImageNamedFinder alloc] init];
        
        NSOrderedSet *defaultOptions = [self.linter defaultConfigValueForName:[[ImageAction class] name]];
        if (defaultOptions != nil) {
            [self.imageNamedFinder.options applyOptions:defaultOptions];
        }
    }
    
    for(NSXMLNode *node in [dom.rootElement nodesForXPath:@"//string[@key='NSResourceName']"
                                                    error:NULL]) {
        NSArray *resourcePaths = [self.imageNamedFinder
                                  pathsForName:[node stringValue]
                                  usingFileExistsBlock:^BOOL(NSString *path) {
                                      return [self.linter.bundleResources objectForKey:path] != nil;
                                  }];
        
        for (NSString *resourcePath in resourcePaths) {
            ResourceReference *resourceRef = [[ResourceReference alloc]
                                               initWithResourcePath:resourcePath
                                               referencePath:path
                                               referenceLocation:MakeTextLineLocation(1)
                                               missingResourceHint:
                                               [self actionMissingResourceHint:resourcePath]];
            [self.linter.resourceReferences addObject:resourceRef];
            
            BundleResource *bundleRes = [self.linter.bundleResources objectForKey:resourcePath];
            if (bundleRes == nil) {
                continue;
            }
            
            [bundleRes.resourceReferences addObject:resourceRef];
            [resourceRef.bundleResources addObject:bundleRes];
        }
    }
}

- (NSArray *)actionResourcePaths:(NSString *)resourcePath {
    NSString *baseNibName = resourcePath;
    
    if ([[baseNibName pathExtension] isEqualToString:@"nib"]) {
        baseNibName = [baseNibName stringByDeletingPathExtension];
    }
    
    NSArray *deviceNames = [[NSArray respect_arrayWithIOSImageDeviceNames]
                            arrayByAddingObject:@""];
    NSMutableArray *prefixes = [NSMutableArray arrayWithObject:@""];
    for (NSString *region in [self.linter.linterSource knownRegions]) {
        [prefixes addObject:[NSString stringWithFormat:@"%@.lproj/", region]];
    }
    
    NSMutableArray *foundNibPaths = [NSMutableArray array];
    for (NSString *prefix in prefixes) {
        for (NSString *deviceName in deviceNames) {
            NSString *possibleNibPath = [NSString stringWithFormat:@"%@%@%@.nib",
                                         prefix, baseNibName, deviceName];
            
            if ([self.linter.bundleResources objectForKey:possibleNibPath]) {
                [foundNibPaths addObject:possibleNibPath];
            }
        }
    }
    
    if ([foundNibPaths count] == 0) {
        [foundNibPaths addObject:resourcePath];
    }
    
    return foundNibPaths;
}

- (void)actionForMatchedBundleResource:(BundleResource *)bundleRes {
    [self parseResourceReferencesInXib:bundleRes.buildSourcePath];
}

@end
