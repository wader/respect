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

#import "ResourceReference.h"
#import "BundleResource.h"
#import "NSString+Respect.h"

@interface ResourceReference ()
@property(nonatomic, copy, readwrite) NSString *resourcePath;
@property(nonatomic, copy, readwrite) NSString *referencePath;
@property(nonatomic, assign, readwrite) TextLocation referenceLocation;
@property(nonatomic, copy, readwrite) NSString *referenceHint;
@property(nonatomic, retain, readwrite) NSMutableArray *bundleResources;
@property(nonatomic, copy, readwrite) NSString *missingResourceHint;
@end

@implementation ResourceReference
@synthesize resourcePath = _resourcePath;
@synthesize referencePath = _referencePath;
@synthesize referenceHint = _referenceHint;
@synthesize referenceLocation = _referenceLocation;
@synthesize bundleResources = _bundleResources;
@synthesize missingResourceHint = _missingResourceHint;

- (id)initWithResourcePath:(NSString *)resourcePath
             referencePath:(NSString *)referencePath
         referenceLocation:(TextLocation)referenceLocation
             referenceHint:(NSString *)referenceHint
       missingResourceHint:(NSString *)missingResourceHint {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.resourcePath = resourcePath;
    self.referencePath = referencePath;
    self.referenceHint = referenceHint;
    self.referenceLocation = referenceLocation;
    self.bundleResources = [NSMutableArray array];
    self.missingResourceHint = missingResourceHint;
    
    return self;
}

- (id)initWithResourcePath:(NSString *)resourcePath
             referencePath:(NSString *)referencePath
         referenceLocation:(TextLocation)referenceLocation
       missingResourceHint:(NSString *)missingResourceHint {
    return [self initWithResourcePath:resourcePath
                        referencePath:referencePath
                    referenceLocation:referenceLocation
                        referenceHint:nil
                  missingResourceHint:missingResourceHint];
}

- (void)dealloc {
    self.resourcePath = nil;
    self.referencePath = nil;
    self.referenceHint = nil;
    self.bundleResources = nil;
    self.missingResourceHint = nil;
    
    [super dealloc];
}

@end
