//
//  IGNSignalStrengthView.h
//  SeraOSX
//
//  Created by Aurimas Žibas on 2016-01-21.
//  Copyright © 2016 Ignitum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IGNSignalStrengthView : NSView
@property (weak) IBOutlet NSProgressIndicator *signalStrengthIndicator;
- (NSArray*)loadFromNib;
@end
