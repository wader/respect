// Implementation of some of the classes found in a project.pbxproj file.
// Will usually be instantiated during unarchive by PBXUnarchiver.
//
// Use +[PBXProject pbxProjectFromPath:...] to instantiate and validate
// a whole project tree from a file. It will take care of associating group and
// build configuration parent objects etc.
// Use -[PBXProject prepareWithEnvironment...] to configure the project for
// a specific target and build environment.
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
 *
 *  A decoded and valid PBXProject tree looks like this:
 *
 *  root PBXProject
 *    buildConfigurationList XCConfigurationList
 *      buildConfigurations NSArray
 *        XCBuildConfiguration
 *          name NSString
 *          buildSettings NSDictionary
 *          parent is nil, could point to Xcode defaults later
 *          baseConfigurationReference PBXFileReference
 *          baseConfiguration NSDictionary, nil or parsed baseConfigurationReference
 *    targets NSArray
 *      PBXNativeTarget
 *        name NSString
 *        buildPhases NSArray
 *          PBXSourcesBuildPhase
 *            files NSArray
 *              PBXBuildFile
 *                fileRef PBXFileReference | PBXVariantGroup | XCVersionGroup
 *                  path NSString
 *                  sourceTree NSString
 *                  parent PBXNode, is parent node in mainGroup tree
 *                  project PBXProject, is root project
 *          PBXResourcesBuildPhase
 *            files NSArray
 *              PBXBuildFile
 *                fileRef PBXFileReference | PBXVariantGroup | XCVersionGroup
 *                  path NSString
 *                  sourceTree NSString
 *                  parent PBXNode, is parent node in mainGroup tree
 *                  project PBXProject, is root project
 *        buildConfigurationList XCConfigurationList
 *          buildConfigurations NSArray
 *            XCBuildConfiguration
 *              name NSString
 *              buildSettings NSDictionary
 *              parent XCBuildConfiguration, is corresponding build configuration root project
 *              baseConfigurationReference PBXFileReference
 *              baseConfiguration NSDictionary, nil or parsed baseConfigurationReference
 *    mainGroup PBXGroup
 *      path NSString
 *      sourceTree NSString
 *      children NSArray
 *      parent PBXNode, is parent node
 *      project PBXProject, is root project
 *         PBXGroup
 *           ... nested group ...
 *         PBXVariantGroup
 *           path NSString
 *           sourceTree NSString
 *           parent PBXNode, is parent node
 *           project PBXProject, is root project
 *         PBXFileReference
 *           name NSString
 *           path NSString
 *           sourceTree NSString
 *           parent PBXNode, points to parent node
 *           project PBXProject, points to root project
 *    knownRegions NSArray
 *      NSString
 *    parent PBXNode, is nil
 *    project PBXProject, is self
 */

#import <Foundation/Foundation.h>

NSString * const PBXProjectErrorDomain;

@class PBXProject;

// abstract class, does not exist in PBX files
@interface PBXNode : NSObject
@property(nonatomic, retain, readonly) NSString *path; // can be nil
@property(nonatomic, retain, readonly) NSString *sourceTree;
@property(nonatomic, assign, readonly) PBXNode *parent;
@property(nonatomic, assign, readonly) PBXProject *project;
- (NSString *)buildPath;
@end


@interface PBXFileReference : PBXNode
@property(nonatomic, retain, readonly) NSString *name; // can be nil
- (BOOL)isFolderReference;
- (NSArray *)subPathsForFolderReference;
@end


@interface PBXGroup : PBXNode
@property(nonatomic, retain, readonly) NSString *name; // can be nil
@property(nonatomic, retain, readonly) NSArray *children;
- (void)recursivelySetParent:(PBXNode *)parent andProject:(PBXProject *)project;
@end


@interface PBXVariantGroup : PBXGroup
@end


@interface XCVersionGroup : PBXGroup
@property(nonatomic, retain, readonly) PBXFileReference *currentVersion;
@end


@interface PBXBuildFile : NSObject
// fileRef can be PBXFileReference or XCVersionGroup
@property(nonatomic, retain, readonly) PBXNode *fileRef;
@end


@interface XCBuildConfiguration : NSObject
@property(nonatomic, retain, readonly) NSString *name;
@property(nonatomic, retain, readonly) PBXFileReference *baseConfigurationReference;
@property(nonatomic, retain, readonly) NSDictionary *buildSettings;
@property(nonatomic, assign, readonly) XCBuildConfiguration *parent;
@property(nonatomic, assign, readonly) PBXProject *project;

// not in project file, nil or parsed version of baseConfigurationReference
@property(nonatomic, retain, readonly) NSDictionary *baseConfiguration;

- (id)resolveConfigValueNamed:(NSString *)configName;
- (NSArray *)resolveConfigPathsNamed:(NSString *)configName
               usingWorkingDirectory:(NSString *)workingDirectory;
@end


@interface XCConfigurationList : NSObject
@property(nonatomic, retain, readonly) NSArray *buildConfigurations;
@end


// abstract class, does not exist in PBX files
@interface PBXBuildPhase : NSObject
@property(nonatomic, retain, readonly) NSArray *files;
@end


@interface PBXSourcesBuildPhase : PBXBuildPhase
@end


@interface PBXResourcesBuildPhase : PBXBuildPhase
@end


@interface PBXNativeTarget : NSObject
@property(nonatomic, retain, readonly) NSString *name;
@property(nonatomic, retain, readonly) NSArray *buildPhases;
@property(nonatomic, retain, readonly) XCConfigurationList *buildConfigurationList;
- (NSArray *)configurationNames;
- (XCBuildConfiguration *)configurationNamed:(NSString *)buildConfigName;
@end


@interface PBXProject : PBXNode
@property(nonatomic, retain, readonly) XCConfigurationList *buildConfigurationList;
@property(nonatomic, retain, readonly) NSArray *targets;
@property(nonatomic, retain, readonly) NSArray *knownRegions;
@property(nonatomic, retain, readonly) PBXGroup *mainGroup;

@property(nonatomic, retain, readonly) NSDictionary *environment;
@property(nonatomic, retain, readonly) NSString *pbxFilePath;

+ (PBXProject *)pbxProjectFromPath:(NSString *)path
                             error:(NSError **)error;

- (BOOL)prepareWithEnvironment:(NSDictionary *)environment
                  nativeTarget:(PBXNativeTarget *)nativeTarget
            buildConfiguration:(XCBuildConfiguration *)buildConfiguration
                         error:(NSError **)error;

- (NSString *)lookupEnvironmentName:(NSString *)name;
- (NSString *)pathForSourceTree:(NSString *)sourceTree;
- (NSString *)projectName;
- (NSString *)projectPath;
- (NSString *)sourceRoot;
- (NSArray *)nativeTargetNames;
- (NSArray *)nativeTargets;
- (PBXNativeTarget *)nativeTargetNamed:(NSString *)targetName;

@end
