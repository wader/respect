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

#import "ResourceLinter.h"
#import "PBXProject.h"
#import "ResourceLinterXcodeProjectSource.h"
#import "ResourceLinterAbstractReport.h"
#import "ResourceLinterXcodeReport.h"
#import "ResourceLinterCliReport.h"
#import "ResourceLinterConfigReport.h"
#include <getopt.h>
#include "version.h"

static void fprintf_nsstring(FILE *stream, NSString *format, va_list va) {
    fprintf(stream, "%s\n",
            [[[[NSString alloc] initWithFormat:format arguments:va]
              autorelease]
             cStringUsingEncoding:NSUTF8StringEncoding]);
}

static void error(NSString *format, ...) {
    va_list va;
    va_start(va, format);
    fprintf_nsstring(stderr, format, va);
    va_end(va);
}

static void help(const char *argv0) {
    printf("Usage: %s [-cndv] XcodeProjectPath [TargetName] [ConfigurationName]\n"
           "  XcodeProjectPath                   Path to XcodeProject file or directory\n"
           "  TargetName (First native target)   Native target name to lint\n"
           "  ConfigurationName (Release)        Build configuration name\n"
           "\n"
           "  No arguments are required when running as a Xcode run script.\n"
           "\n"
           "  -c, --config Path   Configuration file ($SRCROOT/.respect)\n"
           "  -n, --nodefault     Don't use default configuration\n"
           "  -d, --dumpconfig    Dump interpreted configuration\n"
           "  -v, --version       Print build version\n"
           "  --spfeatures Path   Spotify features path\n"
           ,
           argv0);
}

int main(int argc,  char *const argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    char *argv0 = argv[0];
    NSString *configPath = nil;
    BOOL parseDefaultConfig = YES;
    BOOL dumpConfig = NO;
    NSString *spFeaturesPath = NULL;
    
    static struct option longopts[] = {
        {"help", no_argument, NULL, 'h'},
        {"config", required_argument, NULL, 'c'},
        {"nodefault", no_argument, NULL, 'n'},
        {"dumpconfig", no_argument, NULL, 'd'},
        {"version", no_argument, NULL, 'v'},
        {"spfeatures", required_argument, NULL, 's'},
        {NULL, 0, NULL, 0}
    };
    
    int c;
    while ((c = getopt_long(argc, argv, "hc:ndvs:", longopts, NULL)) != -1) {
        if (c == 'h') {
            help(argv0);
            return EXIT_SUCCESS;
        } else if (c == 'c') {
            configPath = [NSString stringWithUTF8String:optarg];
        } else if (c == 'n') {
            parseDefaultConfig = NO;
        } else if (c == 'd') {
            dumpConfig = YES;
        } else if (c == 'v') {
            fprintf(stdout, "%s\n", GIT_HASH);
            return EXIT_SUCCESS;
        } else if (c == 's') {
            spFeaturesPath = [NSString stringWithUTF8String:optarg];
        } else {
            return EXIT_FAILURE;
        }
    }
    
    argc -= optind;
    argv += optind;
    
    // try to get configuration from env
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    NSString *xcodeProjectPath = [env objectForKey:@"PROJECT_FILE_PATH"];
    NSString *targetName = [env objectForKey:@"TARGET_NAME"];
    NSString *configurationName = [env objectForKey:@"CONFIGURATION"] ?: @"Release";
    // assume Xcode if PROJECT_FILE_PATH env was found else CLI
    Class lintReportClass = (xcodeProjectPath != nil ?
                             [ResourceLinterXcodeReport class] :
                             [ResourceLinterCliReport class]);
    
    if (dumpConfig) {
        lintReportClass = [ResourceLinterConfigReport class];
    }
    
    if (argc > 0) {
        xcodeProjectPath = [NSString stringWithCString:argv[0]
                                              encoding:NSUTF8StringEncoding];
    } else if (xcodeProjectPath == nil) {
        help(argv0);
        return EXIT_FAILURE;
    }
    
    if (argc > 1) {
        targetName = [NSString stringWithCString:argv[1]
                                        encoding:NSUTF8StringEncoding];
    }
    
    if (argc > 2) {
        configurationName = [NSString stringWithCString:argv[2]
                                               encoding:NSUTF8StringEncoding];
    }
    
    PBXProject *pbxProject = [PBXProject pbxProjectFromPath:xcodeProjectPath
                                                environment:env];
    if (pbxProject == nil) {
        error(@"Failed to read %@", xcodeProjectPath);
        return EXIT_FAILURE;
    }
    
    NSArray *nativeTargetNames = [pbxProject nativeTargetNames];
    if (targetName == nil) {
        if ([nativeTargetNames count] == 0) {
            error(@"No native targets found in project file.");
            return EXIT_FAILURE;
        }
        
        targetName = [nativeTargetNames objectAtIndex:0];
    } else {
        if (![nativeTargetNames containsObject:targetName]) {
            error(@"No native target named \"%@\" found.", targetName);
            error(@"Suggested targets: %@",
                  [nativeTargetNames componentsJoinedByString:@", "]);
            return EXIT_FAILURE;
        }
    }
    
    PBXNativeTarget *target = [pbxProject nativeTargetNamed:targetName];
    NSArray *configurationNames = [target configurationNames];
    if (![configurationNames containsObject:configurationName]) {
        error(@"No configuration named \"%@\" found for native target \"%@\".",
              configurationName, targetName);
        error(@"Suggested configurations: %@",
              [configurationNames componentsJoinedByString:@", "]);
        return EXIT_FAILURE;
    }
    
    ResourceLinterXcodeProjectSource *projectSource = [[[ResourceLinterXcodeProjectSource alloc]
                                                        initWithPBXProject:pbxProject
                                                        targetName:targetName
                                                        configurationName:configurationName]
                                                       autorelease];
    if (spFeaturesPath != nil) {
        [projectSource addSpotifyFeaturesAtPath:spFeaturesPath];
    }
    
    ResourceLinter *linter = [[[ResourceLinter alloc]
                               initWithResourceLinterSource:projectSource
                               configPath:configPath
                               parseDefaultConfig:parseDefaultConfig]
                              autorelease];
    
    ResourceLinterAbstractReport *lintReport = [[[lintReportClass alloc]
                                                 initWithLinter:linter]
                                                autorelease];
    
    fprintf(stdout, "%s", [lintReport.outputBuffer UTF8String]);
    
    // as we should not have any side effects we can safly skip to drain the
    // autorelease pool and by that save some time by not calling release
    // and dealloc on autoreleased objects
    //[pool drain];
    (void)pool;
    
    return EXIT_SUCCESS;
}
