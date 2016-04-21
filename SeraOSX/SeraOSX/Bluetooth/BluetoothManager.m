//
//  BluetoothManager.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "BluetoothManager.h"
#import <Cocoa/Cocoa.h>
#import "DeviceUID.h"


@implementation BluetoothManager

+ (instancetype)sharedClient {
    static BluetoothManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BluetoothManager alloc] init];
        _sharedClient.supportedServices = @[[CBUUID UUIDWithString:BLE_SERVICE_UUID]];
        _sharedClient.supportedCharacteristics = @[[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MAC_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_DEVICE_UUID], [CBUUID UUIDWithString:BLE_CHARACTERSITICS_UPDATE_MAC_UUID]];
    });
    
    return _sharedClient;
}

- (void) scanForDevices {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)];
    NSLog(@"Starting scanning");
    [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
}

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral:%@",peripheral);
    //NSArray * peripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:nil];
    //NSLog(@"devices: %@", peripherals);
    
    self.connectedPhone = peripheral;
    peripheral.delegate = self;
    
    if(peripheral.services && peripheral.services.count != 0)
    {
        [self peripheral:peripheral didDiscoverServices:nil];
    }
    else
    {
        [peripheral discoverServices:self.supportedServices];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
     dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"Did fail to connect");
    NSLog(@"%@",error);
         self.hasMacUUID = NO;
         self.hasDeviceUUID = NO;
    [self.delegate peripheralDisconnected:peripheral];
    if (self.signalStrengthUpdater){
        [self.signalStrengthUpdater invalidate];
        self.signalStrengthUpdater = nil;
    }
    
    if (self.connectedPhone){
        self.lastConnectedPhone = self.connectedPhone;
        [self.centralManager connectPeripheral:self.connectedPhone options:nil];
        if (self.connectedPhone.state != CBPeripheralStateConnected){
            [self performSelector:@selector(reconnectToPhone) withObject:nil afterDelay:1.0];
        }
    } else {
        NSLog(@"Starting scanning");
        [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
    }
     });
    
//    self.connectedPhone = nil;
//    NSLog(@"Starting scanning");
//    [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Peripheral disconnected");
        NSLog(@"%@",error);
        self.hasMacUUID = NO;
        self.hasDeviceUUID = NO;
        [self.delegate peripheralDisconnected:peripheral];
        
        //self.connectedPhone = peripheral;
        
        if (self.signalStrengthUpdater){
            [self.signalStrengthUpdater invalidate];
            self.signalStrengthUpdater = nil;
        }
        
//        //    [self.centralManager cancelPeripheralConnection:self.connectedPhone];
//        //    self.connectedPhone = nil;
//        
//        if (self.connectedPhone){
//            //self.lastConnectedPhone = self.connectedPhone;
//            
//            //[self.centralManager cancelPeripheralConnection:self.lastConnectedPhone];
//            //[self.centralManager connectPeripheral:self.lastConnectedPhone options:nil];
//
//            NSLog(@"didDisconnectPeripheral lastConnectedPhone state %li", self.lastConnectedPhone.state);
//            
//            //[self reconnectToPhone];
//            //[self performSelector:@selector(reconnectToPhone) withObject:nil afterDelay:1.0];
//            //[self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
//        
//        } else {
//            
//        }
        
        NSLog(@"Starting scanning");
        [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
        
        //NSLog(@"Starting scanning");
        //[self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
    });
}

- (void) startScan{
    
    NSLog(@"Starting scanning");
    [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
}

- (void) stopScan{
    
    NSLog(@"Stopping scanning");
    [self.centralManager stopScan];
}

- (void)reconnectToPhone {
    
//    if (self.connectedPhone && self.connectedPhone.state == CBPeripheralStateDisconnected)
//    {
//        NSLog(@"Reconnecting to phone with state: %li %f", self.connectedPhone.state, [[NSDate date] timeIntervalSince1970]);
//        //[self.centralManager cancelPeripheralConnection:self.connectedPhone];
//        
//        [self.centralManager connectPeripheral:self.connectedPhone options:nil];
//        //[self performSelector:@selector(reconnectToPhone) withObject:nil afterDelay:1.0];
//    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray<CBPeripheral *> *)peripherals {
    NSLog(@"centralManager: %@ didRetrieveConnectedPeripherals: %@",central, peripherals);
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    NSLog(@"centralManager: %@, willRestoreState: %@", central,dict);
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"centerManager: %@, didDiscoverPeripheral: %@, adveristmentData: %@, RSSI: %@",central, peripheral, advertisementData, RSSI);
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:localName forKey:@"iphoneName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.connectedPhone = peripheral;
    self.connectedPhone.delegate = self;
    
        [self.centralManager cancelPeripheralConnection:peripheral];
        [self.centralManager connectPeripheral:peripheral options:nil];
    
    NSLog(@"Stopping scanning");
    [self.centralManager stopScan];
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        if (self.connectedPhone){
            [self.centralManager connectPeripheral:self.connectedPhone options:nil];
            NSLog(@"Stopping scanning");
            [self.centralManager stopScan];
        }
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Bluetooth error!"];
        [alert setInformativeText:@"CoreBluetooth BLE state is unauthorized"];
        [alert addButtonWithTitle:@"Ok"];
        [alert runModal];
        
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setMessageText:@"Bluetooth error!"];
//        [alert setInformativeText:@"CoreBluetooth BLE state is unknown"];
//        [alert addButtonWithTitle:@"Ok"];
//        [alert runModal];
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Bluetooth error!"];
        [alert setInformativeText:@"CoreBluetooth BLE hardware is unsupported on this platform"];
        [alert addButtonWithTitle:@"Ok"];
        [alert runModal];
    }
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        if ([self.supportedServices containsObject:service.UUID]){
            [peripheral discoverCharacteristics:nil forService:service];
            //self.connectedPhone = peripheral;
            break;
        }
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:BLE_SERVICE_UUID]])  {  // 1
        for (CBCharacteristic *aChar in service.characteristics)
        {
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
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
     dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"peripheral: %@ didUpdateValueForCharacteristics: %@, error: %@",peripheral, characteristic, error)
    ;
    if (peripheral == self.connectedPhone){
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
            NSLog(@"GOT UNLINK!!");
            NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
            [[NSUserDefaults standardUserDefaults]
             removePersistentDomainForName:appDomain];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.connectedPhone = nil;
            [self.delegate deviceUnlinked];
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_DEVICE_UUID]]){
            NSString *savedPhoneUUIDString = [[NSUserDefaults standardUserDefaults] stringForKey:@"phoneUUID"];
            if (savedPhoneUUIDString != nil){
                NSString *peripheralDeviceUUID = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                if ([savedPhoneUUIDString isEqualToString:peripheralDeviceUUID]){ // Connect
                    self.hasDeviceUUID = YES;
                    if (self.hasMacUUID){
                        [self setupConnection];
                    }
                } else {
                    [self.centralManager cancelPeripheralConnection:peripheral];
                    self.connectedPhone = nil;
                    [self scanForDevices];
                }
            } else { //TODO check if all string is passed, connect and save UUID string
                //[peripheral readValueForCharacteristic:characteristic];
                self.hasDeviceUUID = YES;
                NSString *peripheralDeviceUUID = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                
                NSLog(@"Device UID: %@",peripheralDeviceUUID);
                [[NSUserDefaults standardUserDefaults] setObject:peripheralDeviceUUID forKey:@"phoneUUID"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (self.hasMacUUID){
                    [self setupConnection];
                }
            }
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MAC_UUID]]){
             NSString *macDeviceUUID = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            if (macDeviceUUID && macDeviceUUID.length){
                if (![macDeviceUUID isEqualToString:[DeviceUID uid]]){
                    [self.centralManager cancelPeripheralConnection:peripheral];
                    self.connectedPhone = nil;
                    [self scanForDevices];
                } else {
                    self.hasMacUUID = YES;
                    [self setupConnection];
                }
            } else {
                self.hasMacUUID = YES;
                [self sendMacUUID];
                if (self.hasDeviceUUID){
                    [self setupConnection];
                }
            }
        }
    }
     });
}

- (void)setupConnection {
    [self setupCharacteristics];
    [self.delegate peripheralSuccessfulyConnected:self.connectedPhone];
    NSRunLoop * rl = [NSRunLoop mainRunLoop];
    self.signalStrengthUpdater = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestCurrentSignalStrenght) userInfo:nil repeats:NO];
    [rl addTimer:self.signalStrengthUpdater forMode:NSRunLoopCommonModes];
}

- (void)setupCharacteristics{
    if (self.macNameCharacteristic && self.macNameLastCharacteristic){
    NSString *macName = [[NSHost currentHost] localizedName];
    NSData *nameData = [macName dataUsingEncoding:NSUTF8StringEncoding
                        ];
    int count = 0;
    int dataLength = nameData.length;
    if (dataLength > 20){
        while (count < dataLength && dataLength - count > 20){
            [self.connectedPhone writeValue:[nameData subdataWithRange:NSMakeRange(count, 20)] forCharacteristic:self.macNameCharacteristic type:CBCharacteristicWriteWithoutResponse];
            
            [NSThread sleepForTimeInterval:0.005];
            count += 20;
        }
    }
    
    if (count < dataLength){
        
//        for (CBCharacteristic *bChar in service.characteristics){
//            if ([bChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID]]){
                [self.connectedPhone writeValue:[nameData subdataWithRange:NSMakeRange(count, dataLength-count)] forCharacteristic:self.macNameLastCharacteristic type:CBCharacteristicWriteWithoutResponse];
//                break;
//            }
//        }
    }
    }
    
    if (self.unlinkCharacteristic ) {
        [self.connectedPhone setNotifyValue:YES forCharacteristic:self.unlinkCharacteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"peripheral: %@ didUpdateNotificationStateForCharacteristic: %@, error: %@",peripheral, characteristic.UUID, error)
    ;

}

- (void)sendMacUUID {
    if (self.updateMacUUIDCharacteristic){
        NSString *macUID = [DeviceUID uid];
        NSLog(@"Mac UID: %@",macUID);
        NSData *uidData = [macUID dataUsingEncoding:NSUTF8StringEncoding];
        
        int count = 0;
        int dataLength = uidData.length;
        if (dataLength > 20){
            while (count < dataLength && dataLength - count > 20){
                [self.connectedPhone writeValue:[uidData subdataWithRange:NSMakeRange(count, 20)] forCharacteristic:self.updateMacUUIDCharacteristic type:CBCharacteristicWriteWithoutResponse];
                
                [NSThread sleepForTimeInterval:0.005];
                count += 20;
            }
        }
        
        if (count < dataLength){
            [self.connectedPhone writeValue:[uidData subdataWithRange:NSMakeRange(count, dataLength-count)] forCharacteristic:self.updateMacUUIDCharacteristic type:CBCharacteristicWriteWithoutResponse];
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

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    NSLog(@"peripheralDidUpdateName: %@",peripheral);
}  

#pragma mark - CBCharacteristic helpers
- (void)requestCurrentSignalStrenght {
    [self.connectedPhone readRSSI];
}

- (void)sendUnlink {
    NSUInteger index = 1;
    NSData *payload = [NSData dataWithBytes:&index length:sizeof(index)];
    if (self.connectedPhone && self.connectedPhone.state == CBPeripheralStateConnected){
    [self.connectedPhone writeValue:payload forCharacteristic:self.unlinkCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

@end
