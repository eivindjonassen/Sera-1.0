//
//  BluetoothManager.h
//  SeraiOS
//
//  Created by Aurimas Žibas on 2015-11-12.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@import QuartzCore;
@import CoreBluetooth;

#define BLE_SERVICE_UUID @"B500"
#define BLE_CHARACTERISTICS_MAC_UUID @"B511"
#define BLE_CHARACETRISTICS_MACNAME_UUID @"B512"
#define BLE_CHARACTERISTICS_MACNAME_LAST_UUID @"B513"
#define BLE_CHARACTERISTICS_UNLINK_UUID @"B514"
#define BLE_CHARACTERISTICS_DEVICE_UUID @"B515"
#define BLE_CHARACTERISTICS_UPDATE_MAC_UUID @"B516"

@protocol BTManagerDelegate;

@interface BluetoothManager : NSObject <CBPeripheralManagerDelegate, CBPeripheralDelegate>
+ (instancetype)sharedClient;

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBCentral *connectedCentral;
@property(nonatomic, strong) CBMutableCharacteristic *macCharacteristic;
@property(nonatomic, strong) CBUUID *serviceUUID;
@property(nonatomic, strong) CBUUID *macUUID;
@property(nonatomic, strong) CBUUID *macNameUUID;
@property(nonatomic, strong) CBUUID *macNameLastUUID;
@property(nonatomic, strong) CBUUID *unlinkUUID;
@property(nonatomic, strong) CBUUID *deviceUUID;
@property(nonatomic, strong) CBUUID *updateMacUUID;
@property(nonatomic, strong) CBMutableService *deviceInfoService;
@property(nonatomic, strong) CBMutableCharacteristic *macNameCharacteristics;
@property(nonatomic, strong) CBMutableCharacteristic *macNameLastCharacteristics;
@property(nonatomic, strong) CBMutableCharacteristic *unlinkCharacteristics;
@property(nonatomic, strong) CBMutableCharacteristic *deviceCharacteristics;
@property(nonatomic, strong) CBMutableCharacteristic *updateMacUUIDCharacteristics;
@property(nonatomic, assign) BOOL shouldStartAdvertising;
@property(nonatomic, assign) BOOL hasReceivedMacName;
@property(nonatomic, assign) BOOL hasConnectedPeripheral;

@property(weak, nonatomic) id<BTManagerDelegate>delegate;


- (void)initPeripheralManager;
- (void)startAdvertisingIfReady;
- (void)sendUnlinkToCentral;

@end

@protocol BTManagerDelegate <NSObject>
- (void)bluetoothStateDidChanged:(CBPeripheralManagerState) state;
- (void)peripheralSuccessfullyConnected;
- (void)peripheralDisconnected;
- (void)macNameUpdated;
- (void)gotForceUnlink;
- (void)beganAdvertising;
- (void)stopedAdvertising;
@end
