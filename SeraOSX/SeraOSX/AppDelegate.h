//
//  AppDelegate.h
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-10-28.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BluetoothManager.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, BTManagerDelegate>

@property (nonatomic, assign) BOOL isScreenLocked;
@property (nonatomic, retain) NSAppleScript *lockScript;
@property (nonatomic, retain) NSAppleScript *unlockScript;

- (void)onSetupClick;
- (void)hidePopoverWithFade;
- (void)showSignalStrenghtView;
- (void)showAllDoneView;
- (void) compileScripts;
- (void)compileUnlockScript;
- (void)compileLockScript;
@end

