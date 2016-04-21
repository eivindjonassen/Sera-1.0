//
//  ConnectedViewController.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-10-30.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "ConnectedViewController.h"
#import "AppDelegate.h"

@interface ConnectedViewController ()

@end

@implementation ConnectedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.phoneNameLabel.stringValue = [NSString stringWithFormat:@"Connected to %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"iphoneName"]];
}

- (void)viewDidAppear{
    [super viewDidAppear];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"%@",[defaults objectForKey:@"sera_pass"]);
    NSLog(@"%li",(long)[defaults integerForKey:@"signalStrength"]);
    if ([defaults objectForKey:@"sera_pass"] == nil || [defaults integerForKey:@"signalStrength"] == 0){
        [self performSelector:@selector(goToConfiguration:) withObject:nil afterDelay:5];
    } else {
        [self performSelector:@selector(dismissPopover) withObject:nil afterDelay:5];
    }

}

- (IBAction)goToConfiguration:(id)sender  {
    LOG(@"Go to configuration");
     AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate onSetupClick];
}

- (void)dismissPopover {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate hidePopoverWithFade];
}


@end
