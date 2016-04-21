//
//  BluetoothManager2.m
//  SeraOSX
//
//  Created by develop on 14/04/16.
//  Copyright © 2016 Ignitum. All rights reserved.
//

#import "BluetoothManager2.h"

@interface BluetoothManager2()

@property (strong, nonatomic) NSString* foundDeviceName;

@end

@implementation BluetoothManager2

+ (instancetype)sharedClient {
    static BluetoothManager2 *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BluetoothManager2 alloc] init];
        _sharedClient.supportedServices = @[[CBUUID UUIDWithString:BLE_SERVICE_UUID]];
        _sharedClient.supportedCharacteristics = @[[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MAC_UUID],
                                                   [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_UUID],
                                                   [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID],
                                                   [CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID],
                                                   [CBUUID UUIDWithString:BLE_CHARACTERISTICS_DEVICE_UUID],
                                                   [CBUUID UUIDWithString:BLE_CHARACTERSITICS_UPDATE_MAC_UUID]];
    });
    
    return _sharedClient;
}

- (void) initCentralManager {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)];
    LOG(@"scanForDevices");
    [self scanForPeripherals];
}

- (void)scanForPeripheralsAfterDelay {
    LOG(@"Will scan for peripherals after delay");
    [self performSelector:@selector(scanForPeripherals) withObject:nil afterDelay:2.0];
}

- (void)scanForPeripherals {
    dispatch_async(dispatch_get_main_queue(), ^{
        LOG(@"Will scan for peripherals (connected phone %@)", self.connectedPhone);
        [self.centralManager stopScan];
        [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
        [self performSelector:@selector(startScanningForPeripheralsIfNoPhoneIsConnected) withObject:nil afterDelay:10.0];
    });
}

- (void)startScanningForPeripheralsIfNoPhoneIsConnected {
    if (!self.connectedPhone) {
        LOG(@"Start scanning by timer");
        [self scanForPeripherals];
    }
}

#pragma mark CBCentralManagerDelegate

// Manager updated state
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    LOG(@"centralManagerDidUpdateState: %@", central);
    
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        LOG(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        LOG(@"CoreBluetooth BLE hardware is powered on and ready");
        if (self.connectedPhone){
            [self.centralManager connectPeripheral:self.connectedPhone options:nil];
            NSLog(@"Stopping scanning");
            [self.centralManager stopScan];
        } else {
            [self scanForPeripheralsAfterDelay];
        }
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        LOG(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        LOG(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        LOG(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}

// Discovered
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    LOG(@"centralManager: didDiscoverPeripheral:%@ advertisementData:%@ RSSI:%@", peripheral, advertisementData, RSSI);
    
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    LOG(@"localName: %@", localName);
    if ([localName length] > 0) {
        _foundDeviceName = localName;
    }
    
    LOG(@"Stop scan");
    [self.centralManager stopScan];
    
    [self.centralManager cancelPeripheralConnection:peripheral];
    
    self.connectedPhone = peripheral;
    peripheral.delegate = self;
    
    LOG(@"Will try to connect to %@", self.connectedPhone.name);
    // Initiates a connection to peripheral. Connection attempts never time out and, depending on the outcome, will result
    // in a call to either {centralManager:didConnectPeripheral:} or {centralManager:didFailToConnectPeripheral:error:}.
    // Pending attempts are cancelled automatically upon deallocation of peripheral, and explicitly via {cancelPeripheralConnection}.
    [self.centralManager connectPeripheral:self.connectedPhone options:nil];
}

// Connected
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    LOG(@"centralManager: didConnectPeripheral:%@", peripheral);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        LOG(@"Will call discoverServices:");
        [peripheral discoverServices:self.supportedServices];
    });
}

// Disconnected
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    LOG(@"centralManager: didDisconnectPeripheral:%@ error:%@", peripheral, error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.hasMacUUID = NO;
        self.hasDeviceUUID = NO;
        [self.delegate peripheralDisconnected:peripheral];
        peripheral.delegate = nil;
        self.connectedPhone = nil;
        
        if (self.signalStrengthUpdater){
            [self.signalStrengthUpdater invalidate];
            self.signalStrengthUpdater = nil;
        }
        
        [self scanForPeripheralsAfterDelay];
    });
}

// Fail to connect
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    LOG(@"centralManager: didFailToConnectPeripheral:%@ error:%@", peripheral, error);
    
    [self.delegate peripheralDisconnected:peripheral];
    peripheral.delegate = nil;
    
    [self scanForPeripheralsAfterDelay];
}

// Did retrieve connected peripherals
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray<CBPeripheral *> *)peripherals {
    LOG(@"centralManager: didRetrieveConnectedPeripherals:%@", peripherals);
}

// Will restore state
- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    LOG(@"centralManager: willRestoreState:%@", dict);
}

#pragma mark CBPeripheralDelegate

// Did discover services
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    LOG(@"peripheral:%@ didDiscoverServices:", peripheral.name);
    if (error) LOG(@"error:%@", error);
    
    for (CBService *service in peripheral.services) {
        LOG(@"Discovered service: %@", service.UUID);
        if ([self.supportedServices containsObject:service.UUID]){
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    LOG(@"peripheral:%@ didDiscoverCharacteristicsForService:%@", peripheral.name, service);
    if ([service.UUID isEqual:[CBUUID UUIDWithString:BLE_SERVICE_UUID]])  {  // 1
        for (CBCharacteristic *aChar in service.characteristics) {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_DEVICE_UUID]]){
                [peripheral readValueForCharacteristic:aChar];
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MAC_UUID]]){
                [peripheral readValueForCharacteristic:aChar];
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
                self.unlinkCharacteristic = aChar;
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_UUID]]) { // 3
                self.macNameCharacteristic = aChar;
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID]]){
                self.macNameLastCharacteristic = aChar;
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERSITICS_UPDATE_MAC_UUID]]){
                self.updateMacUUIDCharacteristic = aChar;
            }
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"peripheral: %@ didUpdateValueForCharacteristic: %@, error: %@",peripheral.name, characteristic, error);
        if (peripheral == self.connectedPhone){
            
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
                NSLog(@"GOT UNLINK!!");
                
                NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
                [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                self.connectedPhone = nil;
                self.hasMacUUID = NO;
                self.hasDeviceUUID = NO;
                
                [self.delegate deviceUnlinked];
            } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_DEVICE_UUID]]){
                NSString *savedPhoneUUIDString = [[NSUserDefaults standardUserDefaults] stringForKey:@"phoneUUID"];
                NSString *peripheralDeviceUUID = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                
                if (savedPhoneUUIDString != nil){
                    
                    if ([savedPhoneUUIDString isEqualToString:peripheralDeviceUUID]){ // Connect
                        self.hasDeviceUUID = YES;
                        
                        [self setupConnection];
                        
                    } else {
                        [self.centralManager cancelPeripheralConnection:peripheral];
                        self.connectedPhone = nil;
                        // [self scanForDevices];
                        [self scanForPeripheralsAfterDelay];
                    }
                } else { //TODO check if all string is passed, connect and save UUID string
                    //[peripheral readValueForCharacteristic:characteristic];
                    self.hasDeviceUUID = YES;
                    
                    NSLog(@"Device UID: %@",peripheralDeviceUUID);
                    [[NSUserDefaults standardUserDefaults] setObject:peripheralDeviceUUID forKey:@"phoneUUID"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [self setupConnection];
                    
                }
            } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MAC_UUID]]){
                NSString *macDeviceUUID = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                if (macDeviceUUID && macDeviceUUID.length){
                    if (![macDeviceUUID isEqualToString:[DeviceUID uid]]){
                        [self.centralManager cancelPeripheralConnection:peripheral];
                        self.connectedPhone = nil;
                        // [self scanForDevices];
                        [self scanForPeripheralsAfterDelay];
                    } else {
                        self.hasMacUUID = YES;
                        [self setupConnection];
                    }
                } else {
                    self.hasMacUUID = YES;
                    // [self sendMacUUID];
                    [self setupConnection];
                }
            }
        }
    });
}

- (void)setupConnection {
    LOG(@"Setup connection?");
    
    if (!self.hasDeviceUUID || !self.hasMacUUID) return;
    
    LOG(@"Yes, setup connection");
    
    [self setupCharacteristics];
    [self.delegate peripheralSuccessfulyConnected:self.connectedPhone];
    NSRunLoop * rl = [NSRunLoop mainRunLoop];
    self.signalStrengthUpdater = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestCurrentSignalStrenght) userInfo:nil repeats:NO];
    [rl addTimer:self.signalStrengthUpdater forMode:NSRunLoopCommonModes];
    
    [[NSUserDefaults standardUserDefaults] setObject:_foundDeviceName ? _foundDeviceName : @"" forKey:@"iphoneName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupCharacteristics{
    if (self.macNameCharacteristic && self.macNameLastCharacteristic){
        NSString *macName = [[NSHost currentHost] localizedName];
        NSData *nameData = [macName dataUsingEncoding:NSUTF8StringEncoding];
        NSInteger sentDataCount = 0;
        NSInteger dataLength = (NSInteger)nameData.length;
        
        LOG(@"Send macName %@", macName);
        
        while (sentDataCount < dataLength) {
            // If data that is left is longer than 20, make it 20, otherwise - what is left
            
            NSInteger pieceToBeSent = dataLength - sentDataCount > 20 ? 20 : dataLength - sentDataCount;
            
            if (dataLength - sentDataCount > 20) {
                // If not last chunk, send as macNameCharacteristic
                [self.connectedPhone writeValue:[nameData subdataWithRange:NSMakeRange(sentDataCount, pieceToBeSent)] forCharacteristic:self.macNameCharacteristic type:CBCharacteristicWriteWithoutResponse];
            } else {
                // If last chunk, send as macNameLastCharacteristic
                [self.connectedPhone writeValue:[nameData subdataWithRange:NSMakeRange(sentDataCount, pieceToBeSent)] forCharacteristic:self.macNameLastCharacteristic type:CBCharacteristicWriteWithoutResponse];
            }
            
            [NSThread sleepForTimeInterval:0.005];
            sentDataCount += pieceToBeSent;
        }
    }

    if (self.unlinkCharacteristic ) {
        [self.connectedPhone setNotifyValue:YES forCharacteristic:self.unlinkCharacteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"peripheral: %@ didUpdateNotificationStateForCharacteristic: %@, error: %@",peripheral, characteristic.UUID, error);
}

- (void)sendMacUUID {
    if (self.updateMacUUIDCharacteristic){
        NSString *macUID = [DeviceUID uid];
        NSLog(@"Mac UID: %@",macUID);
        NSData *uidData = [macUID dataUsingEncoding:NSUTF8StringEncoding];
        
        NSInteger sentDataCount = 0;
        NSInteger dataLength = (NSInteger)uidData.length;
        
        while (sentDataCount < dataLength) {
            // If data that is left is longer than 20, make it 20, otherwise - what is left
            
            NSInteger pieceToBeSent = dataLength - sentDataCount > 20 ? 20 : dataLength - sentDataCount;
            
            [self.connectedPhone writeValue:[uidData subdataWithRange:NSMakeRange(sentDataCount, pieceToBeSent)] forCharacteristic:self.updateMacUUIDCharacteristic type:CBCharacteristicWriteWithoutResponse];
            
            [NSThread sleepForTimeInterval:0.005];
            sentDataCount += pieceToBeSent;
        }
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.signalStrengthUpdater){
            [self.signalStrengthUpdater invalidate];
            self.signalStrengthUpdater = nil;
        }
        
        if (!error){
            [self.delegate connectedPhoneDidUpdateRSSI:peripheral.RSSI];
            NSRunLoop * rl = [NSRunLoop mainRunLoop];
            self.signalStrengthUpdater = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestCurrentSignalStrenght) userInfo:nil repeats:NO];
            [rl addTimer:self.signalStrengthUpdater forMode:NSRunLoopCommonModes];
        }
    });
    
}

- (void)requestCurrentSignalStrenght {
    [self.connectedPhone readRSSI];
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    NSLog(@"peripheralDidUpdateName: %@",peripheral);
}

- (void)sendUnlink {
    LOG(@"sendUnlink");
    NSUInteger index = 1;
    NSData *payload = [NSData dataWithBytes:&index length:sizeof(index)];
    if (self.connectedPhone && self.connectedPhone.state == CBPeripheralStateConnected){
        [self.connectedPhone writeValue:payload forCharacteristic:self.unlinkCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

@end
