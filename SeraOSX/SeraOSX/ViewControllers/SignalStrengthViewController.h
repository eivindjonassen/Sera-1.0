//
//  SignalStrengthViewController.h
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SignalStrengthViewController : NSViewController
@property (weak) IBOutlet NSSlider *signalStrengthSlider;
@property (weak) IBOutlet NSProgressIndicator *currentSignalStrengthProgressBar;
- (IBAction)onSaveClick:(id)sender;

@end
