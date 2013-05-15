// xcconfig (Xcode config) file format parser
//
// Copyright (c) 2013 <mattias.wadman@gmail.com>
//
// MIT License:
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/*
 * xcconfig format as figured out by testing with Xcode as can't find any
 * formal specification from Apple.
 *
 * XCCONFIG = LINES
 * LINES = LINE LINES
 * LINE = SPACE (PAIR | DIRECTIVE) SPACE ("" | COMMENT) "\n"
 *
 * PAIR = NAME SPACE "=" SPACE VALUE
 * DIRECTIVE = "#" NAME SPACE QUOTE_STRING
 * COMMENT = "//" .*
 *
 * SPACE = [ \t]*
 * NAME = [a-z-AZ0-9_]+
 * VALUE = .* (but ends if "//" is found)
 * QUOTE_STRING = '"' [^"]* '"'
 *
 * Example of valid lines:
 * // comment
 * key = value // comment
 * #include "file.xcconfig" // comment
 *   key=value//comment
 *   #include"file.xcconfig"//comment
 *
 * if duplicated keys, last value wins
 *
 * #include behaviour:
 * path relative to current file
 * file not found ignores "root" config file
 * recursive include is ignored and causes no error
 *
 */

#import "XCConfigParser.h"

NSString * const XCConfigParserErrorDomain = @"XCConfigParserErrorDomain";
NSString * const XCConfigParserCharacterLocationKey = @"XCConfigParserCharacterLocationKey";
NSString * const XCConfigParserFileKey = @"XCConfigParserFileKey";
NSString * const XCConfigParserLineNumberKey = @"XCConfigParserLineNumberKey";

static NSUInteger const XCConfigParserMaxIncludeDepth = 30;

typedef enum {
    XCConfigParserTokenTypeComment,
    XCConfigParserTokenTypeHashName,
    XCConfigParserTokenTypeName,
    XCConfigParserTokenTypeQuotedString,
    XCConfigParserTokenTypeEquals,
    XCConfigParserTokenTypeString
} XCConfigParserTokenType;

@interface XCConfigParserToken : NSObject
@property(nonatomic, assign, readwrite) XCConfigParserTokenType tokenType;
@property(nonatomic, assign, readwrite) NSRange range;
@end

@implementation XCConfigParserToken
@synthesize tokenType = _tokenType;
@synthesize range = _range;
@end

static XCConfigParserToken *makeXCConfigParserToken(XCConfigParserTokenType tokenType,
                                                    NSUInteger location,
                                                    NSUInteger length) {
    XCConfigParserToken *token = [[[XCConfigParserToken alloc] init] autorelease];
    token.tokenType = tokenType;
    token.range = NSMakeRange(location, length);
    
    return token;
}

@interface XCConfigParserStatement : NSObject
@property(nonatomic, assign, readwrite) NSRange range;
@end

@implementation XCConfigParserStatement
@synthesize range = _range;
@end

@interface XCConfigParserStatementPair : XCConfigParserStatement
@property(nonatomic, copy, readwrite) NSString *key;
@property(nonatomic, copy, readwrite) NSString *value;
@end

@implementation XCConfigParserStatementPair
@synthesize key = _key;
@synthesize value = _value;
@end

@interface XCConfigParserStatementInclude : XCConfigParserStatement
@property(nonatomic, copy, readwrite) NSString *path;
@end

@implementation XCConfigParserStatementInclude
@synthesize path = _path;
@end

static NSUInteger lineNumberFromLocation(NSString *string, NSUInteger location) {
    __block NSUInteger lineNumber = 0;
    
    [string
     enumerateSubstringsInRange:NSMakeRange(0, [string length])
     options:NSStringEnumerationByLines
     usingBlock:^(NSString *substring,
                  NSRange substringRange,
                  NSRange enclosingRange,
                  BOOL *stop) {
         *stop = NSLocationInRange(location, enclosingRange);
         lineNumber++;
     }];
    
    return lineNumber;
}

static NSError *makeParserError(NSString *string,
                                NSUInteger location,
                                NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSString *description = [[[NSString alloc]
                              initWithFormat:format arguments:ap]
                             autorelease];
    va_end(ap);
    
    return [NSError errorWithDomain:XCConfigParserErrorDomain
                               code:0
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                     description,
                                     NSLocalizedDescriptionKey,
                                     [NSNumber numberWithInteger:location],
                                     XCConfigParserCharacterLocationKey,
                                     [NSNumber numberWithInteger:
                                      lineNumberFromLocation(string, location)],
                                     XCConfigParserLineNumberKey,
                                     nil]];
}

@interface XCConfigParser ()
+ (NSArray *)_tokenizeString:(NSString *)string
                       error:(NSError **)error;

+ (NSArray *)_parseTokens:(NSArray *)tokens
                   string:(NSString *)string
                    error:(NSError **)error;

+ (NSDictionary *)_dictionaryFromString:(NSString *)string
                        maxIncludeDepth:(NSUInteger)maxIncludeDepth
                        includeBasePath:(NSString *)includeBasePath
                                  error:(NSError **)error;

+ (NSDictionary *)_dictionaryFromFile:(NSString *)file
                      maxIncludeDepth:(NSUInteger)maxIncludeDepth
                                error:(NSError **)error;
@end

@implementation XCConfigParser

+ (NSArray *)_tokenizeString:(NSString *)string
                       error:(NSError **)error {
    enum {
        TokenizeStateWhitespace,
        TokenizeStateComment,
        TokenizeStateHashName, // #name
        TokenizeStateQuotedString, // "string"
        TokenizeStateName,
        TokenizeStateStringToCommentOrEndOfLine,
    } tokenizeState = TokenizeStateWhitespace;
    NSMutableArray *tokens = [NSMutableArray array];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableCharacterSet *nameSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [nameSet addCharactersInString:@"_"]; // hmm
    NSUInteger length = [string length];
    
    NSUInteger i = 0;
    NSUInteger tokenLocation = i;
    
    while (i < length) {
        unichar c  = [string characterAtIndex:i];
        unichar c1  = i < (length-1) ? [string characterAtIndex:i+1] : 0;
        
        if (tokenizeState == TokenizeStateWhitespace) {
            if (c == '=') {
                [tokens addObject:
                 makeXCConfigParserToken(XCConfigParserTokenTypeEquals, i, 1)];
                i++; // =
                tokenLocation = i;
                tokenizeState = TokenizeStateStringToCommentOrEndOfLine;
            } else if (c  == '#') {
                tokenLocation = i;
                tokenizeState = TokenizeStateHashName;
            } else if (c  == '"') {
                tokenLocation = i;
                tokenizeState = TokenizeStateQuotedString;
                i++; // skip "
            } else if (c  == '/' && c1 == '/') {
                tokenLocation = i;
                tokenizeState = TokenizeStateComment;
                i += 2; // skip //
            } else if ([nameSet characterIsMember:c]) {
                tokenLocation = i;
                tokenizeState = TokenizeStateName;
            } else if ([whitespaceSet characterIsMember:c]) {
                i++; // skip whitespace
            } else {
                *error = makeParserError(string, i, @"Unexpected character \"%C\"", c);
                return nil;
            }
        } else if (tokenizeState == TokenizeStateComment) {
            if (c == '\n') {
                [tokens addObject:
                 makeXCConfigParserToken(XCConfigParserTokenTypeComment,
                                         tokenLocation, i - tokenLocation)];
                tokenizeState = TokenizeStateWhitespace;
            } else {
                // char in comment
            }
            i++;
        } else if (tokenizeState == TokenizeStateName) {
            if ([nameSet characterIsMember:c] &&
                ![nameSet characterIsMember:c1]) {
                [tokens addObject:
                 // +1 to include current char also
                 makeXCConfigParserToken(XCConfigParserTokenTypeName,
                                         tokenLocation, i+1 - tokenLocation)];
                tokenizeState = TokenizeStateWhitespace;
            } else {
                // char in ident
            }
            i++;
        } else if (tokenizeState == TokenizeStateHashName) {
            if ([nameSet characterIsMember:c] &&
                ![nameSet characterIsMember:c1]) {
                [tokens addObject:
                 // +1 to include current char also
                 makeXCConfigParserToken(XCConfigParserTokenTypeHashName,
                                         tokenLocation, i+1 - tokenLocation)];
                tokenizeState = TokenizeStateWhitespace;
            } else {
                // char in ident
            }
            i++;
        } else if (tokenizeState == TokenizeStateQuotedString) {
            if (c == '"') {
                [tokens addObject:
                 // +1 to include current char also
                 makeXCConfigParserToken(XCConfigParserTokenTypeQuotedString,
                                         tokenLocation, i+1 - tokenLocation)];
                tokenizeState = TokenizeStateWhitespace;
            } else {
                // char in string until end if line
            }
            i++;
        } else if (tokenizeState == TokenizeStateStringToCommentOrEndOfLine) {
            if (c == '/' && c1 == '/') {
                [tokens addObject:
                 makeXCConfigParserToken(XCConfigParserTokenTypeString,
                                         tokenLocation, i - tokenLocation)];
                tokenizeState = TokenizeStateComment;
                i++;
            } else if (c == '\n') {
                [tokens addObject:
                 makeXCConfigParserToken(XCConfigParserTokenTypeString,
                                         tokenLocation, i - tokenLocation)];
                tokenizeState = TokenizeStateWhitespace;
            } else {
                // char in string until comment or end of line
            }
            i++;
        } else {
            NSAssert(NO, nil);
        }
    }
    
    // at end we should be in whitespace state
    if (tokenizeState != TokenizeStateWhitespace) {
        *error = makeParserError(string, length-1, @"Unexpected end");
        return nil;
    }
    
    return tokens;
}

+ (NSArray *)_parseTokens:(NSArray *)tokens
                   string:(NSString *)string
                    error:(NSError **)error {
    NSMutableArray *statements = [NSMutableArray array];
    
    // filter out comment tokens
    NSMutableArray *filteredTokens = [NSMutableArray array];
    for (XCConfigParserToken *token in tokens) {
        if (token.tokenType == XCConfigParserTokenTypeComment) {
            continue;
        }
        
        [filteredTokens addObject:token];
    }
    
    NSUInteger tokensCount = [filteredTokens count];
    for (NSUInteger i = 0; i < tokensCount; ) {
        XCConfigParserToken *token1 = [filteredTokens objectAtIndex:i];
        XCConfigParserToken *token2 = (i+1 < tokensCount ?
                                       [filteredTokens objectAtIndex:i+1] : nil);
        XCConfigParserToken *token3 = (i+2 < tokensCount ?
                                       [filteredTokens objectAtIndex:i+2] : nil);
        
        if (token1.tokenType == XCConfigParserTokenTypeName &&
            token2 != nil &&
            token2.tokenType == XCConfigParserTokenTypeEquals &&
            token3 != nil &&
            token3.tokenType == XCConfigParserTokenTypeString) {
            
            // name = value
            
            XCConfigParserStatementPair *pair = [[[XCConfigParserStatementPair alloc] init]
                                                 autorelease];
            pair.range = NSMakeRange(token1.range.location,
                                     NSMaxRange(token3.range) -
                                     token1.range.location);
            pair.key = [string substringWithRange:token1.range];
            pair.value = [[string substringWithRange:token3.range]
                          stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
            
            [statements addObject:pair];
            
            i += 3;
        } else if (token1.tokenType == XCConfigParserTokenTypeHashName &&
                   token2 != nil &&
                   token2.tokenType == XCConfigParserTokenTypeQuotedString) {
            
            // #directive "argument"
            
            NSString *directive = [string substringWithRange:token1.range];
            NSString *token2String = [string substringWithRange:token2.range];
            NSString *argument = [token2String substringWithRange:
                                  NSMakeRange(1, [token2String length]-2)];
            NSRange range = NSMakeRange(token1.range.location,
                                        NSMaxRange(token2.range) -
                                        token1.range.location);
            
            if ([directive isEqualToString:@"#include"]) {
                XCConfigParserStatementInclude *include = [[[XCConfigParserStatementInclude alloc] init]
                                                           autorelease];
                include.range = range;
                include.path = argument;
                [statements addObject:include];
            } else {
                *error = makeParserError(string, token1.range.location,
                                         @"Unknown directive %@", directive);
                return nil;
            }
            
            i += 2;
        } else {
            *error = makeParserError(string, token1.range.location,
                                     @"Parse error around %@",
                                     [string substringWithRange:token1.range]);
            return nil;
        }
    }
    
    return statements;
}

+ (NSDictionary *)_dictionaryFromString:(NSString *)string
                        maxIncludeDepth:(NSUInteger)maxIncludeDepth
                        includeBasePath:(NSString *)includeBasePath
                                  error:(NSError **)error {
    NSArray *tokens = [self _tokenizeString:string error:error];
    if (tokens == nil) {
        return nil;
    }
    
    NSArray *statements = [self _parseTokens:tokens string:string error:error];
    if (statements == nil) {
        return nil;
    }
    
    NSMutableDictionary *configDictionary = [NSMutableDictionary dictionary];
    for (XCConfigParserStatement *statement in statements) {
        if ([statement isKindOfClass:[XCConfigParserStatementPair class]]) {
            XCConfigParserStatementPair *pair = (id)statement;
            [configDictionary setObject:pair.value
                                 forKey:pair.key];
        } else if ([statement isKindOfClass:[XCConfigParserStatementInclude class]]) {
            XCConfigParserStatementInclude *include = (id)statement;
            
            if (maxIncludeDepth == 0) {
                // probably recursive include, Xcode does not give any
                // error so just ignore the include and continue
                continue;
            }
            
            NSString *includeFile = [[includeBasePath
                                      stringByAppendingPathComponent:include.path]
                                     stringByStandardizingPath];
            NSDictionary *includeConfigDictionary = [self
                                                     _dictionaryFromFile:includeFile
                                                     maxIncludeDepth:maxIncludeDepth-1
                                                     error:error];
            if (includeConfigDictionary == nil) {
                if ([[*error domain] isEqualToString:XCConfigParserErrorDomain]) {
                    // pass along error
                } else {
                    *error = makeParserError(string, include.range.location,
                                             @"Failed to include %@: %@",
                                             include.path, [*error localizedDescription]);
                }
                
                return nil;
            }
            
            [configDictionary addEntriesFromDictionary:includeConfigDictionary];
            
        } else {
            NSAssert(NO, @"");
        }
    }
    
    return configDictionary;
}

+ (NSDictionary *)dictionaryFromString:(NSString *)string
                       includeBasePath:(NSString *)includeBasePath
                                 error:(NSError **)error {
    return [self _dictionaryFromString:string
                       maxIncludeDepth:XCConfigParserMaxIncludeDepth
                       includeBasePath:includeBasePath
                                 error:error ?: &(NSError *){nil}];
}

+ (NSDictionary *)_dictionaryFromFile:(NSString *)file
                      maxIncludeDepth:(NSUInteger)maxIncludeDepth
                                error:(NSError **)error {
    NSString *string = [NSString stringWithContentsOfFile:file usedEncoding:nil error:error];
    if (string == nil) {
        return nil;
    }
    
    NSString *standardizedFile = [file stringByStandardizingPath];
    NSString *includeBasePath = [standardizedFile stringByDeletingLastPathComponent];
    if ([includeBasePath isEqualToString:@""]) {
        // TODO: can this happen? only if file is not absolute
        includeBasePath = [[NSFileManager defaultManager] currentDirectoryPath];
    }
    
    NSDictionary *configDictionary = [self _dictionaryFromString:string
                                                 maxIncludeDepth:maxIncludeDepth
                                                 includeBasePath:includeBasePath
                                                           error:error];
    if (configDictionary == nil) {
        if ([[*error userInfo] objectForKey:XCConfigParserFileKey] == nil) {
            // no file has been set in error yet, include file key.
            // this makes sure the deepest error gets reported.
            
            NSMutableDictionary *userInfo = [NSMutableDictionary
                                             dictionaryWithDictionary:[*error userInfo]];
            [userInfo setObject:standardizedFile forKey:XCConfigParserFileKey];
            *error = [NSError
                      errorWithDomain:XCConfigParserErrorDomain
                      code:0
                      userInfo:userInfo];
        } else {
            // just pass along the error unchanged
        }
        
        return nil;
    }
    
    return configDictionary;
}

+ (NSDictionary *)dictionaryFromFile:(NSString *)file
                               error:(NSError **)error {
    return [self _dictionaryFromFile:file
                     maxIncludeDepth:XCConfigParserMaxIncludeDepth
                               error:error ?: &(NSError *){nil}];
}

@end
