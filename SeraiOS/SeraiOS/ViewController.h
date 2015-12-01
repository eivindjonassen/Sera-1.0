//
//  ViewController.h
//  SeraiOS
//
//  Created by Aurimas Žibas on 2015-11-12.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIView+Shimmer/UIView+Shimmer.h>
#import "BluetoothManager.h"

@interface ViewController : UIViewController <BTManagerDelegate, UIActionSheetDelegate>


typedef NS_ENUM (NSInteger, UserState){
    UserStateFirstTime,
    UserStateNotConfigured,
    UserStateConfigured
};

@property (weak, nonatomic) IBOutlet UILabel *greetingsSwipeLeftLabel;
@property (assign, nonatomic) CGPoint startPanGestureLocation;
@property (weak, nonatomic) IBOutlet UIView *greetingsView;
@property(nonatomic, assign) CBPeripheralManagerState currentBluetoothState;
@property (weak, nonatomic) IBOutlet UIView *bluetoothDisabledView;
@property (weak, nonatomic) IBOutlet UIView *connectView;
@property (weak, nonatomic) IBOutlet UILabel *connectViewTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectViewDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *unlinkButton;
@property (weak, nonatomic) IBOutlet UIImageView *connectViewStateImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusImageYConstraint;
@property (assign, nonatomic) BOOL hasReceivedName;

@end

