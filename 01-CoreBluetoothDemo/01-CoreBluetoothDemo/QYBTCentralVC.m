//
//  QYBTCentralVC.m
//  01-CoreBluetoothDemo
//
//  Created by qingyun on 15/12/22.
//  Copyright © 2015年 qingyun. All rights reserved.
//

#import "QYBTCentralVC.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface QYBTCentralVC () <CBCentralManagerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *scanSwitch;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) CBCentralManager *manager;

@end

@implementation QYBTCentralVC

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1. 创建central manager对象
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"[INFO]: 蓝牙未开启!");
        return;
    }
}

#pragma mark - events handling
- (IBAction)toggleScan:(UISwitch *)sender {
    if (sender.on) {
        // scan
    } else {
        // stop scan
    }
}

@end
