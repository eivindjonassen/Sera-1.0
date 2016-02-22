//
//  IGNSignalStrengthView.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2016-01-21.
//  Copyright © 2016 Ignitum. All rights reserved.
//

#import "IGNSignalStrengthView.h"

@implementation IGNSignalStrengthView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
- (IBAction)signalChanged:(id)sender {
     [[NSUserDefaults standardUserDefaults] setInteger:self.signalStrengthSlider.doubleValue forKey:@"signalStrength"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray*)loadFromNib

{
    
    NSNib*      aNib = [[NSNib alloc] initWithNibNamed:@"IGNSignalStrengthView" bundle:nil];
    
    NSArray*    topLevelObjs = nil;
    
    
    
    if (![aNib instantiateNibWithOwner:self topLevelObjects:&topLevelObjs])
        
    {
        
        NSLog(@"Warning! Could not load nib file.\n");
        
        return nil;
        
    }
    
    // Release the raw nib data.
    
    
    
    
    // Release the top-level objects so that they are just owned by the array.
    
    //[topLevelObjs makeObjectsPerformSelector:@selector(release)];
    
    
    
    // Do not autorelease topLevelObjs.
    
    return topLevelObjs;
    
}

@end
