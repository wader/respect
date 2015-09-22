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

#import "NSArray+Respect.h"
#import "NSString+Respect.h"

@implementation NSArray (Respect)
+ (NSArray *)respect_arrayWithIOSImageExtensionNames {
    static NSArray *extensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extensions = [[NSArray alloc] initWithObjects:
                      @"png",
                      @"jpg",
                      @"jpeg",
                      @"tiff",
                      @"tif",
                      @"gif",
                      @"bmp",
                      @"bmpf",
                      @"ico",
                      @"cur",
                      @"xbm",
                      nil];
    });

    return extensions;
}

+ (NSArray *)respect_arrayWithIOSImageDotExtensionNames {
    static NSArray *dotExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *extWithDots = [NSMutableArray array];
        for (NSString *ext in [self respect_arrayWithIOSImageExtensionNames]) {
            [extWithDots addObject:[@"." stringByAppendingString:ext]];
        }

        dotExtensions = [NSArray arrayWithArray:extWithDots];
    });

    return dotExtensions;
}

+ (NSArray *)respect_arrayWithIOSImageScaleNames {
    static NSArray *scales = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scales = [[NSArray alloc] initWithObjects:@"@2x", nil];
    });

    return scales;
}

+ (NSArray *)respect_arrayWithIOSImageDeviceNames {
    static NSArray *devices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        devices = [[NSArray alloc] initWithObjects:@"~ipad", @"~iphone", nil];
    });

    return devices;
}

+ (NSArray *)respect_arrayWithIOSIpadOrientationNames {
    static NSArray *devices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        devices = [[NSArray alloc] initWithObjects:
                   @"PortraitUpsideDown",
                   @"LandscapeLeft",
                   @"LandscapeRight",
                   @"Portrait",
                   @"Landscape",
                   nil];
    });

    return devices;
}

- (NSString *)respect_componentsJoinedByWhitespaceQuoteAndEscapeIfNeeded {
    NSMutableArray *quoteAndEscaped = [NSMutableArray array];

    for (NSString *component in self) {
        [quoteAndEscaped addObject:[component respect_stringByQuoteAndEscapeIfNeeded]];
    }

    return [quoteAndEscaped componentsJoinedByString:@" "];
}

@end
