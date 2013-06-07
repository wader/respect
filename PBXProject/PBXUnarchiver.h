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
 * Unarchiver for the Xcode project file format.
 *
 * If the allowedClasses property is set only classes found in the set is
 * allowed to be instantiated, if not found in set the object will be ignored.
 *
 * When unarchiving an object only keys that have a matching property name in
 * the instantiated class will be recursively unarchived.
 */

#import <Foundation/Foundation.h>

@interface PBXUnarchiver : NSObject
@property(nonatomic, strong, readwrite) NSSet *allowedClasses;

- (id)initWithFile:(NSString *)path;
- (id)decodeObject;
@end
