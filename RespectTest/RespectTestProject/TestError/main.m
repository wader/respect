
// no argument
// @LintFile:
// @ExpectedConfigError: TestError/main.m: No arguments

// no actions
// @LintSourceMatch: [a b:@]
// @ExpectedConfigError: TestError/main.m: Source matcher has no actions

// no actions
// @LintResourceMatch: a
// @ExpectedConfigError: TestError/main.m: Resource matcher has no actions

// malformed signature
// @LintSourceMatch: [test
// @LintFile: $1
// @ExpectedConfigError: TestError/main.m: Matcher error: Signature has no parameters

// malformed regex
// @LintSourceMatch: /*?/
// @LintFile: $1
// @ExpectedConfigError: TestError/main.m: Matcher error: The value “*?” is invalid.

// malformed action arguments
// @LintSourceMatch: [a b:@]
// @LintFile: "$1" "
// @LintFile: $1 "
// @ExpectedConfigError: TestError/main.m: Unbalanced quotes
// @ExpectedConfigError: TestError/main.m: Source matcher do not match anything

// source matcher that do not match anything
// @LintSourceMatch: [donot match]
// @LintFile: file
// @ExpectedConfigError: TestError/main.m: Source matcher do not match anything

// resource matcher that do not match anything
// @LintResourceMatch: donotmatch
// @LintFile: file
// @ExpectedConfigError: TestError/main.m: Resource matcher do not match any bundle files

// unknown options
// @LintSourceMatch: [a b:@]
// @LintFile: $1 unknown
// @ExpectedConfigError: TestError/main.m: Unknown options unknown

// unknown options
// @LintSourceMatch: [a b:@]
// @LintFile: $1 all any optional
// @ExpectedConfigError: TestError/main.m: Only one of all, any or optional can be specified

// precompiled header configured but missing
// @ExpectedLintError: TestError/TestError-Prefix.pch: Failed to read precompiled header

// malformed info.plist file
// @ExpectedLintError: TestError/TestError-Info.plist: Failed to parse Info.plist

// unknown lint config
// @LintImmage:
// @ExpectedConfigError: TestError/main.m: Did you mean @LintImage?

// malformed lint config, missing colon
// @LintDummy arg
// @ExpectedConfigError: TestError/main.m: Missing colon, did you mean @LintDummy: arg?
// @ExpectedConfigError: TestError/main.m: Unknown config @LintDummy

// @LintIgnoreMissing: /*?/
// @ExpectedConfigError: TestError/main.m: The value “*?” is invalid.

// @ExpectedWarning: TestError/b/collision: Bundle path "collision" collides with TestError/a/collision
// @ExpectedUnused: collision

// @ExpectedWarning: TestError/multiple: Bundle path "multiple" copied multiple times
// @ExpectedUnused: multiple

int main(int argc, char *argv[]) {
}
