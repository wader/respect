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

#import "AbstractAction.h"

@interface AbstractAction ()
@property(nonatomic, assign, readwrite) ResourceLinter *linter;
@property(nonatomic, assign, readwrite) TextLocation textLocation;
@property(nonatomic, copy, readwrite) NSString *file;
@property(nonatomic, copy, readwrite) NSString *argumentString;
@property(nonatomic, assign, readwrite) BOOL isDefaultConfig;
@end

@implementation AbstractAction
@synthesize linter = _linter;
@synthesize file = _file;
@synthesize textLocation = _textLocation;
@synthesize argumentString = _argumentString;
@synthesize isDefaultConfig = _isDefaultConfig;

+ (NSString *)name {
    return @"";
}

+ (id)defaultConfigValueFromArgument:(NSString *)argument
                        errorMessage:(NSString **)errorMessage {
    *errorMessage = nil;
    
    return nil;
}

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
      argumentString:(NSString *)argumentString
     isDefaultConfig:(BOOL)isDefaultConfig {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.linter = linter;
    self.file = file;
    self.textLocation = textLocation;
    self.argumentString = argumentString;
    self.isDefaultConfig = isDefaultConfig;
    
    return self;
}

- (void)dealloc {
    self.linter = nil;
    self.file = nil;
    self.argumentString = nil;
    
    [super dealloc];
}

- (void)performWithParameters:(PerformParameters *)parameters {
}

- (NSArray *)configLines {
    return [NSArray array];
}

@end
