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

// TODO:
// written to support pcre compiled with utf8 support
// default osx pcre library seems to not have pcre(16|32)_ symbols
// just as nsre enumrate is thread and reentrant safe
/*
 PCRE_CONFIG_UTF8 0 1
 PCRE_CONFIG_UTF16 -3 1
 PCRE_CONFIG_UNICODE_PROPERTIES 0 1
 PCRE_CONFIG_JIT -3 1
 PCRE_CONFIG_NEWLINE 0 10
 PCRE_CONFIG_BSR 0 0
 PCRE_CONFIG_LINK_SIZE 0 2
 PCRE_CONFIG_POSIX_MALLOC_THRESHOLD 0 10
 PCRE_CONFIG_MATCH_LIMIT 0 10000000
 PCRE_CONFIG_MATCH_LIMIT_RECURSION 0 10000000
 PCRE_CONFIG_STACKRECURSE 0 1
 */

#import "PCRegularExpression.h"
#include "pcre.h"

// number of trailing bytes after first byte in codepoint
#define UTF8_BYTE_TRAIL_COUNT(b) (1+((b)>0xe0)+((b)>0xf0)+((b)>0xf8)+((b)>0xfc))

void dump_pcre_config() {
    const void *where = NULL;
    
    printf("PCRE_CONFIG_UTF8 %d %d\n", pcre_config(PCRE_CONFIG_UTF8, &where), (int)where);
    printf("PCRE_CONFIG_UTF16 %d %d\n", pcre_config(PCRE_CONFIG_UTF16, &where), (int)where);
    printf("PCRE_CONFIG_UNICODE_PROPERTIES %d %d\n", pcre_config(PCRE_CONFIG_UNICODE_PROPERTIES, &where), (int)where);
    printf("PCRE_CONFIG_JIT %d %d\n", pcre_config(PCRE_CONFIG_JIT, &where), (int)where);
    //printf("PCRE_CONFIG_JITTARGET %d %s\n", pcre_config(PCRE_CONFIG_JIT, &where), (char *)where);
    printf("PCRE_CONFIG_NEWLINE %d %d\n", pcre_config(PCRE_CONFIG_NEWLINE, &where), (int)where);
    printf("PCRE_CONFIG_BSR %d %d\n", pcre_config(PCRE_CONFIG_BSR, &where), (int)where);
    
    printf("PCRE_CONFIG_LINK_SIZE %d %d\n", pcre_config(PCRE_CONFIG_LINK_SIZE, &where), (int)where);
    
    printf("PCRE_CONFIG_POSIX_MALLOC_THRESHOLD %d %d\n", pcre_config(PCRE_CONFIG_POSIX_MALLOC_THRESHOLD, &where), (int)where);
    printf("PCRE_CONFIG_MATCH_LIMIT %d %d\n", pcre_config(PCRE_CONFIG_MATCH_LIMIT, &where), (int)where);
    printf("PCRE_CONFIG_MATCH_LIMIT_RECURSION %d %d\n", pcre_config(PCRE_CONFIG_MATCH_LIMIT_RECURSION, &where), (int)where);
    printf("PCRE_CONFIG_STACKRECURSE %d %d\n", pcre_config(PCRE_CONFIG_STACKRECURSE, &where), (int)where);
    
    
}

// check a range of bytes if any byte has bit 8 set
static unsigned int is_ascii_only(const char *start, const char *end) {
    // check in 64 bit chunks if enough bytes
    if (end - start >= sizeof(uint64_t)) {
        uint64_t *p;
        
        // align p pointer
        uintptr_t bytes = end - start;
        uintptr_t align_bytes = (sizeof(*p) - (uintptr_t)start) % sizeof(*p);
        for (uintptr_t i = align_bytes; i > 0; i--, start++) {
            if (*start & 0x80) {
                return 0;
            }
        }
        
        p = (uint64_t *)start;
        bytes -= align_bytes;
        
        // check if highest bit in each byte is set
        uintptr_t chunks = bytes / (sizeof(*p));
        for (uintptr_t i = 0; i < chunks; i++) {
            if (*p++ & 0x8080808080808080) {
                return 0;
            }
        }
        
        start = (const char*)p;
    }
    
    // check remainig bytes
    for (; start < end; start++) {
        if (*start & 0x80) {
            return 0;
        }
    }
    
    return 1;
}

/*
 void utf8_is_ascii_only_test() {
 char *s = malloc(10000000);
 memset(s, 0, 10000000);
 
 int n = 0;
 
 for (int i = 0; i < 200; i++) {
 n += utf8_is_ascii_only(s+1, s+10000000);
 }
 
 NSLog(@"%d", n);
 
 free(s);
 }
 */

typedef uintptr_t (*codepoints_between_f)(const char *start, const char *end);
typedef uintptr_t (*bytes_to_skip_n_codepoints_f)(const char *start, uintptr_t codepoints);

static uintptr_t ascii_codepoints_between(const char *start, const char *end) {
    return end - start;
}

static size_t ascii_bytes_to_skip_n_codepoints(const char *start,
                                               uintptr_t codepoints) {
    return codepoints;
}

static uintptr_t utf8_codepoints_between(const char *start, const char *end) {
    size_t codepoints = 0;
    
    while (start < end) {
        unsigned char b = (unsigned char)*start;
        
        codepoints++;
        
        start++;
        if (b <= 0xc0) {
            continue;
        }
        start += UTF8_BYTE_TRAIL_COUNT(b);
    }
    
    return codepoints;
}

static uintptr_t utf8_bytes_to_skip_n_codepoints(const char *start,
                                                 uintptr_t codepoints) {
    uintptr_t bytes = 0;
    
    if (codepoints == 0) {
        return 0;
    }
    
#define LOOP_BODY \
b = (unsigned char)start[bytes++]; \
if (b > 0xc0) \
bytes += UTF8_BYTE_TRAIL_COUNT(b);
    
    uintptr_t n = (codepoints + 7) / 8;
    unsigned char b;
    switch(codepoints % 8) {
        case 0: do { LOOP_BODY
        case 7:      LOOP_BODY
        case 6:      LOOP_BODY
        case 5:      LOOP_BODY
        case 4:      LOOP_BODY
        case 3:      LOOP_BODY
        case 2:      LOOP_BODY
        case 1:      LOOP_BODY
        } while(--n > 0);
    }
#undef CODEPOINT_BYTES
    
    return bytes;
}

NSString *const PCRegularExpressionErrorDomain = @"PCRegularExpressionErrorDomain";

@implementation PCRegularExpressionException
@end

@interface PCRegularExpression () {
    NSString *_pattern;
    NSRegularExpressionOptions _options;
    pcre *_re;
    pcre_extra *_re_extra;
    int _capture_count;
    int _ovector_count;
}
@end

@implementation PCRegularExpression

+ (PCRegularExpression *)regularExpressionWithPattern:(NSString *)pattern
                                              options:(NSRegularExpressionOptions)options
                                                error:(NSError **)error {
    return [[[self alloc] initWithPattern:pattern
                                  options:options
                                    error:error]
            autorelease];
}

+ (PCRegularExpression *)regularExpressionWithPatternAndFlags:(NSString *)patternAndFlags
                                                      options:(NSRegularExpressionOptions)options
                                                        error:(NSError **)error {
    NSRange start = [patternAndFlags rangeOfString:@"/" options:0];
    NSRange end = [patternAndFlags rangeOfString:@"/" options:NSBackwardsSearch];
    
    NSError *dummyError = nil;
    if (error == NULL) {
        error = &dummyError;
    }
    
    if (start.location != 0 ||
        end.location == NSNotFound ||
        start.location == end.location) {
        *error = [NSError errorWithDomain:PCRegularExpressionErrorDomain
                                     code:0
                                 userInfo:[NSDictionary
                                           dictionaryWithObject:@"Should be in /regex/[ixsmw] format"
                                           forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    NSString *pattern = [patternAndFlags substringWithRange:
                         NSMakeRange(NSMaxRange(start),
                                     end.location-NSMaxRange(start))];
    NSString *flags = [patternAndFlags substringFromIndex:NSMaxRange(end)];
    
    NSRegularExpressionOptions flagsOptions = 0;
    
    for (NSUInteger i = 0; i < [flags length]; i++) {
        unichar c = [flags characterAtIndex:i];
        if (c == 'i') {
            flagsOptions |= NSRegularExpressionCaseInsensitive;
        } else if (c == 'x') {
            flagsOptions |= NSRegularExpressionAllowCommentsAndWhitespace;
        } else if (c == 's') {
            flagsOptions |= NSRegularExpressionDotMatchesLineSeparators;
        } else if (c == 'm') {
            flagsOptions |= NSRegularExpressionAnchorsMatchLines;
        } else if (c == 'w') {
            flagsOptions |= NSRegularExpressionUseUnicodeWordBoundaries;
        } else {
            *error = [NSError errorWithDomain:PCRegularExpressionErrorDomain
                                         code:0
                                     userInfo:[NSDictionary
                                               dictionaryWithObject:@"Invalid flags, available flags are ixsmw"
                                               forKey:NSLocalizedDescriptionKey]];
            return nil;
        }
    }
    
    return [self regularExpressionWithPattern:pattern
                                      options:flagsOptions|options
                                        error:error];
}

- (id)initWithPattern:(NSString *)pattern
              options:(NSRegularExpressionOptions)options
                error:(NSError **)error {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _pattern = [pattern copy];
    _options = options;
    
    // translate NSRegularExpression options to PCRE options
    int pcre_options =
    (
     // case insensetive
     ((options & NSRegularExpressionCaseInsensitive) ? PCRE_CASELESS : 0) |
     // allow # comments
     ((options & NSRegularExpressionAllowCommentsAndWhitespace) ? PCRE_EXTENDED : 0) |
     // make . match line separators, i think dot match all is closest
     ((options & NSRegularExpressionDotMatchesLineSeparators) ? PCRE_DOTALL : 0) |
     // default PCRE ^$ matches whole text ignoring new lines so to match
     ((options & NSRegularExpressionAnchorsMatchLines) ? PCRE_MULTILINE : 0) |
     // only CRLF as new line
     ((options & NSRegularExpressionUseUnixLineSeparators) ? PCRE_NEWLINE_LF : PCRE_NEWLINE_ANY) |
     // not sure how got this one matches
     ((options & NSRegularExpressionUseUnicodeWordBoundaries) ? PCRE_UCP : 0) |
     // always use utf8 mode
     PCRE_UTF8
     );
    
    if (options & NSRegularExpressionIgnoreMetacharacters) {
        pattern = [[self class] escapedPatternForString:pattern];
    }
    
    const char *errstr = NULL;
    int erroffset = 0;
    
    _re = pcre_compile([pattern UTF8String],
                       pcre_options,
                       &errstr,
                       &erroffset,
                       NULL);
    if (_re == NULL) {
        NSString *description = [NSString stringWithFormat:@"%s at offset %d",
                                 errstr, erroffset];
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:0
                                 userInfo:[NSDictionary
                                           dictionaryWithObject:description
                                           forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    // TODO: JIT?
    _re_extra = pcre_study(_re, 0, &errstr);
    if (_re_extra == NULL && errstr != NULL) {
        NSString *description = [NSString stringWithFormat:@"%s", errstr];
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:0
                                 userInfo:[NSDictionary
                                           dictionaryWithObject:description
                                           forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    pcre_fullinfo(_re, _re_extra, PCRE_INFO_CAPTURECOUNT, &_capture_count);
    
    // From pcreapi:
    // The smallest size for ovector that will allow for n captured substrings,
    // in addition to the offsets of the substring matched by the whole
    // pattern, is (n+1)*3.
    _ovector_count = (_capture_count+1)*3;
    
    return self;
}

- (void)dealloc {
    [_pattern release];
    _pattern = nil;
    pcre_free(_re);
    pcre_free(_re_extra);
    
    [super dealloc];
}

- (NSString *)pattern {
    return [[_pattern retain] autorelease];
}

- (NSRegularExpressionOptions)options {
    return _options;
}

- (NSUInteger)numberOfCaptureGroups {
    return _capture_count;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@ 0x%lx",
            [self class], self, _pattern, _options];
}

- (void)enumerateMatchesInString:(NSString *)string
                         options:(NSMatchingOptions)options
                           range:(NSRange)range
                      usingBlock:(void (^)(NSTextCheckingResult *result,
                                           NSMatchingFlags flags,
                                           BOOL *stop))block {
    [self enumerateMatchesInUTF8CString:[string UTF8String]
                         withByteLength:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]
                                options:options
                                  range:range
                             usingBlock:block];
}

- (void)enumerateMatchesInUTF8CString:(const char *)string
                       withByteLength:(NSUInteger)byteLength
                              options:(NSMatchingOptions)options
                                range:(NSRange)range
                           usingBlock:(void (^)(NSTextCheckingResult *result,
                                                NSMatchingFlags flags,
                                                BOOL *stop))block {
    // TODO: NSMatchingOptions
    
    BOOL stop = NO;
    codepoints_between_f codepoints_between = utf8_codepoints_between;
    bytes_to_skip_n_codepoints_f bytes_to_skip_n_codepoints = utf8_bytes_to_skip_n_codepoints;
    if (is_ascii_only(string, string+byteLength)) {
        codepoints_between = ascii_codepoints_between;
        bytes_to_skip_n_codepoints = ascii_bytes_to_skip_n_codepoints;
    }
    
    uintptr_t start_bytes_offset = bytes_to_skip_n_codepoints(string, (uintptr_t)range.location);
    uintptr_t string_bytes_length = (start_bytes_offset +
                                     bytes_to_skip_n_codepoints(&string[start_bytes_offset],
                                                                (uintptr_t)range.length));
    NSUInteger codepoint_offset = range.location;
    
    /*
     NSLog(@"codepoint_offset=%ld start_offset=%d length=%d",
     codepoint_offset, start_offset, length);
     */
    
    // TODO: sanity > byteLength etc
    
    uintptr_t last_start_bytes_offset = start_bytes_offset;
    
    int *_ovector = calloc(_ovector_count, sizeof(_ovector[0]));
    NSRange *_ranges = calloc(_capture_count+1, sizeof(_ranges[0]));
    
    while (!stop) {
        int rc = pcre_exec(_re,
                           _re_extra,
                           string,
                           (int)string_bytes_length,
                           (int)start_bytes_offset,
                           PCRE_NO_UTF8_CHECK,
                           _ovector,
                           _ovector_count);
        if (rc == PCRE_ERROR_NOMATCH) {
            break;
        } else if (rc < 0) {
            [PCRegularExpressionException raise:@"pcre_exec error" format:@"error=%d", rc];
        }
        
        NSUInteger groupCount = rc;
        
        // _ovector has this format:
        // _ovector[0] first char of whole match
        // _ovector[1] last char + 1 of whole match
        // _ovector[(n+1)*2] first char of capture group n
        // _ovector[(n+1)*2+1] last char + 1 of capture group n
        
        // whole string range first
        _ranges[0].location = codepoint_offset + codepoints_between(&string[start_bytes_offset],
                                                                    &string[_ovector[0]]);
        _ranges[0].length = codepoints_between(&string[_ovector[0]],
                                               &string[_ovector[1]]);
        // reset all other capture groups. pcre seems to not return non-matched
        // capture groups after the last matched group
        for (int i = 1; i < _capture_count+1; i++) {
            _ranges[i].location = NSNotFound;
            _ranges[i].length = 0;
        }
        
        for (int i = 1; i < groupCount; i++) {
            NSUInteger location = NSNotFound;
            NSUInteger length = 0;
            
            if (_ovector[i*2] >= 0) {
                location = codepoint_offset + codepoints_between(&string[start_bytes_offset],
                                                                 &string[_ovector[i*2]]);
                length = codepoints_between(&string[_ovector[i*2]],
                                            &string[_ovector[i*2+1]]);
                start_bytes_offset = _ovector[i*2+1];
                codepoint_offset = location + length;
            }
            
            _ranges[i].location = location;
            _ranges[i].length = length;
        }
        
        block([NSTextCheckingResult
               regularExpressionCheckingResultWithRanges:_ranges
               count:_capture_count+1
               regularExpression:self],
              0,
              &stop);
        
        last_start_bytes_offset = start_bytes_offset;
        
        // continue after match
        start_bytes_offset = _ovector[1];
        codepoint_offset = NSMaxRange(_ranges[0]);
        
        // FIXME:
        // break is we haven't moved forward. this also emulates the
        // NSRegularExperssion behaviour that .* matching string "a"
        // have two matches, "a" and "".
        if (last_start_bytes_offset == string_bytes_length) {
            break;
        }
    }
    
    if (options & NSMatchingCompleted) {
        block(nil,
              // should set NSMatchingHitEnd and or NSMatchingRequiredEnd also?
              NSMatchingCompleted,
              &stop);
    }
    
    free(_ovector);
    free(_ranges);
}

- (void)enumerateMatchesWithLineNumberInUTF8CString:(const char *)string
                                     withByteLength:(NSUInteger)byteLength
                                            options:(NSMatchingOptions)options
                                              range:(NSRange)range
                                         lineRanges:(NSArray *)lineRanges
                                         usingBlock:(void (^)(NSTextCheckingResult *result,
                                                              NSUInteger lineNumber,
                                                              NSRange inLineRange,
                                                              NSMatchingFlags flags,
                                                              BOOL *stop))block {
    NSEnumerator *lineRangesEnumerator = [lineRanges objectEnumerator];
    __block NSValue *lineRangeValue = [lineRangesEnumerator nextObject];
    __block NSUInteger lineNumber = 1;
    
    [self enumerateMatchesInUTF8CString:string
                         withByteLength:byteLength
                                options:options
                                  range:range
                             usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         while(lineRangeValue != nil &&
               !NSLocationInRange(result.range.location, [lineRangeValue rangeValue])) {
             lineRangeValue = [lineRangesEnumerator nextObject];
             lineNumber++;
         }
         
         NSRange inLineRange = result.range;
         // range inside current line starting from 1
         inLineRange.location -= [lineRangeValue rangeValue].location-1;
         
         block(result, lineNumber, inLineRange, flags, stop);
     }];
}

@end
