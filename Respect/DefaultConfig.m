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

#import "DefaultConfig.h"
#import "ConfigError.h"
#import "NSString+Respect.h"

@interface DefaultConfig ()
@property(nonatomic, weak, readwrite) ResourceLinter *linter;
@property(nonatomic, copy, readwrite) NSString *file;
@property(nonatomic, assign, readwrite) TextLocation textLocation;
@property(nonatomic, strong, readwrite) NSString *name;
@property(nonatomic, copy, readwrite) NSString *argument;
@property(nonatomic, strong, readwrite) id configValue;
@property(nonatomic, strong, readwrite) NSString *errorMessage;
@property(nonatomic, assign, readwrite) BOOL hasError;
@end

@implementation DefaultConfig

+ (id)defaultWithLinter:(ResourceLinter *)linter
                   file:(NSString *)file
           textLocation:(TextLocation)textLocation
                   name:(NSString *)name
         argumentString:(NSString *)argumentString
            configValue:(id)configValue
           errorMessage:(NSString *)errorMessage {
    return [[self alloc] initWithLinter:linter
                                    file:file
                            textLocation:textLocation
                                    name:name
                          argumentString:argumentString
                             configValue:configValue
                            errorMessage:errorMessage];
}

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
                name:(NSString *)name
      argumentString:(NSString *)argumentString
         configValue:(id)configValue
        errorMessage:(NSString *)errorMessage {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.linter = linter;
    self.file = file;
    self.textLocation = textLocation;
    self.name = name;
    self.argument = argumentString;
    self.configValue = configValue;
    self.errorMessage = errorMessage;
    self.hasError = errorMessage != nil;
    
    if (self.hasError) {
        [linter.configErrors addObject:
         [ConfigError configErrorWithFile:file
                             textLocation:textLocation
                                  message:errorMessage]];
    }
    
    return self;
}


- (NSArray *)configLines {
    NSMutableArray *lines = [NSMutableArray array];
    [lines addObject:[NSString stringWithFormat:@"// %@:%@",
                      [self.file respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
                      NSStringFromTextLocation(self.textLocation)]];
    
    if (self.hasError) {
        [lines addObject:[NSString stringWithFormat:@"// %@", self.errorMessage]];
    }
    
    [lines addObject:[NSString stringWithFormat:@"@Lint%@Default: %@", self.name, self.argument]];
    
    return lines;
}

@end
