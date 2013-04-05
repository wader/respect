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

#import "ImageNamedOptions.h"
#import "NSArray+Respect.h"


NSString * const ImageNamedOptions1x = @"@1x";
NSString * const ImageNamedOptions2x = @"@2x";
NSString * const ImageNamedOptions568h = @"568h";
NSString * const ImageNamedOptionsAny = @"~any";
NSString * const ImageNamedOptionsIphone = @"~iphone";
NSString * const ImageNamedOptionsIpad = @"~ipad";

@interface ImageNamedOptions ()
@property(nonatomic, retain, readwrite) NSMutableOrderedSet *scales;
@property(nonatomic, retain, readwrite) NSMutableOrderedSet *devices;
@property(nonatomic, retain, readwrite) NSMutableOrderedSet *exts;
@end

@implementation ImageNamedOptions
@synthesize scales = _scales;
@synthesize devices = _devices;
@synthesize exts = _exts;

- (void)dealloc {
    self.scales = nil;
    self.devices = nil;
    self.exts = nil;
    
    [super dealloc];
}

+ (NSOrderedSet *)scaleOptions {
    static dispatch_once_t onceToken;
    static NSOrderedSet *options = nil;
    dispatch_once(&onceToken, ^{
        options = [[NSOrderedSet alloc]
                   initWithObjects:
                   ImageNamedOptions1x,
                   ImageNamedOptions2x,
                   ImageNamedOptions568h,
                   nil];
    });
    
    return options;
}

+ (NSOrderedSet *)deviceOptions {
    static dispatch_once_t onceToken;
    static NSOrderedSet *options = nil;
    dispatch_once(&onceToken, ^{
        options = [[NSOrderedSet alloc]
                   initWithObjects:
                   ImageNamedOptionsAny,
                   ImageNamedOptionsIphone,
                   ImageNamedOptionsIpad,
                   nil];
    });
    
    return options;
}

+ (NSOrderedSet *)extOptions {
    static dispatch_once_t onceToken;
    static NSOrderedSet *options = nil;
    dispatch_once(&onceToken, ^{
        options = [[NSOrderedSet alloc]
                   initWithArray:[NSArray respect_arrayWithIOSImageExtensionNames]];
    });
    
    return options;
}

+ (NSOrderedSet *)allOptions {
    static dispatch_once_t onceToken;
    static NSOrderedSet *options = nil;
    dispatch_once(&onceToken, ^{
        NSMutableOrderedSet *optionsUnion = [[[self scaleOptions] mutableCopy]
                                             autorelease];
        [optionsUnion unionOrderedSet:[self deviceOptions]];
        [optionsUnion unionOrderedSet:[self extOptions]];
        options = [[NSOrderedSet alloc] initWithOrderedSet:optionsUnion];
    });
    
    return options;
}

+ (NSOrderedSet *)unknownOptionsFromOptions:(NSOrderedSet *)options {
    NSMutableOrderedSet *unknownOptions = [[options mutableCopy] autorelease];
    [unknownOptions minusOrderedSet:[self scaleOptions]];
    [unknownOptions minusOrderedSet:[self deviceOptions]];
    [unknownOptions minusOrderedSet:[self extOptions]];
    
    return unknownOptions;
}

- (void)applyOptions:(NSOrderedSet *)options {
    NSMutableOrderedSet *scaleOptions = [[[[self class] scaleOptions] mutableCopy] autorelease];
    NSMutableOrderedSet *deviceOptions = [[[[self class] deviceOptions] mutableCopy] autorelease];
    NSMutableOrderedSet *extOptions = [[[[self class] extOptions] mutableCopy] autorelease];
    
    [scaleOptions intersectOrderedSet:options];
    if ([scaleOptions count] > 0) {
        self.scales = [NSMutableOrderedSet orderedSet];
        if ([scaleOptions containsObject:ImageNamedOptions1x]) {
            [self.scales addObject:@""];
        }
        if ([scaleOptions containsObject:ImageNamedOptions2x]) {
            [self.scales addObject:@"@2x"];
        }
        if ([scaleOptions containsObject:ImageNamedOptions568h]) {
            [self.scales addObject:@"-568h@2x"];
        }
    }
    
    [deviceOptions intersectOrderedSet:options];
    if ([deviceOptions count] > 0) {
        self.devices = [NSMutableOrderedSet orderedSet];
        if ([deviceOptions containsObject:ImageNamedOptionsAny]) {
            [self.devices addObject:@""];
        }
        if ([deviceOptions containsObject:ImageNamedOptionsIphone]) {
            [self.devices addObject:ImageNamedOptionsIphone];
        }
        if ([deviceOptions containsObject:ImageNamedOptionsIpad]) {
            [self.devices addObject:ImageNamedOptionsIpad];
        }
    }
    
    [extOptions intersectOrderedSet:options];
    if ([extOptions count] > 0) {
        self.exts = [NSMutableOrderedSet orderedSet];
        for (NSString *ext in extOptions) {
            [self.exts addObject:[@"." stringByAppendingString:ext]];
        }
    }
}

@end
