//
//  AllDoneViewController.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-18.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "AllDoneViewController.h"
#import "AppDelegate.h"

@interface AllDoneViewController ()

@end

@implementation AllDoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
   
    // Do view setup here.
}
- (IBAction)onCloseAppClicked:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate hidePopoverWithFade];

}
- (IBAction)onShareFacebookClicked:(id)sender {
}
- (IBAction)onShareLinkedInClicked:(id)sender {
}
- (IBAction)onShareTwitterClicked:(id)sender {
}

- (void)tintIcons {
    
    NSImage *icon = [self.shareTwitterButton.image copy];
    NSSize iconSize = [icon size];
    NSRect iconRect = {NSZeroPoint, iconSize};
    
    [icon lockFocus];
    [[[NSColor darkGrayColor] colorWithAlphaComponent: 0.5] set];
    NSRectFillUsingOperation(iconRect, NSCompositeSourceAtop);
    [icon unlockFocus];
    
    [self.shareTwitterButton setImage: icon];
}

@end
