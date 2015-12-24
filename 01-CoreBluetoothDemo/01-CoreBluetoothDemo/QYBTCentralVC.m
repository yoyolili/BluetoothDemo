//
//  QYBTCentralVC.m
//  01-CoreBluetoothDemo
//
//  Created by qingyun on 15/12/22.
//  Copyright © 2015年 qingyun. All rights reserved.
//

#import "QYBTCentralVC.h"
#import "QyTransfer.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface QYBTCentralVC () <CBCentralManagerDelegate,CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *scanSwitch;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong)CBPeripheral *discoverdPeripheral;//记录已经发现的设备
@property (nonatomic, strong)NSMutableData *data;

@end

@implementation QYBTCentralVC

#pragma mark - lazy loading
- (NSMutableData *)data
{
    if (_data == nil) {
        _data = [NSMutableData data];
    }
    return _data;
}

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1. 创建central manager对象
   _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - CBCentralManagerDelegate
/*
 *当central设备的状态改变之后回调
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"[INFO]: 蓝牙未开启!");
        return;
    }
}
/*
 *当central设备发现peripheral设备发出的AD报文时调用该方法
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //如果已经发现过该设备，则直接返回，否则保存该设备并开始连接该设备
    if (self.discoverdPeripheral == peripheral) {
        return;
    }
    NSLog(@"[INFO]: 已经发现peripheral设备>>> %@ - %@",peripheral.name, RSSI);
    
    //保存该设备
    self.discoverdPeripheral = peripheral;
    
    peripheral.delegate = self;
    
    [self.centralManager connectPeripheral:peripheral options:0];
}

/*
 *当central设备连接peripheral设备失败时回调
 */
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"[ERROR]: 连接 %@ 失败\terror >>> %@",peripheral, error);
}
/*
 *当central与periphrial连接成功的回调
 */
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //一旦连接成功，就立刻停止扫描
    [self.centralManager stopScan];
    NSLog(@"[INFO]: 正在停止扫描...");
    
    //清空已经存储的数据，为了重新接收数据
    self.data.length = 0;
    
    //发现服务 -- 根据UUID发现感兴趣的服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}
/*
 *断开连接
 */
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error) {
        NSLog(@"[ERROR]: 断开连接失败\terror >>> %@",error);
    }
    NSLog(@"[INFO]: 连接已断开");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _scanSwitch.on = NO;
    });
    
    self.discoverdPeripheral = nil;
}

#pragma mark - CBPeripheralDelegate
/*
 *发现service之后的回调
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"[ERROR]: Peripheral设备发现服务失败\terror >>> %@",error);
        [self cleanup];
        return;
    }
    //遍历所有服务发现所有的特性Characterstics
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERSTICS_UUID]] forService:service];
    }
}
/*
 *发现Characteristic之后的回调
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"[ERROR]: Peripheral设备发现特性失败\terror >>> %@",error);
        [self cleanup];
        return;
    }
    
    //遍历该服务的所有特性，然后订阅这些特性
    for (CBCharacteristic *charact in service.characteristics) {
        //订阅该Characteristic
        [peripheral setNotifyValue:YES forCharacteristic:charact];
    }
}
/*
 *收到数据更新之后的回调
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"[ERROR]: 更新数据失败\terror >>> %@",error);
        [self cleanup];
        return;
    }
    //取出数据
    NSData *data = characteristic.value;
    //解析数据
    [self parseData:data withPeripherial:peripheral andCharacteristic:characteristic];
    
    
}
/*
 *订阅状态发生变化时发生的回调
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"[ERROR]: setNotifyValue:forCharacteristic:失败\terror >>> %@",error);
        [self cleanup];
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"[INFO]: 正在订阅%@",characteristic);
    }else{
        NSLog(@"[INFO]: 取消订阅%@",characteristic);
    }
}


#pragma mark - misc process
- (void)cleanup
{
    if (self.discoverdPeripheral.state == CBPeripheralStateConnected) {
        return;
    }
    
    //遍历所有服务的特性,并且取消订阅
    if (self.discoverdPeripheral.services != nil) {
        for (CBService *service in self.discoverdPeripheral.services) {
            if (service.characteristics) {
                for (CBCharacteristic *charact in service.characteristics) {
                    if ([charact.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERSTICS_UUID]]) {
                        [self.discoverdPeripheral setNotifyValue:NO forCharacteristic:charact];
                    }
                }
            }
        }
    }
    
    //断开central与peripheral设备之间的连接
    
}

/*
 *更新数据
 */
- (void)parseData:(NSData *)data withPeripherial:(CBPeripheral *)peripherial andCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[DEBUG]: dataString >>> %@",dataStr);
    
    //EOM - End Of Message
    if ([dataStr isEqualToString:EOM]) {
        //接收数据完毕
        
        //更新UI
        _textView.text = [[NSString alloc]initWithData:self.data encoding:NSUTF8StringEncoding];
        
        //取消订阅
        [peripherial setNotifyValue:NO forCharacteristic:characteristic];
        
        //断开连接
        [self.centralManager cancelPeripheralConnection:peripherial];
        
        return;
    }
    
    //拼接数据
    [self.data appendData:data];
}

#pragma mark - events handling
- (IBAction)toggleScan:(UISwitch *)sender {
    if (sender.on) {
        // scan-----UUID数组
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:0];
        NSLog(@"[INFO]: 开始扫描...");
        
    } else {
        // stop scan
        [self.centralManager stopScan];
    }
}

@end
