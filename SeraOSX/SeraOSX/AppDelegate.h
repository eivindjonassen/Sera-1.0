//
//  AppDelegate.h
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-10-28.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BluetoothManager.h"
#import "IGNSignalStrengthView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, BTManagerDelegate>

@property (nonatomic, assign) BOOL isScreenLocked;
@property (nonatomic, assign) BOOL isScreenSleeping;
@property (nonatomic, retain) NSAppleScript *lockScript;
@property (nonatomic, retain) NSAppleScript *unlockScript;
@property (nonatomic, strong) IGNSignalStrengthView *signalStrengthView;
@property (nonatomic, strong) NSArray *nibViews;

- (void)onSetupClick;
- (void)hidePopoverWithFade;
- (void)showSignalStrenghtView;
- (void)showAllDoneView;
- (void) compileScripts;
- (void)compileUnlockScriptWitchCompletionBlock:(void (^)(void))completion;
- (void)compileLockScript;
@end

