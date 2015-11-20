//
//  PasswordViewController.h
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PasswordViewController : NSViewController <NSTextFieldDelegate>
@property (weak) IBOutlet NSImageView *userImageView;
@property (weak) IBOutlet NSTextField *userShortUsernameLabel;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
- (IBAction)onNextButtonClick:(id)sender;
@property (weak) IBOutlet NSButton *nextButton;
@property (assign) BOOL hasPasswordChanged;

@end
