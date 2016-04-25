//
//  BluetoothManager.m
//  SeraiOS
//
//  Created by Aurimas Žibas on 2015-11-12.
//  Copyright © 2015 Ignitum. All rights reserved.
//

#import "BluetoothManager.h"
#import "DeviceUID.h"

@implementation BluetoothManager

+ (instancetype)sharedClient {
    static BluetoothManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[BluetoothManager alloc] init];
        _sharedClient.hasConnectedPeripheral = NO;
    });
    
    return _sharedClient;
}

- (void)initPeripheralManager {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],
                             CBCentralManagerOptionShowPowerAlertKey, @"sera-location-identifier",
                             CBPeripheralManagerOptionRestoreIdentifierKey,
                             nil];
    self.shouldStartAdvertising = YES;
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0) options:options];
}

- (void)addDeviceInfoService {
    NSLog(@"addDeviceInfoService");
    if (self.peripheralManager.isAdvertising){
        NSLog(@"Stopping advertising");
        [self.delegate stopedAdvertising];
        [self.peripheralManager stopAdvertising];
    }
    
    [self.peripheralManager removeAllServices];
    if (self.serviceUUID == nil){
        self.serviceUUID = [CBUUID UUIDWithString:BLE_SERVICE_UUID];
        self.macUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MAC_UUID];
        self.macNameUUID = [CBUUID UUIDWithString:BLE_CHARACETRISTICS_MACNAME_UUID];
        self.macNameLastUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_MACNAME_LAST_UUID];
        self.unlinkUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID];
        self.deviceUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_DEVICE_UUID];
        self.updateMacUUID = [CBUUID UUIDWithString:BLE_CHARACTERISTICS_UPDATE_MAC_UUID];
        
        NSLog(@"Device UUID: %@",[DeviceUID uid]);
        
        self.deviceInfoService = [[CBMutableService alloc] initWithType:self.serviceUUID primary:YES];
        self.macCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.macUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        
        self.macNameCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.macNameUUID properties:CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsWriteable];
        
        self.macNameLastCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.macNameLastUUID properties:CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsWriteable];
        
        self.unlinkCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.unlinkUUID properties:CBCharacteristicPropertyWriteWithoutResponse|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
        
        self.deviceCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.deviceUUID properties:CBCharacteristicPropertyRead value:[[DeviceUID uid]dataUsingEncoding:NSUTF8StringEncoding] permissions:CBAttributePermissionsReadable];
        
        self.updateMacUUIDCharacteristics = [[CBMutableCharacteristic alloc] initWithType:self.updateMacUUID properties:CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsWriteable];
        
    }
    self.deviceInfoService.characteristics = @[self.macCharacteristic, self.macNameCharacteristics, self.macNameLastCharacteristics, self.unlinkCharacteristics , self.deviceCharacteristics, self.updateMacUUIDCharacteristics];
    [self.peripheralManager addService:self.deviceInfoService];
}

- (void)startAdvertisingIfReady {
    [self startAdvertisingIfNotConnected];
}

- (void)startAdvertisingIfNotConnected {
    if (!self.hasConnectedPeripheral) {
        [self startAdvertising];
    }
}

- (void)startAdvertising {
    if (self.peripheralManager.isAdvertising){
        NSLog(@"Stopping advertising");
        [self.delegate stopedAdvertising];
        [self.peripheralManager stopAdvertising];
    }
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    
    if (!self.serviceUUID) [self addDeviceInfoService];
    NSDictionary *advertisment = @{
                                   CBAdvertisementDataServiceUUIDsKey : @[self.serviceUUID],
                                   CBAdvertisementDataLocalNameKey: (deviceName ? deviceName : @"Sera")
                                   };
    
    NSLog(@"Starting advertising");
    [self.delegate beganAdvertising];
    [self.peripheralManager startAdvertising:advertisment];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startAdvertisingIfNotConnected) object:nil];
    
    [self performSelector:@selector(startAdvertisingIfNotConnected) withObject:nil afterDelay:15];
}

#pragma mark - PeripheralManager delegate

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"peripheralManager: didAddService:%@ error:%@", service, error);
    
    // [self startAdvertising];
}

// Subscribed to characteristic
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didSubscribeToCharacteristic %@",characteristic.UUID);
    if ([characteristic.UUID isEqual:self.unlinkUUID]){
        self.connectedCentral = central;
        self.hasConnectedPeripheral = YES;
        [self.delegate peripheralSuccessfullyConnected];
    }
}

// Started advertising
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"peripheralManagerDidStartAdvertising");
    
    if (error) {
        NSLog(@"Unable To Start Advertisement: Error: %@", error);
    }
}

// Unsubscibed to characteristic
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didUnsiscripeFromCharacteristic");
    self.hasReceivedMacName = NO;
    self.hasConnectedPeripheral = NO;
    [self.delegate peripheralDisconnected];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    [_delegate bluetoothStateDidChanged:peripheral.state];
    NSLog(@"peripheralManagerDidUpdateState");
    
    switch (peripheral.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"Peripheral powered on");
            if (self.shouldStartAdvertising){
                [self addDeviceInfoService];
            }
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            NSLog(@"Peripheral powered off");
            if (self.connectedCentral){
                self.hasConnectedPeripheral = NO;
                [self.delegate peripheralDisconnected];
                NSLog(@"Stopping advertising");
                [self.delegate stopedAdvertising];
                [self.peripheralManager stopAdvertising];
                [self.peripheralManager removeAllServices];
            }
            self.hasReceivedMacName = NO;
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

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *,id> *)dict {
    NSLog(@"peripheralManager: %@ willRestoreState: %@",peripheral, dict);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"peripheralManager didReceiveReadRequest");
    if ([request.characteristic.UUID isEqual:self.macCharacteristic.UUID]){
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"mac_uuid"]dataUsingEncoding:NSUTF8StringEncoding].length){
            request.value = [[[NSUserDefaults standardUserDefaults] stringForKey:@"mac_uuid"]dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            request.value = [@"" dataUsingEncoding:NSUTF8StringEncoding];
        }
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        [self.peripheralManager updateValue:request.value forCharacteristic:self.macCharacteristic onSubscribedCentrals:nil];
    }
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    NSLog(@"didReceiveWriteRequests");
    
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
                self.hasReceivedMacName = NO;
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.delegate macNameUpdated];
        } else if ([singleRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UNLINK_UUID]]){
            NSLog(@"Stopping advertising");
            [self.delegate stopedAdvertising];
            [self.peripheralManager stopAdvertising];
            [self.delegate gotForceUnlink];
            self.serviceUUID = nil;
        } else if ([singleRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:BLE_CHARACTERISTICS_UPDATE_MAC_UUID]]){
            NSLog(@"%@",[[NSString alloc] initWithData:singleRequest.value encoding:NSUTF8StringEncoding]);
            [self.macCharacteristic setValue:singleRequest.value];
            [[NSUserDefaults standardUserDefaults] setObject:[[NSString alloc] initWithData:singleRequest.value encoding:NSUTF8StringEncoding] forKey:@"mac_uuid"];
            [[NSUserDefaults standardUserDefaults] synchronize];
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
        NSLog(@"Stopping advertising");
        [self.delegate stopedAdvertising];
        [self.peripheralManager stopAdvertising];
        self.hasReceivedMacName = NO;
        self.serviceUUID = nil;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startAdvertisingIfNotConnected) object:nil];
        
    }

}
@end
