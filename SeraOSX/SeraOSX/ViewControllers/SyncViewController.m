//
//  SyncViewController.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-10-30.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "SyncViewController.h"
#import "AppDelegate.h"

@interface SyncViewController ()

@end

@implementation SyncViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self.progressIndicator setUsesThreadedAnimation:YES];
    [self.progressIndicator startAnimation:nil];
    
    
}

@end
