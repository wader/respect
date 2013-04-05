// @ExpectedWarning: TestIOSDefault/source.m: Source code file included in bundle
// @ExpectedWarning: TestIOSDefault/source.cpp: Source code file included in bundle
// @ExpectedWarning: TestIOSDefault/source.mm: Source code file included in bundle
// @ExpectedWarning: TestIOSDefault/source.h: Source code file included in bundle
// @ExpectedWarning: TestIOSDefault/readme.txt: Documentation file included in bundle
// @ExpectedWarning: TestIOSDefault/image~ipad@2x.png: Invalid ~device/@scale order in filename

// @ExpectedUnused: source.m
// @ExpectedUnused: source.cpp
// @ExpectedUnused: source.mm
// @ExpectedUnused: source.h
// @ExpectedUnused: readme.txt
// @ExpectedUnused: image~ipad@2x.png

int main(int argc, char *argv[])
{
    @autoreleasepool {
        [UIImage imageNamed:@"image"];
        
        // @ExpectedMissing: image2@2x.png
        [UIImage imageNamed:@"image2"];
        
        [NSData dataWithContentsOfFile:@"file.txt"];
    }
}
