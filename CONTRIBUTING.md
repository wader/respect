Here are some guidelines if you want to help improve respect.

#### Code style

Please follow the current style and use spaces for indentation and indent width
set to 4.

#### Unit tests

Write new or update the unit test and test cases in the test Xcode project when
adding or changing things.

When running the unit tests one test consists of running respect on a Xcode
test project called RespectTestProject that is located in the RespectTest
directory.

Make sure the test code coverage stays high, it is currently above 91.5% and it
would be nice to keep it that way. The test target is configured to generate
coverage reports and you can use [coverstory](http://code.google.com/p/coverstory/)
if you want to use a user-friendly gcov interface.

#### Call tree overview

main

* ResourceLinterXcodeProjectSource
  * PBXProject
    PBXUnarchiver
    *  Instantiates various PBXProject classes to create the project class graph
  * Add precompiled header as source and included headers recursively
  * Add info.plist path
  * Collect resource paths
    * Rename xib to nib to reflect actual path in bundle
    * Check for collisions
  * Collect sources files and included headers recursively
* ResourceLinter
  * initWithResourceLinterSource
    * lint
      * Build dictionaries of all resources
        One with bundle path one with lower case bundle path as key
        Lower case is used for missing file name hints
      * Add default config
      * Add config from .respect
      * Add config from source files
      * Perform matchers
        * Perform actions for source, resource or static matchers
          * Adds references, warnings etc
          * Image names smartness here
          * Filename casing hints
          * Nib
          * InfoPlist
          * Warning
      * Collect missing resources
      * Collect unused resources
      * Filter missing and unused based on ignore config
* ResourceLinterAbstractReport
  * initWithLinter
     * Outputs report, CLI, Xcode, dump interpreted config 

#### TODO and ideas

Add only-@2x support to LintImage somehow (the case when iOS downscales the @1x for you)

Support shared schemas somehow?

Override defaults, use a signature "ident" to override?

Find missing and unused localization strings

Read image dimensions and warn about wrong scale dimensions

File size stats?

-Werror thingy for Xcode output

Combined matchers

Cache or PCRE for speed

Objective-C tidy

HTML report etc? with refes etc?

Show matched resources per matcher, matchers per resources? (also dot output?)

Lint target dependencies

Handle copy phase somehow?

Action adding actions dynamically? for NIB, infoplist actions etc?

Handle bundles

Storyboard

Better errors for "any"

Multiple precompiled headers? possible?

Use clang for source matching?

