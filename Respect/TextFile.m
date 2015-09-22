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

#import "TextFile.h"
#import "NSString+Respect.h"
#import "NSString+lineNumber.h"

// whitedoutCommentsText is here for performance, it is expensive so only do it
// once per text file instead of everytime a source match is performed.

@interface TextFile ()
@property(nonatomic, copy, readwrite) NSString *path;
@property(nonatomic, copy, readwrite) NSString *text;
@property(nonatomic, strong, readwrite) NSString *whitedoutCommentsText;
@property(nonatomic, strong, readwrite) NSArray *lineRanges;
@end

@implementation TextFile
@synthesize path = _path;
@synthesize text = _text;
@synthesize whitedoutCommentsText = _whitedoutCommentsText;
@synthesize lineRanges = _lineRanges;

+ (id)textFileWithText:(NSString *)text path:(NSString *)path {
    return [[self alloc] initWithText:text path:path];
}

+ (id)textFileWithContentOfFile:(NSString *)file {
    return [[self alloc] initWithContentOfFile:file];
}

// replace C-style comments with whitespace
+ (NSString *)stringWithCommentTextWhitedoutInSource:(NSString *)source {
    static NSRegularExpression *re = nil;
    static NSCharacterSet *nonWhitespaceAndNewlineCharacterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        re = [[NSRegularExpression alloc]
              initWithPattern:
              // match c or objc string as capture group 1 so that we can skip them
              // this is to avoid whiteout of comments inside literal strings
              @"@?\"((?:\\\\.|[^\"])*)\""
              @"|"
              // match /* ... */
              // s flag to make dot match line separators
              @"\\/\\*(?s:.*?)\\*\\/"
              @"|"
              // match // ...
              @"(?:\\/\\/.*(\\r?\\n|$))"
              options:0
              error:NULL];
        
        nonWhitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                                invertedSet];
    });
    
    NSMutableString *replaced = [source mutableCopy];
    
    [re enumerateMatchesInString:source
                         options:0 range:NSMakeRange(0, [source length])
                      usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         // skip if quoted string
         if ([result rangeAtIndex:1].location != NSNotFound) {
             return;
         }
         
         [replaced
          replaceCharactersInRange:result.range
          withString:[[replaced substringWithRange:result.range]
                      respect_stringByReplacingCharactersInSet:nonWhitespaceAndNewlineCharacterSet
                      withCharacter:' ']];
     }];
    
    return replaced;
}

- (id)initWithText:(NSString *)text path:(NSString *)path {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.path = path;
    self.text = text;
    self.lineRanges = [text lineNumber_lineRanges];
    
    return self;
}

- (id)initWithContentOfFile:(NSString *)file {
    NSString *text = [NSString respect_stringWithContentsOfFileTryingEncodings:file
                                                                         error:NULL];
    if (text == nil) {
        return nil;
    }
    
    return [self initWithText:text path:file];
}


- (NSString *)whitedoutCommentsText {
    if (_whitedoutCommentsText == nil) {
        self.whitedoutCommentsText = [[self class]
                                      stringWithCommentTextWhitedoutInSource:self.text];
    }
    
    return _whitedoutCommentsText;
}

@end
