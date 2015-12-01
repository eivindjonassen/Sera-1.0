//
//  BluetoothManager.m
//  SeraiOS
//
//  Created by Aurimas Žibas on 2015-11-12.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "BluetoothManager.h"

@implementation BluetoothManager

+ (instancetype)sharedClient {
    static BluetoothManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BluetoothManager alloc] init];
    });
    
    return _sharedClient;
}

- (void)startAdvertisingIfReady {
    self.shouldStartAdvertising = YES;
    [self checkBluetoothState];
   
}

- (void)checkBluetoothState {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerOptionShowPowerAlertKey, nil];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:options];
}

- (void)startConnection {
    if (self.peripheralManager.isAdvertising){
        [self.peripheralManager stopAdvertising];
    }
    
   // [self.peripheralManager removeAllServices];
    self.serviceUUID = [CBUUID UUIDWithString:BLE_SERVICE_UUID];
    self.characteristicsUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_SERVICE_UUID];
    self.macNameUUID = [CBUUID UUIDWithString:BLE_CHARACETRISTICS_MACNAME_UUID];
    self.macNameLastUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID];
    self.unlinkUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID];
    
    
    self.deviceInfoService = [[CBMutableService alloc] initWithType:self.serviceUUID primary:YES];
    self.deviceInfoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.characteristicsUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    self.macNameCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.macNameUUID properties:CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsWriteable];
    
    self.macNameLastCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.macNameLastUUID properties:CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsWriteable];
    
    self.unlinkCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.unlinkUUID properties:CBCharacteristicPropertyWriteWithoutResponse|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
    
    self.deviceInfoService.characteristics = @[self.deviceInfoCharacteristic, self.macNameCharacteristics, self.macNameLastCharacteristics, self.unlinkCharacteristics];
    [self.peripheralManager addService:self.deviceInfoService];
}



#pragma mark - PeripheralManager delegate

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (self.peripheralManager.isAdvertising){
        [self.peripheralManager stopAdvertising];
    }
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    
    NSDictionary *advertisment = @{
      CBAdvertisementDataServiceUUIDsKey : @[self.serviceUUID],
      CBAdvertisementDataLocalNameKey: (deviceName ? deviceName : @"Sera")
    };
    
    [self.peripheralManager startAdvertising:advertisment];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didSubscribeToCharacteristic");
    NSLog(@"%@",characteristic.UUID);
    if ([characteristic.UUID isEqual:self.characteristicsUUID]){
        
    [self.delegate peripheralSuccessfullyConnected];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"peripheralManagerDidStartAdvertising");
    
    if (error != nil)
    {
        NSLog(@"Unable To Start Advertisement: Error: %@", error);
        //[self.delegate Disconnected_Sender];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didUnsiscripeFromCharacteristic");
    self.hasReceivedMacName = NO;
    [self.delegate peripheralDisconnected];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
   
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate bluetoothStateDidChanged:peripheral.state];
    
    
    switch (peripheral.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"Peripheral powered on");
            if (self.shouldStartAdvertising){
                [self startConnection];
            }
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
             NSLog(@"Peripheral powered off");
            break;
        }
        case CBCentralManagerStateResetting:
        {
             NSLog(@"Peripheral resetting");
            break;
        }
        case CBCentralManagerStateUnauthorized:
        {
             NSLog(@"Peripheral unauthorized");
            break;
        }
        case CBCentralManagerStateUnknown:
        {
            NSLog(@"Peripheral unknown");
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
             NSLog(@"Peripheral unsupported");
            break;
        }
        default:
        {
            NSLog(@"centralManager did update: %ld", (long)peripheral.state);
            break;
        }
    }
    
    

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    for (CBATTRequest *singleRequest in requests){
        if ([singleRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACETRISTICS_MACNAME_UUID]]){
            NSString *macName = [[NSString alloc] initWithData:singleRequest.value encoding:NSUTF8StringEncoding];
            if (!self.hasReceivedMacName){
                self.hasReceivedMacName = YES;
                [[NSUserDefaults standardUserDefaults] setObject:macName forKey:@"macName"];
            } else {
                 NSString *prevName = [[NSUserDefaults standardUserDefaults] stringForKey:@"macName"];
                 [[NSUserDefaults standardUserDefaults] setObject:[prevName stringByAppendingString:macName] forKey:@"macName"];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        } else if ([singleRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID]]){
            NSString *macName = [[NSString alloc] initWithData:singleRequest.value encoding:NSUTF8StringEncoding];
            NSLog(@"LAST NAME CHUNK: %@",macName);
            if (!self.hasReceivedMacName){
                self.hasReceivedMacName = YES;
                [[NSUserDefaults standardUserDefaults] setObject:macName forKey:@"macName"];
            } else {
                NSString *prevName = [[NSUserDefaults standardUserDefaults] stringForKey:@"macName"];
                [[NSUserDefaults standardUserDefaults] setObject:[prevName stringByAppendingString:macName] forKey:@"macName"];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.delegate macNameUpdated];
        } else if ([singleRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
            [self.peripheralManager stopAdvertising];
            [self.delegate gotForceUnlink];
        }
    }
}
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
}

- (void)sendUnlinkToCentral {
    
    NSUInteger index = 1;
    NSData *payload = [NSData dataWithBytes:&index length:sizeof(index)];
    
    if( [self.peripheralManager updateValue:payload forCharacteristic:self.unlinkCharacteristics onSubscribedCentrals:nil]){
        NSLog(@"didSentUnlink");
        [self.peripheralManager stopAdvertising];
    }

}
@end
