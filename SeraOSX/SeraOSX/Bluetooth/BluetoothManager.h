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
#define BLE_CHARACTERISTICS_MAC_UUID @"B511"
#define BLE_CHARACTERISTICS_MACNAME_UUID @"B512"
#define BLE_CHARACTERISTICS_MACNAME_LAST_UUID @"B513"
#define BLE_CHARACTERISTICS_UNLINK_UUID @"B514"
#define BLE_CHARACTERISTICS_DEVICE_UUID @"B515"
#define BLE_CHARACTERSITICS_UPDATE_MAC_UUID @"B516"

@protocol BTManagerDelegate;

@interface BluetoothManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
+ (instancetype)sharedClient;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *connectedPhone;
@property (nonatomic, strong) CBPeripheral *lastConnectedPhone;
@property (nonatomic, strong) NSArray *supportedServices;
@property (nonatomic, strong) NSArray *supportedCharacteristics;
@property (nonatomic, strong) NSTimer *signalStrengthUpdater;
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, strong) CBCharacteristic *unlinkCharacteristic;
@property (nonatomic, strong) CBCharacteristic *macCharacteristic;
@property (nonatomic, strong) CBCharacteristic *macNameCharacteristic;
@property (nonatomic, strong) CBCharacteristic *macNameLastCharacteristic;
@property (nonatomic, strong) CBCharacteristic *deviceUDIDCharacteristic;
@property (nonatomic, strong) CBCharacteristic *updateMacUUIDCharacteristic;
@property (nonatomic, weak) id<BTManagerDelegate>delegate;
@property (nonatomic, assign) BOOL hasMacUUID;
@property (nonatomic, assign) BOOL hasDeviceUUID;

- (void)scanForDevices;
- (void)sendUnlink;

@end

@protocol BTManagerDelegate <NSObject>
- (void)connectedPhoneDidUpdateRSSI:(NSNumber *)RSSI;
- (void)peripheralSuccessfulyConnected:(CBPeripheral *)peripheral;
- (void)peripheralDisconnected:(CBPeripheral *)peripheral;
- (void)deviceUnlinked;

@end
