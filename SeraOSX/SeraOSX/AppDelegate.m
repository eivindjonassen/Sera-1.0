//
//  AppDelegate.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-10-28.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "AppDelegate.h"
#import "SyncViewController.h"
#import "ConnectedViewController.h"
#import "PasswordViewController.h"
#import "SignalStrengthViewController.h"
#import "AllDoneViewController.h"

@interface AppDelegate ()


@property (strong, nonatomic) NSStatusItem *statusItem;
@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSMenuItem *linkPhoneItem;
@property (strong, nonatomic) NSMenuItem *signalStrengthItem;
@property (strong, nonatomic) NSPopover *mainPopover;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self compileLockScript];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self compileUnlockScriptWitchCompletionBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
                NSStatusBarButton *barButton = self.statusItem.button;
                if (barButton){
                    barButton.image = [NSImage imageNamed:@"ic_statusbar"];
                    //        barButton.action = @selector(togglePopover:);
                }
                self.statusItem.highlightMode = YES;
                
                // Initializing main menu
                NSMenu *mainMenu = [[NSMenu alloc] init];
                [mainMenu addItemWithTitle:@"Setup Sera" action:@selector(onSetupClick) keyEquivalent:@""];
                [mainMenu addItem:[NSMenuItem separatorItem]];
                self.nibViews = [[IGNSignalStrengthView alloc] loadFromNib];

                for (NSView *subview in self.nibViews){
                    if ([subview isKindOfClass:[IGNSignalStrengthView class]]){
                        self.signalStrengthView = (IGNSignalStrengthView*)subview;
                        break;
                    }
                }
                
                // Need reference for title changes
                if ([[NSUserDefaults standardUserDefaults] stringForKey:@"iphoneName"]){
                    self.linkPhoneItem = [mainMenu addItemWithTitle:[NSString stringWithFormat:@"Unlink %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"iphoneName"]] action:@selector(onLinkPhoneClick) keyEquivalent:@""];
                    self.linkPhoneItem.enabled = YES;
                } else {
                    self.linkPhoneItem = [mainMenu addItemWithTitle:@"Scanning..." action:@selector(onLinkPhoneClick) keyEquivalent:@""];
                    self.linkPhoneItem.enabled = NO;
                }
                
                [mainMenu addItemWithTitle:@"Unlock automatically" action:@selector(onUpdatesClick) keyEquivalent:@""];
                BOOL autoUpdate = [[NSUserDefaults standardUserDefaults] boolForKey:@"removeSleep"];
                [mainMenu.itemArray objectAtIndex:3].image = autoUpdate ? [NSImage imageNamed:@"ic_tick"] : nil;
                
                [mainMenu addItem:[NSMenuItem separatorItem]];
                self.signalStrengthItem = [[NSMenuItem alloc]
                                                  initWithTitle:@"Signal strength"
                                                  action:nil
                                                  keyEquivalent:@""];
                
                self.signalStrengthItem.view = self.signalStrengthView;
               
                [mainMenu addItem:self.signalStrengthItem];
                [mainMenu addItem:[NSMenuItem separatorItem]];
                
                [mainMenu addItemWithTitle:@"Quit Sera" action:@selector(onQuitClick) keyEquivalent:@""];
                
                [mainMenu setAutoenablesItems:NO];
                [mainMenu.itemArray objectAtIndex:0].enabled = NO;
                //[mainMenu.itemArray objectAtIndex:2].enabled = NO;
                [mainMenu.itemArray objectAtIndex:3].enabled = YES;
                [mainMenu.itemArray objectAtIndex:5].enabled = YES;
                
                self.statusItem.menu = mainMenu;
                
                [BluetoothManager2 sharedClient].delegate = self;
                
                
                // Main popover for views
                self.mainPopover = [[NSPopover alloc] init];
                self.mainPopover.contentViewController = [[SyncViewController alloc] initWithNibName:@"SyncViewController" bundle:nil];
                [self performSelector:@selector(togglePopover:) withObject:nil afterDelay:0.5]; // To show popover in the right place, we need delay
                
                // [[BluetoothManager sharedClient] scanForDevices];
                [[BluetoothManager2 sharedClient] initCentralManager];
                
                NSDistributedNotificationCenter * center =
                [NSDistributedNotificationCenter defaultCenter];
                
                [center
                 addObserver:self
                 selector:@selector(screenIsLocked:)
                 name:@"com.apple.screenIsLocked"
                 object:nil];
                
                [center
                 addObserver:self
                 selector:@selector(screenIsUnlocked:)
                 name:@"com.apple.screenIsUnlocked"
                 object:nil];
                
                [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(screenIsSleeping:) name:NSWorkspaceScreensDidSleepNotification object:nil];
                [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(screenHasWakeUp:) name:NSWorkspaceScreensDidWakeNotification object:nil];
            });
            
        }];
    });
    // Setup main status bar info
    
}

- (void)screenIsLocked:(id)sender {
    NSLog(@"screen LOCKED");
    self.isScreenLocked = YES;
}

- (void)screenIsUnlocked:(id)sender {
    NSLog(@"Screen UNLOCKED!!");
    self.isScreenLocked = NO;
}

- (void)screenIsSleeping:(id)sender {
    NSLog(@"Screen is sleeping!");
    self.isScreenSleeping = YES;
}

- (void)screenHasWakeUp:(id)sender {
    NSLog(@"Screen has wake up!");
    self.isScreenSleeping = NO;
}

- (void)onSetupClick {
    LOG(@"onSetupClick");
    if ([self.mainPopover.contentViewController isKindOfClass:[PasswordViewController class]]) return;
    
    self.mainPopover.contentViewController = [[PasswordViewController alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    [self showPopover];
}

- (void)onLinkPhoneClick {
    [[BluetoothManager2 sharedClient] sendUnlink];
    
    [self deviceUnlinked];
}

- (void)onUpdatesClick {
    BOOL autoUpdate = [[NSUserDefaults standardUserDefaults] boolForKey:@"removeSleep"];
    
    autoUpdate = !autoUpdate;
    
    [[NSUserDefaults standardUserDefaults] setBool:autoUpdate forKey:@"removeSleep"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.statusItem.menu.itemArray objectAtIndex:3].image = autoUpdate ? [NSImage imageNamed:@"ic_tick"] : nil;
    
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [delegate compileUnlockScriptWitchCompletionBlock:^{
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                [delegate showSignalStrenghtView];
            //            });
        }];
        
    });
}

- (void)onQuitClick {
    exit(1);
}

- (void)showAllDoneView {
    self.mainPopover.contentViewController = [[AllDoneViewController alloc] initWithNibName:@"AllDoneViewController" bundle:nil];
}

- (void)togglePopover:(id)sender {
    if (self.mainPopover.isShown){
        [self hidePopover:sender];
    } else {
        [self showPopover];
    }
}

- (void)hidePopoverWithFade {
    [self hidePopover:nil];
    //    [NSAnimationContext beginGrouping];
    //    [NSAnimationContext currentContext].duration = 0.25;
    //    self.mainPopover.contentViewController.view.animator.alphaValue = 0;
    //    [NSAnimationContext endGrouping];
    //    [self performSelector:@selector(hidePopover:) withObject:nil afterDelay:0.25];
}

- (void)showPopover{
    if (self.statusItem.button) {
        NSLog(@"X: %f, Y: %f",self.statusItem.button.frame.origin.x
              , self.statusItem.button.bounds.origin.y);
        [self.mainPopover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSMinYEdge];
    }
}

- (void)hidePopover:(id)sender {
    [self.mainPopover performClose:sender];
    [self configureSignalStrengthSlider];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)peripheralDisconnected:(CBPeripheral *)peripheral {
    self.mainPopover.contentViewController = [[SyncViewController alloc] initWithNibName:@"SyncViewController" bundle:nil];
    [self.statusItem.menu.itemArray objectAtIndex:0].enabled = NO;
    //[self.statusItem.menu.itemArray objectAtIndex:2].enabled = NO;
    self.signalStrengthView.signalStrengthIndicator.doubleValue = -100;
    self.signalStrengthView.signalStrengthSlider.hidden = YES;
}

- (void)connectedPhoneDidUpdateRSSI:(NSNumber *)RSSI {
    dispatch_async(dispatch_get_main_queue(), ^{
    NSViewController *currentController = self.mainPopover.contentViewController;
    if ([currentController isKindOfClass:[SignalStrengthViewController class]]){
        ((SignalStrengthViewController *)currentController).currentSignalStrengthProgressBar.doubleValue = RSSI.doubleValue;
    }
    
    self.signalStrengthView.signalStrengthIndicator.doubleValue = RSSI.doubleValue;
    
    NSInteger signalStrength = [[NSUserDefaults standardUserDefaults] integerForKey:@"signalStrength"];
     NSLog(@"currentStrenght: %li, saved: %li",(long)RSSI.integerValue, (long)signalStrength);
    if (signalStrength != 0){
        if (signalStrength >= RSSI.integerValue+10){
            if (!self.isScreenLocked){
                NSLog(@"lock screen !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                [self.lockScript executeAndReturnError:nil];
            }
        } else {
            if (self.isScreenLocked){
                NSLog(@"Unlock screen");
                NSDictionary *error;
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"removeSleep"]){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self compileUnlockScriptWitchCompletionBlock:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.unlockScript executeAndReturnError:nil];
                            });
                        }];
                        
                    });
                } else {
                    if (!self.isScreenSleeping){
                    [self.unlockScript executeAndReturnError:&error];
                    }
                }
                
                NSLog(@"error: %@",error);
            }
        }
    }
    });
    
}
- (void)deviceUnlinked {
    [self hidePopover:nil];
    [self.statusItem.menu.itemArray objectAtIndex:0].enabled = NO;
    [self.statusItem.menu.itemArray objectAtIndex:2].enabled = NO;
    self.signalStrengthView.signalStrengthIndicator.doubleValue = -100;
    self.signalStrengthView.signalStrengthSlider.hidden = YES;
    [[self.statusItem.menu.itemArray objectAtIndex:2] setTitle:@"Scanning..."];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"signalStrength"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"sera_pass"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"phoneUUID"];
    [[NSUserDefaults standardUserDefaults] setObject:NO forKey:@"shouldWakeUp"];
     [[NSUserDefaults standardUserDefaults] synchronize];
    [self compileUnlockScriptWitchCompletionBlock:^{
        self.mainPopover.contentViewController = [[SyncViewController alloc] initWithNibName:@"SyncViewController" bundle:nil];
        [self performSelector:@selector(showPopover) withObject:nil afterDelay:0.1]; // To show popover in the right place, we need delay
        [BluetoothManager2 sharedClient].connectedPhone = nil;
        
        // [[BluetoothManager sharedClient] scanForDevices];
        [[BluetoothManager2 sharedClient] initCentralManager];
    }];
   
    
}

- (void)showSignalStrenghtView {
    self.mainPopover.contentViewController = [[SignalStrengthViewController alloc] initWithNibName:@"SignalStrengthViewController" bundle:nil];
}

- (void)peripheralSuccessfulyConnected:(CBPeripheral *)peripheral {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self configureSignalStrengthSlider];
    [self.statusItem.menu.itemArray objectAtIndex:0].enabled = YES;
    [self.statusItem.menu.itemArray objectAtIndex:2].enabled = YES;
    [[self.statusItem.menu.itemArray objectAtIndex:2] setTitle:[NSString stringWithFormat:@"Unlink %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"iphoneName"]]];
    switch([[NSUserDefaults standardUserDefaults] integerForKey:@"userState"]){
        case 0:{
            NSLog(@"Connected!");
            self.mainPopover.contentViewController = [[ConnectedViewController alloc] initWithNibName:@"ConnectedViewController" bundle:nil];
            
            break;
        }
        case 1:
            break;
        case 2:
            break;
    }
    });
}

- (void) compileScripts {
    //    NSString *pythonScript= @"import objc;bndl = objc.loadBundle('CoreGraphics', globals(), '/System/Library/Frameworks/ApplicationServices.framework');objc.loadBundleFunctions(bndl, globals(),[('CGWarpMouseCursorPosition', 'v{CGPoint=ff}')]);CGWarpMouseCursorPosition((0, 0));";
    //
    //    NSString *pythonRunScript = [NSString stringWithFormat:@"python -c \"%@\"",pythonScript];
    //
    //    NSString *allScript = [NSString stringWithFormat:@"do shell script \"%@\" tell application \"Finder\" to activate",pythonRunScript];
    
    NSString *allScript = [NSString stringWithFormat:@"do shell script \"pmset displaysleepnow\""];
    
    self.lockScript = [[NSAppleScript alloc] initWithSource:allScript];
    [self.lockScript compileAndReturnError:nil];
    
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"sera_pass"];
    if (password == nil || ![password length])
    {
        password = @"";
    }
    NSString *unlockString =  [[NSString alloc] initWithFormat:@"tell application \"System Events\"\n  tell process \"Finder\"\n keystroke return\n end tell\n end tell\n delay 1 \n tell application \"System Events\" to keystroke \"%@\"\n tell application \"System Events\" to keystroke return",password];
    self.unlockScript = [[NSAppleScript alloc] initWithSource:unlockString];
    
    [self.unlockScript compileAndReturnError:nil];
}

- (void) compileLockScript {
    NSString *allScript = [NSString stringWithFormat:@"do shell script \"pmset displaysleepnow\""];
    
    self.lockScript = [[NSAppleScript alloc] initWithSource:allScript];
    [self.lockScript compileAndReturnError:nil];
}

- (void)compileUnlockScriptWitchCompletionBlock:(void (^)(void))completion {
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"sera_pass"];
    if (password == nil || ![password length])
    {
        password = @"";
    }
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"sera_username"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[[NSDate date] dateByAddingTimeInterval:1]];
    
    BOOL shouldWakeUp = [[NSUserDefaults standardUserDefaults] boolForKey:@"removeSleep"];
    
    NSString *escape = @"";
    if (shouldWakeUp){
        escape = [NSString stringWithFormat:@"do shell script \"pmset schedule wake \\\"%@\\\" &> /dev/null &\" user name \"%@\" password \"%@\" with administrator privileges\n ",dateString,username,password];
    }
    
    escape = [escape stringByAppendingString:[NSString stringWithFormat:@"tell application \"System Events\" to keystroke \"%@\"\n tell application \"System Events\" to keystroke return",password]];
    
    // NSString *trying = [escape stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSLog(@"unlock string: %@",escape);
    
    self.unlockScript = [[NSAppleScript alloc] initWithSource:escape];
    
    [self.unlockScript compileAndReturnError:nil];
    completion();
}

-(void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"applicationDidBecomeActive");
}

-(void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"applicationWillResignActive");
}

- (void)configureSignalStrengthSlider {
    [self.signalStrengthView setWantsLayer:YES];
    [self.signalStrengthView.signalStrengthIndicator setWantsLayer:YES];
    [self.signalStrengthView.signalStrengthSlider setWantsLayer:YES];
    self.signalStrengthView.signalStrengthSlider.layer.zPosition = 100;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"signalStrength"] != 0){
        self.signalStrengthItem.enabled = YES;
        self.signalStrengthView.signalStrengthSlider.doubleValue = [[NSUserDefaults standardUserDefaults] integerForKey:@"signalStrength"];
        self.signalStrengthView.signalStrengthSlider.hidden = NO;
    } else {
        self.signalStrengthItem.enabled = NO;
        self.signalStrengthView.signalStrengthSlider.hidden = YES;
    }
}

@end
