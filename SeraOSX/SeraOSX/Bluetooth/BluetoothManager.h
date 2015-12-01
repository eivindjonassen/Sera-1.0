//
//  BluetoothManager.h
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;
@import QuartzCore;


#define BLE_SERVICE_UUID @"B500"
#define BLE_CHARACTERISTICS_SERVICE_UUID @"B511"
#define BLE_CHARACTERISTICS_MACNAME_UUID @"B512"
#define BLE_CHARACTERISTICS_MACNAME_LAST_UUID @"B513"
#define BLE_CHARACTERISTICS_UNLINK_UUID @"B514"

@protocol BTManagerDelegate;

@interface BluetoothManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
+ (instancetype)sharedClient;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, retain) CBPeripheral     *connectedPhone;
@property (nonatomic, strong) NSArray *supportedServices;
@property (nonatomic, strong) NSArray *supportedCharacteristics;
@property (nonatomic, strong) NSTimer *signalStrengthUpdater;
@property (nonatomic, strong) CBCharacteristic *unlinkCharacteristic;
@property (nonatomic, weak) id<BTManagerDelegate>delegate;

- (void)scanForDevices;
- (void)sendUnlink;

@end

@protocol BTManagerDelegate <NSObject>
- (void)connectedPhoneDidUpdateRSSI:(NSNumber *)RSSI;
- (void)peripheralSuccessfulyConnected:(CBPeripheral *)peripheral;
- (void)peripheralDisconnected:(CBPeripheral *)peripheral;
- (void)deviceUnlinked;

@end
