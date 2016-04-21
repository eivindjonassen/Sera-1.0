//
//  BluetoothManager2.h
//  SeraOSX
//
//  Created by develop on 14/04/16.
//  Copyright © 2016 Ignitum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DeviceUID.h"
#import "CustomLogger.h"

#define BLE_SERVICE_UUID @"B500"
#define BLE_CHARACTERISTICS_MAC_UUID @"B511"
#define BLE_CHARACTERISTICS_MACNAME_UUID @"B512"
#define BLE_CHARACTERISTICS_MACNAME_LAST_UUID @"B513"
#define BLE_CHARACTERISTICS_UNLINK_UUID @"B514"
#define BLE_CHARACTERISTICS_DEVICE_UUID @"B515"
#define BLE_CHARACTERSITICS_UPDATE_MAC_UUID @"B516"

// BTManagerDelegate protocol
@protocol BTManagerDelegate <NSObject>
- (void)connectedPhoneDidUpdateRSSI:(NSNumber *)RSSI;
- (void)peripheralSuccessfulyConnected:(CBPeripheral *)peripheral;
- (void)peripheralDisconnected:(CBPeripheral *)peripheral;
- (void)deviceUnlinked;
@end

// BluetoothManager2 interface
@interface BluetoothManager2 : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (instancetype)sharedClient;

// Services and characteristics
@property (nonatomic, strong) NSArray *supportedServices;
@property (nonatomic, strong) NSArray *supportedCharacteristics;

// Central manager
@property (nonatomic, strong) CBCentralManager *centralManager;

// Peripherals
@property (nonatomic, strong) CBPeripheral *connectedPhone;

// Delegate
@property (nonatomic, weak) id<BTManagerDelegate>delegate;

// Characteristics
@property (nonatomic, strong) CBCharacteristic *unlinkCharacteristic;
@property (nonatomic, strong) CBCharacteristic *macCharacteristic;
@property (nonatomic, strong) CBCharacteristic *macNameCharacteristic;
@property (nonatomic, strong) CBCharacteristic *macNameLastCharacteristic;
@property (nonatomic, strong) CBCharacteristic *deviceUDIDCharacteristic;
@property (nonatomic, strong) CBCharacteristic *updateMacUUIDCharacteristic;

@property (nonatomic, assign) BOOL hasMacUUID;
@property (nonatomic, assign) BOOL hasDeviceUUID;

// Timers
@property (nonatomic, strong) NSTimer *signalStrengthUpdater;

// Methods
- (void)initCentralManager;
- (void)sendUnlink;

@end