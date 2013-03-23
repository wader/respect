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

#import "SourceMatch.h"
#import "ExpressionSignature.h"
#import "TextFile.h"
#import "ConfigError.h"
#import "NSRegularExpression+withPatternAndFlags.h"
#import "NSRegularExpression+lineNumber.h"
#import "NSString+Respect.h"

@interface SourceMatch ()
@property(nonatomic, strong, readwrite) ExpressionSignature *experssionSignature;
@property(nonatomic, strong, readwrite) NSRegularExpression *re;
@property(nonatomic, strong, readwrite) NSError *error;
@end

@implementation SourceMatch

+ (NSString *)name {
    return @"SourceMatch";
}

- (id)initWithLinter:(ResourceLinter *)linter
                file:(NSString *)file
        textLocation:(TextLocation)textLocation
      argumentString:(NSString *)argumentString
     isDefaultConfig:(BOOL)isDefaultConfig {
    self = [super initWithLinter:linter
                            file:file
                    textLocation:textLocation
                  argumentString:argumentString
                 isDefaultConfig:isDefaultConfig];
    if (self == nil) {
        return nil;
    }
    
    NSError *error = nil;
    
    self.error = nil;
    if ([argumentString hasPrefix:@"/"]) {
        self.re = [NSRegularExpression
                   regularExpressionWithPatternAndFlags:argumentString
                   options:0
                   error:&error];
    } else {
        self.experssionSignature = [ExpressionSignature
                                    signatureFromString:argumentString
                                    error:&error];
        if (self.experssionSignature != nil) {
            self.re = [NSRegularExpression
                       regularExpressionWithPattern:[self.experssionSignature toPattern]
                       options:0
                       error:&error];
        }
    }
    
    if (self.re == nil) {
        self.error = error;
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:file
                             textLocation:textLocation
                                  message:[NSString stringWithFormat:
                                           @"Matcher error: %@",
                                           [self.error localizedDescription]]]];
    }
    
    return self;
}

- (void)parseResourceReferencesInSourceFile:(TextFile *)textFile {
    // we can use lineRanges from textFile as comment white out only
    // replaces the comment text with whitesapce and leaves new lines alone
    [self.re enumerateMatchesWithLineNumberInString:textFile.whitedoutCommentsText
                                            options:0
                                              range:NSMakeRange(0, [textFile.whitedoutCommentsText length])
                                         lineRanges:textFile.lineRanges
                                         usingBlock:
     ^(NSTextCheckingResult *result, NSUInteger lineNumber, NSRange inLineRange,
       NSMatchingFlags flags, BOOL *stop) {
         NSMutableArray *parameters = [NSMutableArray array];
         for (NSUInteger i = 0; i < result.numberOfRanges; i++) {
             NSRange r =  [result rangeAtIndex:i];
             NSString *parameter = [[textFile.text substringWithRange:r] respect_stringByUnEscaping];
             [parameters addObject:parameter];
         }
         
         PerformParameters *performParameters = [PerformParameters
                                                 performParametersWithParameters:parameters
                                                 path:textFile.path
                                                 textLocation:MakeTextLocation(lineNumber, inLineRange)];
         [self.performParameters addObject:performParameters];
         
         for (AbstractAction *action in self.actions) {
             [action performWithParameters:performParameters];
         }
     }];
}

- (void)performMatch {
    if (self.error != nil) {
        return;
    }
    
    if ([self.actions count] == 0) {
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:self.file
                             textLocation:self.textLocation
                                  message:@"Source matcher has no actions"]];
        return;
    }
    
    for (TextFile *textFile in
         [[self.linter.linterSource sourceTextFiles] objectEnumerator]) {
        [self parseResourceReferencesInSourceFile:textFile];
    }
    
    if (!self.isDefaultConfig && [self.performParameters count] == 0) {
        [self.linter.configErrors addObject:
         [ConfigError configErrorWithFile:self.file
                             textLocation:self.textLocation
                                  message:@"Source matcher do not match anything"]];
    }
}

- (NSArray *)configLines {
    NSMutableArray *lines = [NSMutableArray array];
    
    if (self.error == nil) {
        if (![self.argumentString hasPrefix:@"/"]) {
            [lines addObject:[NSString stringWithFormat:@"// Translated to %@", self.re.pattern]];
        }
    } else {
        [lines addObject:[NSString stringWithFormat:@"// %@", [self.error localizedDescription]]];
    }
    
    [lines addObject:[NSString stringWithFormat:@"@Lint%@: %@", [[self class] name], self.argumentString]];
    
    return lines;
}

@end
