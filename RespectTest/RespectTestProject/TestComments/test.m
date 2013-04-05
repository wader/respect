#import <Foundation/Foundation.h>

@interface Receiver : NSObject
// @LintSourceMatch: [Receiver argument:@]
// @LintFile: $1
+ (void)argument:(NSString *)argument;
@end

@implementation Receiver
+ (void)argument:(NSString *)argument {
}
@end

// @LintSourceMatch: function(@)
// @LintFile: $1
static void function(char *argument) {
}

int main(int argc, char *argv[])
{
    @autoreleasepool {
        // @ExpectedMissing: t1
        [Receiver /* comment */ argument:@"t1"];
        
        // @ExpectedMissing: t2
        [Receiver
         /* comment */
         argument:@"t2"];
        
        // @ExpectedMissing: t3
        [Receiver
         // comment
         argument:@"t3"];
        
        // @ExpectedMissing: t4
        [Receiver // comment
         argument:@"t4"];
        
        // @ExpectedMissing: /*t5*/
        [Receiver argument:@"/*t5*/"];
        
        // @ExpectedMissing: //t6
        [Receiver argument:@"//t6"];
        
        // @ExpectedMissing: t7
        function("t7");
        
        // @ExpectedMissing: t8
        function/*comment*/("t8");
        
        // @ExpectedMissing: t9
        function /*comment*/
        ("t9");
        
        // @ExpectedMissing: t10
        function
        /*comment*/
        ("t10");
        
        // @ExpectedMissing: t11
        function //comment
        ("t11");
        
        // @ExpectedMissing: t12
        function
        //comment
        ("t12");
        
        // @ExpectedMissing: /*t13*/
        function("/*t13*/");
        
        // @ExpectedMissing: //t14
        function("//t14");
        
        /* function("t15"); */
        /* function(@"t16"); */
        // function("t17");
        // function(@"t18");
    }
}
