// @LintFile: missing
// @LintIgnoreMissing: missing

// @LintIgnoreUnused: readme.txt
// @LintIgnoreUnused: unused1
// @LintIgnoreUnused: unused2

// @LintIgnoreWarning: TestIgnore/readme.txt

// @LintIgnoreError: TestIgnore/missing.m

// @LintIgnoreError: TestIgnore/missing_file

// @LintIgnoreError: TestIgnore/missing_folder

// fnmatch
// @LintFile: a{a,b,c}
// @LintIgnoreMissing: a{a,b,c}

// @LintImage: b
// @LintIgnoreMissing: b{,@2x}

// regex
// @LintFile: b{a,b,c}
// @LintIgnoreMissing: /b[abc]/

// @LintResourceMatch: unused1
// @LintWarning: match $1
// @LintIgnoreWarning: TestIgnore/unused1

// @LintResourceMatch: /^(unused2)$/
// @LintWarning: match $1
// @LintIgnoreWarning: TestIgnore/unused2
