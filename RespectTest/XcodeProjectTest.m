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

#import "XcodeProjectTest.h"
#import "PBXProject.h"

@implementation XcodeProjectTest

- (void)test_xcodeProject {
    PBXProject *pbxProject = [PBXProject
                              pbxProjectFromPath:
                              [[[NSFileManager defaultManager] currentDirectoryPath]
                               stringByAppendingPathComponent:@"RespectTest/Test.xcodeproj"]
                              environment:nil];
    
    NSArray *expectedTagets = [NSArray arrayWithObject:@"Test"];
    NSArray *expectedConfigurations = [NSArray arrayWithObjects:@"Debug", @"Release", nil];
    
    STAssertEqualObjects([pbxProject nativeTargetNames], expectedTagets, nil);
    
    PBXNativeTarget *nativeTarget = [pbxProject nativeTargetNamed:@"Test"];
    
    STAssertEqualObjects([nativeTarget configurationNames], expectedConfigurations, nil);
}

@end
