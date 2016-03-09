//
//  DeviceUID.m
//  SeraiOS
//
//  Created by Aurimas Žibas on 2016-01-21.
//  Copyright © 2016 Ignitum. All rights reserved.
//

#import "DeviceUID.h"
#import <IOKit/IOKitLib.h>

@interface DeviceUID ()
@end

@implementation DeviceUID


+ (NSString *)uid
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
    
    return serialNumberAsNSString;
}

@end
