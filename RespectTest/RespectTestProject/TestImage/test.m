#import <UIKit/UIKit.h>

// all via options
// @LintImage: a @1x @2x ~ipad ~iphone ~any png
// @ExpectedMissing: a.png
// @ExpectedMissing: a@2x.png
// @ExpectedMissing: a~ipad.png
// @ExpectedMissing: a@2x~ipad.png
// @ExpectedMissing: a~iphone.png
// @ExpectedMissing: a@2x~iphone.png

// device from existing files
// @LintImage: b @1x @2x
// @ExpectedMissing: b@2x.png
// @ExpectedMissing: b@2x~ipad.png
// @ExpectedMissing: b@2x~iphone.png

// scale from existing files
// @LintImage: c ~iphone ~ipad ~any
// @ExpectedMissing: c~ipad.png
// @ExpectedMissing: c@2x~ipad.png
// @ExpectedMissing: c~iphone.png
// @ExpectedMissing: c@2x~iphone.png

// TODO: known incompatibility: UIImage finds d.png when d~iphone.png is missing
// @LintImage: d~iphone.png @1x
// @ExpectedMissing: d~iphone.png
// @ExpectedUnused: d.png

// test 568h
// @LintImage: e @1x @2x 568h

int main(int argc, char *argv[]) {
    @autoreleasepool {
    }
}
