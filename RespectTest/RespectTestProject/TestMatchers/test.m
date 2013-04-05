// static match
// @LintFile: static
// @ExpectedMissing: static

// objective-c signature source match 
@interface Test : NSObject
// @LintSourceMatch: [Test testFile:@ anotherFile:@]
// @LintFile: objc-$1-$2-{a,b}
// @LintWarning: objc-$1-$2
// @ExpectedMissing: objc-a-b-a
// @ExpectedMissing: objc-a-b-b
// @ExpectedWarning: TestMatchers/test.m: objc-a-b
+ (void)testFile:(NSString *)file anotherFile:(NSString *)anotherFile;
+ (void)testFile2:(NSString *)file anotherFile:(NSString *)anotherFile;
@end

@implementation Test
+ (void)testFile:(NSString *)file anotherFile:(NSString *)anotherFile {    
}
+ (void)testFile2:(NSString *)file anotherFile:(NSString *)anotherFile {
}
@end

void test1() {
    [Test testFile:@"a" anotherFile:@"b"];
}

// wildcard identifier
// @LintSourceMatch: [Te*t testFile2:@ anotherFile:@]
// @LintFile: wildcard-$1-$2
// @ExpectedMissing: wildcard-a-b

void test2() {
    [Test testFile2:@"a" anotherFile:@"b"];
}

// match identifier
// @LintSourceMatch: test3($, $)
// @LintFile: identifier-$1-$2
// @ExpectedMissing: identifier-a-b

void test3(char *a, NSString *b) {
    test3(a, b);
}

// c signature source match

// @LintSourceMatch: test4(@, @)
// @LintFile: c-$1-$2-{a,b}
// @LintWarning: c-$1-$2
// @ExpectedMissing: c-a-b-a
// @ExpectedMissing: c-a-b-b
// @ExpectedWarning: TestMatchers/test.m: c-a-b

void test4(char *a, NSString *b) {
    test4("a", @"b");
}

// regex source match

// @LintSourceMatch: /FILE_(.*)_(.*)/i
// @LintFile: regex-$1-$2
// @ExpectedMissing: regex-a-b
// @ExpectedMissing: regex-a-c

// @LintSourceMatch: /IMAGE_(.*)_(.*)/i
// @LintImage: regex-$1-$2.png
// @ExpectedMissing: regex-a-b.png
// @ExpectedMissing: regex-a-b@2x.png
// @ExpectedMissing: regex-a-c.png
// @ExpectedMissing: regex-a-c@2x.png

#define FILE_a_b
#define file_a_c
#define IMAGE_a_b
#define image_a_c

int main(int argc, char *argv[]) {
    return 0;
}
