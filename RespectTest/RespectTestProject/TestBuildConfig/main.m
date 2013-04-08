
// build config test:
// info.plist via variable $(TARGET_NAME)

// header search path config
#import "inherited.h"
#import "recursive.h"
#import "target.h"
// @ExpectedMissing: inherited
// @ExpectedMissing: recursive
// @ExpectedMissing: target

// @ExpectedMissing: prefixheader

int main(int argc, char *argv[]) {
}
