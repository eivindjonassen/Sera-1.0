//
//  SignalStrengthViewController.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "SignalStrengthViewController.h"
#import "AppDelegate.h"

@interface SignalStrengthViewController ()

@end

@implementation SignalStrengthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.signalStrengthSlider.doubleValue = [[NSUserDefaults standardUserDefaults] integerForKey:@"signalStrength"] ? [[NSUserDefaults standardUserDefaults] integerForKey:@"signalStrength"] : -60;
}

- (IBAction)onSaveClick:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:self.signalStrengthSlider.doubleValue forKey:@"signalStrength"];
    
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate hidePopoverWithFade];
    
}
@end
