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

#import "IgnoreConfig.h"
#import "NSRegularExpression+withFnmatch.h"
#import "NSRegularExpression+withPatternAndFlags.h"
#import "ConfigError.h"
#import "NSString+Respect.h"

@interface IgnoreConfig ()
@property(nonatomic, assign, readwrite) ResourceLinter *linter;
@property(nonatomic, copy, readwrite) NSString *file;
@property(nonatomic, assign, readwrite) TextLocation textLocation;
@property(nonatomic, copy, readwrite) NSString *type;
@property(nonatomic, retain, readwrite) NSRegularExpression *re;
@property(nonatomic, copy, readwrite) NSString *pattern;
@property(nonatomic, retain, readwrite) NSError *error;
@end

@implementation IgnoreConfig
@synthesize linter = _linter;
@synthesize file = _file;
@synthesize textLocation = _textLocation;
@synthesize type = _type;
@synthesize re = _re;
@synthesize pattern = _pattern;
@synthesize error = _error;

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
                type:(NSString *)type
      argumentString:(NSString *)argumentString {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    NSError *error = nil;
    
    self.linter = linter;
    self.file = file;
    self.textLocation = textLocation;
    self.type = type;
    self.pattern = argumentString;
    if ([argumentString hasPrefix:@"/"]) {
        self.re = [NSRegularExpression
                   regularExpressionWithPatternAndFlags:argumentString
                   options:0
                   error:&error];
    } else {
        self.re = [NSRegularExpression
                   regularExpressionWithFnmatch:argumentString
                   error:&error];
    }
    
    if (self.re == nil) {
        self.error = error;
        [linter.configErrors addObject:
         [ConfigError configErrorWithFile:file
                             textLocation:textLocation
                                  message:[self.error localizedDescription]]];
    }
    
    return self;
}

- (void)dealloc {
    self.file = nil;
    self.type = nil;
    self.re = nil;
    self.pattern = nil;
    self.error = nil;
    
    [super dealloc];
}

- (BOOL)matchesString:(NSString *)string {
    if (self.re == nil) {
        return NO;
    }
    
    return ([self.re
             numberOfMatchesInString:string
             options:0
             range:NSMakeRange(0, [string length])]
            > 0);
}

- (NSArray *)configLines {
    NSMutableArray *lines = [NSMutableArray array];
    
    [lines addObject:[NSString stringWithFormat:@"// %@:%@",
                      [self.file respect_stringRelativeToPathPrefix:[self.linter.linterSource sourceRoot]],
                      NSStringFromTextLocation(self.textLocation)]];
    
    if (![self.pattern hasPrefix:@"/"]) {
        [lines addObject:[NSString stringWithFormat:@"// Translated to %@", self.re.pattern]];
    }
    
    [lines addObject:[NSString stringWithFormat:@"@Lint%@: %@", self.type, self.pattern]];
    
    return lines;
}

@end
