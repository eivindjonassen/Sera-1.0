//
//  BluetoothManager.m
//  SeraOSX
//
//  Created by Aurimas Žibas on 2015-11-02.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "BluetoothManager.h"
#import <Cocoa/Cocoa.h>


@implementation BluetoothManager

+ (instancetype)sharedClient {
    static BluetoothManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BluetoothManager alloc] init];
        _sharedClient.supportedServices = @[[CBUUID UUIDWithString:BLE_SERVICE_UUID]];
        _sharedClient.supportedCharacteristics = @[[CBUUID UUIDWithString:BLE_CHARACTERISTICS_SERVICE_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID], [CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]];
    });
    
    return _sharedClient;
}

- (void) scanForDevices {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
}

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:self.supportedServices];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"Did fail to connect");
    NSLog(@"%@",error);
    [self.delegate peripheralDisconnected:peripheral];
    if (self.signalStrengthUpdater){
        [self.signalStrengthUpdater invalidate];
        self.signalStrengthUpdater = nil;
    }
    [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Peripheral disconnected");
    NSLog(@"%@",error);
    [self.delegate peripheralDisconnected:peripheral];
    if (self.signalStrengthUpdater){
        [self.signalStrengthUpdater invalidate];
        self.signalStrengthUpdater = nil;
    }
    [self.centralManager scanForPeripheralsWithServices:self.supportedServices options:nil];
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray<CBPeripheral *> *)peripherals {
    
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:localName forKey:@"iphoneName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.connectedPhone = peripheral;
        [self.centralManager stopScan];
        self.connectedPhone.delegate = self;
        [self.centralManager connectPeripheral:self.connectedPhone options:nil];
    }
    
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
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Bluetooth error!"];
        [alert setInformativeText:@"CoreBluetooth BLE state is unknown"];
        [alert addButtonWithTitle:@"Ok"];
        [alert runModal];
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
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_SERVICE_UUID]]){ // 2
                [self.connectedPhone setNotifyValue:YES forCharacteristic:aChar];
                [self.delegate peripheralSuccessfulyConnected:self.connectedPhone];
                self.signalStrengthUpdater = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestCurrentSignalStrenght) userInfo:nil repeats:NO];
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
                NSLog(@"Found unlink chara..");
                [self.connectedPhone setNotifyValue:YES forCharacteristic:aChar];
                self.unlinkCharacteristic = aChar;
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_UUID]]) { // 3
                NSString *macName = [[NSHost currentHost] localizedName];
                NSData *nameData = [macName dataUsingEncoding:NSUTF8StringEncoding
                                    ];
                int count = 0;
                int dataLength = nameData.length;
                if (dataLength > 20){
                    while (count < dataLength && dataLength - count > 20){
                        [self.connectedPhone writeValue:[nameData subdataWithRange:NSMakeRange(count, 20)] forCharacteristic:aChar type:CBCharacteristicWriteWithoutResponse];
                        
                        [NSThread sleepForTimeInterval:0.005];
                        count += 20;
                    }
                }
                
                if (count < dataLength){
                    
                    for (CBCharacteristic *bChar in service.characteristics){
                        if ([bChar.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID]]){
                    [self.connectedPhone writeValue:[nameData subdataWithRange:NSMakeRange(count, dataLength-count)] forCharacteristic:bChar type:CBCharacteristicWriteWithoutResponse];
                            break;
                        }
                }
                }
//                [self.connectedPhone writeValue:[[[NSHost currentHost] localizedName] dataUsingEncoding:NSUTF8StringEncoding]forCharacteristic:aChar type:CBCharacteristicWriteWithoutResponse];
//                NSLog(@"Found supported characteristic, sending Mac name");
            }
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"peripheral: %@ didUpdateValueForCharacteristics: %@, error: %@",peripheral, characteristic, error)
    ;
    if (peripheral == self.connectedPhone){
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
            NSLog(@"GOT UNLINK!!");
            NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
            [[NSUserDefaults standardUserDefaults]
             removePersistentDomainForName:appDomain];
            [self.delegate deviceUnlinked];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"peripheral: %@ didUpdateNotificationStateForCharacteristic: %@, error: %@",peripheral, characteristic.UUID, error)
    ;

}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    if (self.signalStrengthUpdater){
        [self.signalStrengthUpdater invalidate];
        self.signalStrengthUpdater = nil;
    }
    
    if (!error){
        [self.delegate connectedPhoneDidUpdateRSSI:peripheral.RSSI];
        self.signalStrengthUpdater = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestCurrentSignalStrenght) userInfo:nil repeats:NO];
    }
    
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
    [self.connectedPhone writeValue:payload forCharacteristic:self.unlinkCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

@end
