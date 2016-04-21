//
//  CustomLogger.h
//
//  Created by Justinas Rumsevicius on 2015-08-31.
//  Copyright (c) 2015 DNB. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG(args...) CustomLogger(1, __FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#define LOGF(args...) CustomLogger(2, __FILE__,__LINE__,__PRETTY_FUNCTION__,args);

void CustomLogger(const int type, const char *file, int lineNumber, const char *functionName, NSString *format, ...);