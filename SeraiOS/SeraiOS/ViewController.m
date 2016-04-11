//
//  ViewController.m
//  SeraiOS
//
//  Created by Aurimas Žibas on 2015-11-12.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib
    [BluetoothManager sharedClient].delegate = self;
    [self initViews];
    [[BluetoothManager sharedClient] checkBluetoothState];
    //[[BluetoothManager sharedClient] startAdvertisingIfReady];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) initViews {
    switch ((UserState)[[NSUserDefaults standardUserDefaults] integerForKey:@"userState"]){
        case UserStateFirstTime:
        {
            [self.greetingsSwipeLeftLabel startShimmering];
            UIPanGestureRecognizer *swipeLeft = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
            [self.greetingsView addGestureRecognizer:swipeLeft];
            self.greetingsView.userInteractionEnabled = YES;
            self.connectViewTitleLabel.text = @"Please download our app!";
            self.connectViewDescriptionLabel.text = @"You need to download our free app for mac at the AppStore";
            self.connectView.alpha = 0;
            self.bluetoothDisabledView.alpha = 0;
            break;
        }
        case UserStateNotConfigured:
            self.greetingsView.alpha = 0;
            self.connectView.alpha = 0;
            self.bluetoothDisabledView.alpha = 1;
            break;
        case UserStateConfigured:
            self.unlinkButton.hidden = NO;
            self.unlinkButton.alpha = 1;
            self.greetingsView.alpha = 0;
            self.bluetoothDisabledView.alpha = 1;
            self.connectViewTitleLabel.text = @"";
            self.connectViewDescriptionLabel.text = [NSString stringWithFormat:@"We can not find\n %@\n\nPlease start Sera on your Mac",[[NSUserDefaults standardUserDefaults] stringForKey:@"macName"]];
            self.connectViewStateImageView.image = [UIImage imageNamed:@"ic_mac_off"];
            self.statusImageYConstraint.constant -= 30;
            [self.activityIndicator startAnimating];
            break;
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    CGPoint velocity = [sender velocityInView:self.view];
    
    if(velocity.x < 0) // To the left
    {
        if (sender.state == UIGestureRecognizerStateBegan) {
            self.startPanGestureLocation = [sender locationInView:self.view];
        }
        else if (sender.state == UIGestureRecognizerStateChanged){
            CGPoint stopLocation = [sender locationInView:self.view];
            CGFloat dx = stopLocation.x - self.startPanGestureLocation.x;
            CGFloat dy = stopLocation.y - self.startPanGestureLocation.y;
            CGFloat distance = sqrt(dx*dx + dy*dy );
            self.greetingsView.alpha = 1-distance/100;
            if (self.currentBluetoothState == CBCentralManagerStatePoweredOn){
                self.connectView.alpha = distance/100;
            } else {
                self.bluetoothDisabledView.alpha = distance/100;
            }
        }
        else if (sender.state == UIGestureRecognizerStateEnded) {
            CGPoint stopLocation = [sender locationInView:self.view];
            CGFloat dx = stopLocation.x - self.startPanGestureLocation.x;
            CGFloat dy = stopLocation.y - self.startPanGestureLocation.y;
            CGFloat distance = sqrt(dx*dx + dy*dy );
            NSLog(@"Distance: %f", distance);
            if (distance>50){
                [UIView animateWithDuration:0.15 animations:^{
                    self.greetingsView.alpha = 0;
                    if (self.currentBluetoothState == CBCentralManagerStatePoweredOn){
                        self.connectView.alpha = 1;
                    } else {
                        self.bluetoothDisabledView.alpha = 1;
                    }
                } completion:^(BOOL finished) {
                    if (self.connectView.alpha){
                        [[BluetoothManager sharedClient] startAdvertisingIfReady];
                    }
                }];
            } else {
                [UIView animateWithDuration:0.15 animations:^{
                    self.greetingsView.alpha = 1;
                    if (self.currentBluetoothState == CBCentralManagerStatePoweredOn){
                        self.connectView.alpha = 0;
                    } else {
                        self.bluetoothDisabledView.alpha = 0;
                    }
                }];
                
            }
            

        }

    }
}


#pragma mark - BTManager delegate
- (void)bluetoothStateDidChanged:(CBPeripheralManagerState )state {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentBluetoothState != state){
            self.currentBluetoothState = state;
            if (self.currentBluetoothState == CBCentralManagerStatePoweredOn){
                if (self.bluetoothDisabledView.alpha){
                    [UIView animateWithDuration:0.15 animations:^{
                        self.bluetoothDisabledView.alpha = 0;
                        self.connectView.alpha = 1;
                        [self.activityIndicator startAnimating];
                    } completion:^(BOOL finished) {
                        [[BluetoothManager sharedClient] startAdvertisingIfReady];
                    }];
                } else if (self.connectView.alpha){
                    [[BluetoothManager sharedClient] startAdvertisingIfReady];
                }
            } else if (self.currentBluetoothState == CBCentralManagerStatePoweredOff){
                if (self.connectView.alpha){
                    [UIView animateWithDuration:0.15 animations:^{
                        self.bluetoothDisabledView.alpha = 1;
                        self.connectView.alpha = 0;
                    } completion:^(BOOL finished) {
                        self.connectViewTitleLabel.text = @"";
                        
                        NSString* macName = [[NSUserDefaults standardUserDefaults] stringForKey:@"macName"];
                        if (macName){
                            self.connectViewDescriptionLabel.text = [NSString stringWithFormat:@"We can not find\n %@\n\nPlease start Sera on your Mac",macName];
                        }
                        
                        self.connectViewStateImageView.image = [UIImage imageNamed:@"ic_mac_off"];
                    }];
                }
            }
        }
    });
}

- (void)peripheralSuccessfullyConnected {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.debugTextView.text == nil){
            self.debugTextView.text = @"";
        }
        self.debugTextView.text = [self.debugTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@ Connected\n",[NSDate date]]];
        switch ((UserState)[[NSUserDefaults standardUserDefaults] integerForKey:@"userState"]){
            case UserStateFirstTime:
            case UserStateNotConfigured:
                [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"userState"];
                self.connectViewTitleLabel.text = @"Congratulations!";
                self.connectViewDescriptionLabel.text = [NSString stringWithFormat:@"You've connected to your\n %@\n\nYou can now press sleep button on iPhone and put it in the pocket!",[[NSUserDefaults standardUserDefaults] stringForKey:@"macName"]];
                [self.connectViewStateImageView setImage:[UIImage imageNamed:@"ic_mac_complete"]];
                self.activityIndicator.hidden = YES;
                self.unlinkButton.hidden = NO;
                [self performSelector:@selector(peripheralSuccessfullyConnected) withObject:nil afterDelay:3];
                break;
            case UserStateConfigured:
                self.connectViewTitleLabel.text = @"";
                [self.connectViewStateImageView setImage:[UIImage imageNamed:@"ic_mac_on"]];
                self.connectViewDescriptionLabel.text = [NSString stringWithFormat:@"Connected to\n %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"macName"]];
                self.activityIndicator.hidden = YES;
                self.unlinkButton.hidden = NO;
                break;
        }
    });
}

- (void)peripheralDisconnected {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.debugTextView.text == nil){
            self.debugTextView.text = @"";
        }
        self.debugTextView.text = [self.debugTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@ Disconnected\n",[NSDate date]]];
        
        if (self.connectView.alpha){
            if ((UserState)[[NSUserDefaults standardUserDefaults] integerForKey:@"userState"] != UserStateFirstTime){
                self.activityIndicator.hidden = NO;
                self.connectViewStateImageView.image = [UIImage imageNamed:@"ic_mac_off"];
                self.connectViewTitleLabel.text = @"";
                self.connectViewDescriptionLabel.text = [NSString stringWithFormat:@"We can not find\n %@\n\nPlease start Sera on your Mac",[[NSUserDefaults standardUserDefaults] stringForKey:@"macName"]];
                //[[BluetoothManager sharedClient] startAdvertisingIfReady];
            } else {
                [self initViews];
                
                [UIView animateWithDuration:0.25 animations:^{
                    self.greetingsView.alpha = 1;
                    self.connectView.alpha = 0;
                }];
            }
        }
    });
}

- (void)macNameUpdated {
      dispatch_async(dispatch_get_main_queue(), ^{
    if (self.connectView.alpha && (UserState)[[NSUserDefaults standardUserDefaults] integerForKey:@"userState"] == UserStateConfigured){
        self.connectViewDescriptionLabel.text = [NSString stringWithFormat:@"Connected to\n %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"macName"]];
    }
      });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onUnlinckClick:(id)sender {
   
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                        initWithTitle:[NSString stringWithFormat:@"Do You want to unlink this phone from %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"macName"]]
                        delegate:self
                        cancelButtonTitle:@"Cancel"
                        destructiveButtonTitle:nil
                        otherButtonTitles:@"Unlink iPhone",nil];
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
        if (buttonIndex == 0)       // Unlink iPhone
        {
            [self unlinkPhone];
        }
}

- (void)gotForceUnlink {
    [self unlinkInternal];
}

- (void)unlinkInternal{
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults]
     removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
      dispatch_async(dispatch_get_main_queue(), ^{
    [self initViews];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.greetingsView.alpha = 1;
        self.connectView.alpha = 0;
    }];
      });
}

- (void)unlinkPhone {

    [[BluetoothManager sharedClient] sendUnlinkToCentral];
    [self unlinkInternal];
}

// DEBUG
- (void)beganAdvertising {
      dispatch_async(dispatch_get_main_queue(), ^{
    if (self.debugTextView.text == nil){
        self.debugTextView.text = @"";
    }
    self.debugTextView.text = [self.debugTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@ Starting Advertising\n",[NSDate date]]];
    });
}

- (void)stopedAdvertising {
      dispatch_async(dispatch_get_main_queue(), ^{
    if (self.debugTextView.text == nil){
        self.debugTextView.text = @"";
    }
    self.debugTextView.text = [self.debugTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@ Stopping Advertising\n",[NSDate date]]];
      });
}

@end
