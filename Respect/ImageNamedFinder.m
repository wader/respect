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

#import "ImageNamedFinder.h"
#import "NSArray+Respect.h"
#import "NSString+Respect.h"


@interface ImageNamedFinder ()
@property(nonatomic, retain, readwrite) ImageNamedOptions *options;
@property(nonatomic, retain, readwrite) ImageNamedOptions *wildcardOptions;
@end

@implementation ImageNamedFinder

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.options = [[[ImageNamedOptions alloc] init] autorelease];
    self.wildcardOptions = [[[ImageNamedOptions alloc] init] autorelease];
    [self.wildcardOptions applyOptions:[ImageNamedOptions allOptions]];
    
    return self;
}

- (void)dealloc {
    self.options = nil;
    self.wildcardOptions = nil;
    
    [super dealloc];
}

+ (void)dumpPrefix:(NSString *)prefix
              name:(NSString *)name
            scales:(NSOrderedSet *)scales
           devices:(NSOrderedSet *)devices
              exts:(NSOrderedSet *)exts {
    /*
    NSLog(@"%@ %@{%@}{%@}{%@}",
          prefix,
          name,
          [[scales array] componentsJoinedByString:@","],
          [[devices array] componentsJoinedByString:@","],
          [[exts array] componentsJoinedByString:@","]);
     */
}

- (NSArray *)pathsForName:(NSString *)name
     usingFileExistsBlock:(BOOL (^)(NSString *path))fileExistsBlock {
    // figure out limits, from options then from filename
    NSOrderedSet *limitScales = self.options.scales;
    NSOrderedSet *limitDevices = self.options.devices;
    NSOrderedSet *limitExts = self.options.exts;
    
    NSString *normalizedName = name;
    NSString *filenameExt = [normalizedName respect_stringSuffixInArray:
                             [NSArray respect_arrayWithIOSImageDotExtensionNames]];
    if (filenameExt != nil) {
        normalizedName = [normalizedName respect_stringByStripSuffix:filenameExt];
        limitExts = [NSOrderedSet orderedSetWithObject:filenameExt];
    }
    
    NSString *filenameScale = [normalizedName respect_stringSuffixInArray:
                               [NSArray respect_arrayWithIOSImageScaleNames]];
    if (filenameScale != nil) {
        normalizedName = [normalizedName respect_stringByStripSuffix:filenameScale];
        limitScales = [NSOrderedSet orderedSetWithObject:filenameScale];
    } else if ([normalizedName hasSuffix:@"-568h"]) {
        // special case for 568h, limit to @2x and keep -568h
        limitScales = [NSOrderedSet orderedSetWithObject:@"@2x"];
    }
    
    NSString *filenameDevice = [normalizedName respect_stringSuffixInArray:
                                [NSArray respect_arrayWithIOSImageDeviceNames]];
    if (filenameDevice != nil) {
        normalizedName = [normalizedName respect_stringByStripSuffix:filenameDevice];
        limitDevices = [NSOrderedSet orderedSetWithObject:filenameDevice];
    }
    
    [[self class] dumpPrefix:@"limit " name:normalizedName
                      scales:limitScales devices:limitDevices exts:limitExts];
    
    NSOrderedSet *searchScales = limitScales ?: self.wildcardOptions.scales;
    NSOrderedSet *searchDevices = limitDevices ?: self.wildcardOptions.devices;
    NSOrderedSet *searchExts = limitExts ?: self.wildcardOptions.exts;
    
    [[self class] dumpPrefix:@"search" name:normalizedName
                      scales:searchScales devices:searchDevices exts:searchExts];
    
    NSMutableOrderedSet *foundScales = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet *foundDevices = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet *foundExts = [NSMutableOrderedSet orderedSet];
    
    // search for exsiting images using limits with wildcard if unspecified
    for (NSString *device in searchDevices) {
        for (NSString *scale in searchScales) {
            for (NSString *ext in searchExts) {
                NSString *possiblePath = [NSString stringWithFormat:@"%@%@%@%@",
                                          normalizedName, scale, device, ext];
                if (!fileExistsBlock(possiblePath)) {
                    continue;
                }
                
                [foundScales addObject:scale];
                [foundDevices addObject:device];
                [foundExts addObject:ext];
                
                // wildcard ext, limit continued search to first found
                if (limitExts == nil) {
                    searchExts = foundExts;
                    break;
                }
            }
        }
    }
    
    [[self class] dumpPrefix:@"found " name:normalizedName
                      scales:foundScales devices:foundDevices exts:foundExts];
    
    // image that must exist are the union of limits and found
    NSMutableOrderedSet *mustScales = [[foundScales mutableCopy] autorelease];
    if (limitScales != nil) {
        [mustScales unionOrderedSet:limitScales];
    }
    
    NSMutableOrderedSet *mustDevices = [[foundDevices mutableCopy] autorelease];
    if (limitDevices != nil) {
        [mustDevices unionOrderedSet:limitDevices];
    }
    
    NSMutableOrderedSet *mustExts = [[foundExts mutableCopy] autorelease];
    if (limitExts != nil) {
        [mustExts unionOrderedSet:limitExts];
    }
    
    // if we have at least one must make sure to add empty string to the non-musts
    if ([mustScales count] +
        [mustDevices count] +
        [mustExts count] > 0) {
        if ([mustScales count] == 0) {
            [mustScales addObject:@""];
        }
        if ([mustDevices count] == 0) {
            [mustDevices addObject:@""];
        }
        if ([mustExts count] == 0) {
            [mustExts addObject:@""];
        }
    }
    
    [[self class] dumpPrefix:@"must  " name:normalizedName
                      scales:mustScales devices:mustDevices exts:mustExts];
    
    NSMutableOrderedSet *resourcePaths = [NSMutableOrderedSet orderedSet];
    for (NSString *scale in mustScales) {
        for (NSString *device in mustDevices) {
            for (NSString *ext in mustExts) {
                [resourcePaths addObject:[NSString stringWithFormat:@"%@%@%@%@",
                                          normalizedName, scale, device, ext]];
            }
        }
    }
    
    return [resourcePaths array];
}

@end
