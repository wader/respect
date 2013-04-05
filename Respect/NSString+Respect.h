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

@interface NSString (Respect)

- (NSString *)respect_stringByEscapingCharactesInSet:(NSCharacterSet *)set;

// "\\ \a" -> "\ a"
- (NSString *)respect_stringByUnEscapingCharactersInSet:(NSCharacterSet *)set;
- (NSString *)respect_stringByUnEscaping;

// like stringWithContentsOfFile:usedEncoding:error: but tries some
// encodings first
+ (NSString *)respect_stringWithContentsOfFileTryingEncodings:(NSString *)path
                                                        error:(NSError **)error;

// "xb" strip suffix "b" -> "x"
- (NSString *)respect_stringByStripSuffix:(NSString *)suffix;

// "xb" strip suffixes ["a", "b"] -> "x"
// "xa" strip suffixes ["a", "b"] -> "x"
- (NSString *)respect_stringByStripSuffixes:(NSArray *)suffixes;

// "bx" strip suffixes ["a", "b"] -> "x"
// "ax" strip suffixes ["a", "b"] -> "x"
- (NSString *)respect_stringByStripPrefixes:(NSArray *)prefixes;

// "xa" suffixes in ["a", "b"] -> "a"
// "xb" suffixes in ["a", "b"] -> "b"
- (NSString *)respect_stringSuffixInArray:(NSArray *)suffixes;

// with prefix "/some": "/some/path" -> "path", "/another/path" -> "/another/path"
- (NSString *)respect_stringRelativeToPathPrefix:(NSString *)pathPrefix;

// "$0 $1 $2" replace with parameters ["a", "b"] -> "a b $2"
- (NSString *)respect_stringByReplacingParameters:(NSArray *)parameters;

// "a{b,c}{d,e}" -> ["abd", "abe", "acd", "ace"]
- (NSArray *)respect_permutationsUsingGroupCharacterPair:(NSString *)pair
                                          withSeparators:(NSString *)separators;

// "b" relative to "a" -> "a/b"
// "../b" relative to "/a/c" -> "/a/b"
// "/b" relative to "a" -> "/b"
- (NSString *)respect_stringByResolvingPathRealtiveTo:(NSString *)path;

// "image@2x~ipad.png" -> "image"
- (NSString *)respect_stringByNormalizingIOSImageName;

// "aba" replace [a] with ' ' -> " b "
- (NSString *)respect_stringByReplacingCharactersInSet:(NSCharacterSet *)set
                                         withCharacter:(unichar)character;

// "test" distance to "tst" -> 1
- (NSUInteger)respect_levenshteinDistanceToString:(NSString *)string;

// "test" suggestions ["tst", "ts"] max distance 1 -> "tst"
- (NSString *)respect_stringBySuggestionFromArray:(NSArray *)suggestions
                             maxDistanceThreshold:(NSUInteger)maxDistanceThreshold;

// 'a "b\"" c' -> ['a', 'b"', 'c']
- (NSArray *)respect_componentsSeparatedByWhitespaceAllowingQuotes;

// 'a' -> 'a'
// 'a\"' -> 'a\\\"'
// 'a \"' -> '"a \\\""'
- (NSString *)respect_stringByQuoteAndEscapeIfNeeded;

// '\t\r\n a \n\r\t' -> 'a'
- (NSString *)respect_stringByTrimmingWhitespace;

@end
