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

#import "InfoPlistAction.h"
#import "BundleResource.h"
#import "ResourceReference.h"
#import "LintError.h"
#import "ImageNamedFinder.h"
#import "ImageAction.h"
#import "NSString+Respect.h"
#import "NSArray+Respect.h"

// main idea is that images are required if they are explicitly referenced in Info.plist

// TODO: currently this action might mark resources as used when they are not
// TODO: look at ios version? skip some checks
// use [versionString compare:actualVersion options:NSNumericSearch] == NSOrderedDescending
// NSLog(@"%@", [self.linter.linterSource deploymentTarget]);

static NSString * const InfoPlistKeyUILaunchImageFile = @"UILaunchImageFile";
static NSString * const InfoPlistKeyCFBundleIconFile = @"CFBundleIconFile";
static NSString * const InfoPlistKeyCFBundleIconFiles = @"CFBundleIconFiles";
static NSString * const InfoPlistKeyCFBundleIcons = @"CFBundleIcons";
static NSString * const InfoPlistKeyCFBundlePrimaryIcon = @"CFBundlePrimaryIcon";
static NSString * const InfoPlistKeyUINewsstandIcon = @"UINewsstandIcon";

@interface InfoPlistAction ()
@property(nonatomic, retain, readwrite) ImageNamedFinder *imageNamedFinder;
@end

@implementation InfoPlistAction
@synthesize imageNamedFinder = _imageNamedFinder;

- (void)dealloc {
    self.imageNamedFinder = nil;
    
    [super dealloc];
}

+ (NSString *)name {
    return @"InfoPlist";
}

- (void)addResourcePath:(NSString *)resourcePath
          referencePath:(NSString *)referencePath
          referenceHint:(NSString *)referenceHint {
    ResourceReference *resourceRef = [[[ResourceReference alloc]
                                       initWithResourcePath:resourcePath
                                       referencePath:referencePath
                                       referenceLocation:MakeTextLineLocation(1)
                                       referenceHint:referenceHint
                                       missingResourceHint:
                                       // TODO: image smartness?
                                       [self actionMissingResourceHint:resourcePath]]
                                      autorelease];
    [self.linter.resourceReferences addObject:resourceRef];
    
    BundleResource *bundleRes = [self.linter.bundleResources objectForKey:resourcePath];
    if (bundleRes == nil) {
        return;
    }
    
    [bundleRes.resourceReferences addObject:resourceRef];
    [resourceRef.bundleResources addObject:bundleRes];
}

- (void)addNamed:(NSString *)name
   referencePath:(NSString *)referencePath
   referenceHint:(NSString *)referenceHint
      isOptional:(BOOL)isOptional {
    if (isOptional && ![self.linter.bundleResources objectForKey:name]) {
        return;
    }
    
    [self addResourcePath:name
            referencePath:referencePath
            referenceHint:referenceHint];
}

- (void)addNamedImages:(NSString *)name
         referencePath:(NSString *)referencePath
         referenceHint:(NSString *)referenceHint
            isOptional:(BOOL)isOptional {
    NSArray *resourcePaths = [self.imageNamedFinder
                              pathsForName:name
                              usingFileExistsBlock:^BOOL(NSString *path) {
                                  return [self.linter.bundleResources objectForKey:path] != nil;
                              }];
    
    // optional only if all of the found variants do not exist
    if (isOptional) {
        for (NSString *resourcePath in resourcePaths) {
            if ([self.linter.bundleResources objectForKey:resourcePath]) {
                isOptional = NO;
                break;
            }
        }
    }
    
    for (NSString *resourcePath in resourcePaths) {
        [self addNamed:resourcePath
         referencePath:referencePath
         referenceHint:referenceHint
            isOptional:isOptional];
    }
}

- (void)addLaunchImage:(NSDictionary *)infoPlist path:(NSString *)path {
    NSString *launchImage = [infoPlist objectForKey:InfoPlistKeyUILaunchImageFile];
    BOOL launchImageOptional = NO;
    if (launchImage == nil || ![launchImage isKindOfClass:[NSString class]] ||
        [[launchImage respect_stringByTrimmingWhitespace] length] == 0) {
        launchImage = @"Default";
        launchImageOptional = YES;
    }
    [self addNamedImages:launchImage
           referencePath:path
           referenceHint:InfoPlistKeyUILaunchImageFile
              isOptional:launchImageOptional];
    
    NSString *launchImageIphoneKey = [InfoPlistKeyUILaunchImageFile
                                      stringByAppendingString:@"~iphone"];
    NSString *launchImageIphone = [infoPlist objectForKey:launchImageIphoneKey];
    if (launchImageIphone != nil && [launchImageIphone isKindOfClass:[NSString class]] &&
        [[launchImageIphone respect_stringByTrimmingWhitespace] length] > 0) {
        [self addNamedImages:launchImageIphone
               referencePath:path
               referenceHint:launchImageIphoneKey
                  isOptional:NO];
    } else {
        [self addNamedImages:[NSString stringWithFormat:@"%@~iphone", launchImage]
               referencePath:path
               referenceHint:InfoPlistKeyUILaunchImageFile
                  isOptional:YES];
    }
    
    NSString *launchImageIpadKey = [InfoPlistKeyUILaunchImageFile
                                    stringByAppendingString:@"~ipad"];
    NSString *launchImageIpad = [infoPlist objectForKey:launchImageIpadKey];
    if (launchImageIpad != nil && [launchImageIpad isKindOfClass:[NSString class]] &&
        [[launchImageIpad respect_stringByTrimmingWhitespace] length] > 0) {
        [self addNamedImages:launchImageIpad
               referencePath:path
               referenceHint:launchImageIpadKey
                  isOptional:NO];
    } else {
        launchImageIpad = launchImage;
        
        [self addNamedImages:[NSString stringWithFormat:@"%@~ipad", launchImage]
               referencePath:path
               referenceHint:InfoPlistKeyUILaunchImageFile
                  isOptional:YES];
    }
    
    // only ipad have landscape launch images
    NSString *launchImageIpadBasename = [launchImageIpad stringByDeletingPathExtension];
    NSString *launchImageIpadExt = [launchImageIpad pathExtension];
    // Append .ext if ext is not empty to not require ext to be specified
    if (![launchImageIpadExt isEqualToString:@""]) {
        launchImageIpadExt = [@"." stringByAppendingString:launchImageIpadExt];
    }
    for (NSString *orientationName in [NSArray respect_arrayWithIOSIpadOrientationNames]) {
        for (NSString *deviceName in [[NSArray respect_arrayWithIOSImageDeviceNames]
                                      arrayByAddingObject:@""]) {
            [self addNamedImages:[NSString stringWithFormat:@"%@-%@%@%@",
                                  launchImageIpadBasename,
                                  orientationName,
                                  deviceName,
                                  launchImageIpadExt]
                   referencePath:path
                   referenceHint:nil
                      isOptional:YES];
        }
    }
    
    // this will trigger the 568h case in the image finder
    [self addNamedImages:[NSString stringWithFormat:@"%@-568h", launchImageIpadBasename]
           referencePath:path
           referenceHint:nil
              isOptional:YES];
}

- (void)addIcons:(NSDictionary *)infoPlist path:(NSString *)path {
    // collect InfoPlistKeyCFBundlePrimaryIcon, InfoPlistKeyUINewsstandIcon
    // and InfoPlistKeyCFBundleIconFiles as they all are arrays of icon names.
    // use dictionary key for hint.
    NSMutableDictionary *iconArraysDict = [NSMutableDictionary dictionary];
    
    NSDictionary *icons = [infoPlist objectForKey:InfoPlistKeyCFBundleIcons];
    if (icons != nil && [icons isKindOfClass:[NSDictionary class]]) {
        for (NSString *iconKey in [NSArray arrayWithObjects:
                                   InfoPlistKeyCFBundlePrimaryIcon,
                                   InfoPlistKeyUINewsstandIcon,
                                   nil]) {
            NSDictionary *iconDict = [icons objectForKey:iconKey];
            if (iconDict == nil || ![iconDict isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            NSArray *iconArray = [iconDict objectForKey:InfoPlistKeyCFBundleIconFiles];
            if (iconArray != nil) {
                [iconArraysDict setObject:iconArray
                                   forKey:[NSString stringWithFormat:@"%@/%@",
                                           InfoPlistKeyCFBundleIcons,
                                           iconKey]];
            }
        }
    }
    
    NSArray *iconFiles = [infoPlist objectForKey:InfoPlistKeyCFBundleIconFiles];
    if (iconFiles != nil) {
        [iconArraysDict setObject:iconFiles
                           forKey:InfoPlistKeyCFBundleIconFiles];
    }
    
    for (NSString *hintKey in iconArraysDict) {
        NSArray *iconArray = [iconArraysDict objectForKey:hintKey];
        
        if (![iconArray isKindOfClass:[NSArray class]]) {
            continue;
        }
        
        for (NSString *name in iconArray) {
            if (![name isKindOfClass:[NSString class]] ||
                [[name respect_stringByTrimmingWhitespace] length] == 0) {
                continue;
            }
            
            [self addNamedImages:name
                   referencePath:path
                   referenceHint:hintKey
                      isOptional:NO];
        }
    }
    
    NSString *iconFile = [infoPlist objectForKey:InfoPlistKeyCFBundleIconFile];
    if (iconFile == nil || ![iconFile isKindOfClass:[NSString class]] ||
        [[iconFile respect_stringByTrimmingWhitespace] length] == 0) {
        iconFile = @"Icon";
    }
    NSString *iconFileExt = [iconFile pathExtension];
    if (![iconFileExt isEqualToString:@""]) {
        iconFileExt = [@"." stringByAppendingString:iconFileExt];
    }
    NSString *iconFileNormalized = [iconFile respect_stringByNormalizingIOSImageName];
    for (NSString *suffix in [NSArray arrayWithObjects:
                              @"",
                              @"~ipad",
                              @"-72",
                              @"-Small",
                              @"-Small-50",
                              nil]) {
        [self addNamedImages:[NSString stringWithFormat:@"%@%@%@",
                              iconFileNormalized, suffix, iconFileExt]
               referencePath:path
               referenceHint:nil
                  isOptional:YES];
    }
}

- (void)parseInfoPlistAtPath:(NSString *)path {
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:path];
    if (infoPlist == nil ||
        ![infoPlist isKindOfClass:[NSDictionary class]]) {
        [self.linter.lintErrors addObject:
         [LintError lintErrorWithFile:path
                              message:@"Failed to parse Info.plist"]];
        return;
    }
    
    [self addLaunchImage:infoPlist path:path];
    [self addIcons:infoPlist path:path];
    
    // not needed for app store but used in itunes for ad hoc distributions
    for (NSString *optionalNamed in [NSArray arrayWithObjects:
                                     @"iTunesArtwork",
                                     @"iTunesArtwork@2x",
                                     nil]) {
        [self addNamed:optionalNamed
         referencePath:path
         referenceHint:nil
            isOptional:YES];
    }
    
    // TODO: UIMainStoryboardFile
    // TODO: NSMainNibFile
}

- (NSArray *)actionResourcePaths:(NSString *)resourcePath {
    if (self.imageNamedFinder == nil) {
        self.imageNamedFinder = [[[ImageNamedFinder alloc] init] autorelease];
        NSOrderedSet *defaultOptions = [self.linter defaultConfigValueForName:[[ImageAction class] name]];
        if (defaultOptions != nil) {
            [self.imageNamedFinder.options applyOptions:defaultOptions];
        }
        
        // default limit wildcard to ~any, that is to not search for ~ipad and ~iphone.
        // to search for device specific resources the filename must include the
        // device modifier
        [self.imageNamedFinder.wildcardOptions applyOptions:
         [NSOrderedSet orderedSetWithObject:ImageNamedOptionsAny]];
    }
    
    // TODO: non main bundle
    
    NSMutableArray *foundPaths = [NSMutableArray array];
    [foundPaths addObject:resourcePath];
    
    // TODO: must exist? special case Info.plist -> InfoPlist.strings?
    for (NSString *region in [self.linter.linterSource knownRegions]) {
        NSString *stringsPath = [NSString stringWithFormat:@"%@.lproj/InfoPlist.strings",
                                 region];
        if ([self.linter.bundleResources objectForKey:stringsPath]) {
            [foundPaths addObject:stringsPath];
        }
    }
    
    return foundPaths;
}

- (void)actionForMatchedBundleResource:(BundleResource *)bundleRes {
    if (![[bundleRes.buildSourcePath pathExtension] isEqualToString:@"plist"]) {
        return;
    }
    
    [self parseInfoPlistAtPath:bundleRes.buildSourcePath];
}

@end
