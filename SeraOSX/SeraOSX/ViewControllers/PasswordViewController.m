//
//  PasswordViewController.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "PasswordViewController.h"
#import <Collaboration/Collaboration.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

@interface PasswordViewController ()

@end

@implementation PasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here
    [self.userImageView setImage:[self userImage]];
    [self.userImageView setWantsLayer:YES];
    self.userImageView.layer.cornerRadius = (float)self.userImageView.frame.size.height/2.f;
    self.userImageView.layer.masksToBounds = YES;
    self.userShortUsernameLabel.stringValue = NSFullUserName();
    self.passwordTextField.delegate = self;
    self.passwordTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"sera_pass"] ? [[NSUserDefaults standardUserDefaults] stringForKey:@"sera_pass"] : @"";
    if (self.passwordTextField.stringValue){
        self.nextButton.enabled = YES;
    }
}

- (NSImage *)userImage
{
    CBIdentity *identity = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]];
    return [identity image];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    if (textField == self.passwordTextField){
        if ([textField.stringValue length] == 0){
            self.nextButton.enabled = NO;
        } else {
            //TODO: put this part on phone side...
//            NSString *oldPassword = [[NSUserDefaults standardUserDefaults] stringForKey:@"sera_pass"];
            self.nextButton.enabled = YES;
        }
    }
}

- (IBAction)onNextButtonClick:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:self.passwordTextField.stringValue forKey:@"sera_pass"];
    [[NSUserDefaults standardUserDefaults] setObject:NSUserName() forKey:@"sera_username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate compileUnlockScript];
    [delegate showSignalStrenghtView];
    
    
}
@end
