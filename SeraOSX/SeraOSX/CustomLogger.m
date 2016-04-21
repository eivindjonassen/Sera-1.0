//
//  CustomLogger.m
//
//  Created by Justinas Rumsevicius on 2015-08-31.
//  Copyright (c) 2015 DNB. All rights reserved.
//

#import "CustomLogger.h"

static NSDateFormatter* formatter;

void CustomLogger(const int type, const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        NSString *formatString = @"yyyy-MM-dd' 'HH:mm:ss.SSS";
        [formatter setDateFormat:formatString];
    }
    
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    // NSLog only adds a newline to the end of the NSLog format if
    // one is not already there.
    // Here we are utilizing this feature of NSLog()
    if (![format hasSuffix: @"\n"]) {
        format = [format stringByAppendingString: @"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end (ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    // fprintf(stderr, "%s (%s) (%s:%d) %s",
    //        [[formatter stringFromDate:[NSDate date]] UTF8String],
    //        functionName, [fileName UTF8String],
    //         lineNumber, [body UTF8String]);
    if (type == 1) {
        // Simple Log
        fprintf(stderr, "%s (%s:%d) %s",
                [[formatter stringFromDate:[NSDate date]] UTF8String],
                [fileName UTF8String],
                lineNumber, [body UTF8String]);
    } else if (type == 2) {
        // Function Log
        fprintf(stderr, "%s (%s:%d) [%s] %s",
                [[formatter stringFromDate:[NSDate date]] UTF8String],
                [fileName UTF8String],
                lineNumber, functionName ,[body UTF8String]);
    }
}