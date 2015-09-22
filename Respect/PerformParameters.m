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

#import "PerformParameters.h"

@interface PerformParameters ()
@property(nonatomic, strong, readwrite) NSArray *parameters;
@property(nonatomic, copy, readwrite) NSString *path;
@property(nonatomic, assign, readwrite) TextLocation textLocation;
@end

@implementation PerformParameters

+ (id)performParametersWithParameters:(NSArray *)parameters
                                 path:(NSString *)path
                         textLocation:(TextLocation)textLocation {
    return [[self alloc] initWithParameters:parameters
                                        path:path
                                textLocation:textLocation];
}

- (id)initWithParameters:(NSArray *)parameters
                    path:(NSString *)path
            textLocation:(TextLocation)textLocation {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.parameters = parameters;
    self.path = path;
    self.textLocation = textLocation;
    
    return self;
}


@end
