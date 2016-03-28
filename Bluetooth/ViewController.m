//
//  ViewController.m
//  Bluetooth
//
//  Created by 李文深 on 16/3/22.
//  Copyright © 2016年 30pay. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MBProgressHUD+Extension.h"

//01 41 0C 46 3C 55 2D 40 1F 00 00 01 08 00 00 解绑指令

#define myUUID @"F99CD4A7-19D7-A33C-E4FD-EDDA2CCD4747"  //设备UUID

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>

/**
 *  外设
 */
@property (nonatomic, strong) NSMutableArray *peripherals;

/**
 *  中心管理者
 */
@property (nonatomic, strong) CBCentralManager *mgr;
/**
 *  手环外设
 */
@property (nonatomic, strong) CBPeripheral *peripheral;
/**
 *  ServiceUUID
 */
@property (nonatomic, strong) CBUUID *serviceUUID;

/**
 *  写的特征UUID
 */
@property (nonatomic, strong) CBUUID *txCharacteristicUUID;

/**
 *  读的特征UUID
 */
@property (nonatomic, strong) CBUUID *rxCharacteristicUUID;

/**
 *  读的特征
 */
@property (nonatomic, strong) CBCharacteristic *rxCharacteristic;

/**
 *  写的特征
 */
@property (nonatomic, strong) CBCharacteristic *txCharacteristic;

@end

@implementation ViewController


- (CBUUID *)serviceUUID {
    if (!_serviceUUID) {
        _serviceUUID = [CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"];
    }
    return _serviceUUID;
}

- (CBUUID *)txCharacteristicUUID {
    if (!_txCharacteristicUUID) {
        _txCharacteristicUUID = [CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"];
    }
    return _txCharacteristicUUID;
}

- (CBUUID *)rxCharacteristicUUID {
    if (!_rxCharacteristicUUID) {
        _rxCharacteristicUUID = [CBUUID UUIDWithString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"];
    }
    return _rxCharacteristicUUID;
}

- (NSMutableArray *)peripherals {
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送指令" style:UIBarButtonItemStylePlain target:self action:@selector(rightItemClick)];
    
    // 创建中心设备
    CBCentralManager *mgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.mgr = mgr;
    
}

- (void)rightItemClick {
    [self writeData];
}

#pragma 写数据
- (void) writeData {
    //准备要写的数据
    Byte byteData[] = {0,0xc0,0};
    NSData *data = [[NSData alloc] initWithBytes:byteData length:sizeof(byteData)];
    
    if ((self.txCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0) {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else if ((self.txCharacteristic.properties & CBCharacteristicPropertyWrite) != 0) {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithResponse];
    } else {
        NSLog(@"No write property on TX characteristic, %zd.", self.txCharacteristic.properties);
    }
}

#pragma mark - CBCentralManagerDelegate
#pragma mark - 中心管理器发现外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // 保存扫描到得外部设备
    // 判断如果数组中不包含当前扫描到得外部设置才保存
    if (![self.peripherals containsObject:peripheral]) {
        
        peripheral.delegate = self;
        [self.peripherals addObject:peripheral];
        [self.tableView reloadData];
    }
}

#pragma mark - 中心管理器状态发生变化回调
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    switch (central.state) {
        case CBCentralManagerStateUnknown:
            [MBProgressHUD showError:@"发生未知错误,请重试"];
            break;
        case CBCentralManagerStateResetting:
            [MBProgressHUD showError:@"您的蓝牙处于重置状态,请稍后从事"];
            break;

        case CBCentralManagerStateUnsupported:
            [MBProgressHUD showError:@"您的手机不支持蓝牙技术"];
            break;

        case CBCentralManagerStateUnauthorized:
            [MBProgressHUD showError:@"您的蓝牙未授权"];
            break;

        case CBCentralManagerStatePoweredOff:
            [MBProgressHUD showError:@"您的蓝牙处于关闭状态，请打开"];
            break;

        case CBCentralManagerStatePoweredOn:
            [central scanForPeripheralsWithServices:@[self.serviceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
            break;
            
        default:
            [MBProgressHUD showError:@"发生未知错误,请重试"];
            break;
    }
}

/**
 *  连接外设成功调用
 */
#pragma mark 连接外设成功调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    if ([peripheral.identifier.UUIDString isEqualToString:myUUID]) {
         [MBProgressHUD hideHUD];
       [MBProgressHUD showSuccess:[NSString stringWithFormat:@"成功连接了%@",peripheral.name]];
        self.peripheral = peripheral;
        [central stopScan];
        [peripheral discoverServices:@[self.serviceUUID]];
    }
}


/**
 *  断开连接
 */
#pragma makr - 断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSString *msg = [NSString stringWithFormat:@"断开连接%@,原因为:%@",peripheral.name,error];
    NSLog(@"断开连接%@,原因为:%@",peripheral.name,error);
    [MBProgressHUD showError:msg];
}

/**
 *  连接外设失败调用
 */
#pragma makr - 连接外设失败调用
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    [MBProgressHUD showError:[NSString stringWithFormat:@"连接%@失败,原因为:%@",peripheral.name,error]];
}

#pragma makr - CBPeripheralDelegate
/**
 *  只要扫描到服务就会调用
 *
 *  @param peripheral 服务所在的外设
 */
#pragma makr - 只要扫描到服务就会调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    
    if (error) {
        NSLog(@"Error discovering services: %@", error);
        return;
    }
    
     //获取外设中所有扫描到得服务
    for (CBService *service in peripheral.services) {
        // 拿到需要的服务
        if ([service.UUID isEqual:self.serviceUUID]) {
            // 从需要的服务中查找需要的特征
            // 从peripheral中得service中扫描特征
            [peripheral discoverCharacteristics:@[self.txCharacteristicUUID, self.rxCharacteristicUUID] forService:service];
        }
    }
}

/**
 *  只要扫描到特征就会调用
 *
 *  @param peripheral 特征所属的外设
 *  @param service    特征所属的服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error discovering characteristics: %@", error);
        return;
    }
    
    // 拿到服务中所有的特诊
    // 遍历特征, 拿到需要的特征处理
    for (CBCharacteristic *c in service.characteristics) {
        if ([c.UUID isEqual:self.rxCharacteristicUUID]) {
            NSLog(@"Found RX characteristic");
            self.rxCharacteristic = c;
            
            [self.peripheral setNotifyValue:YES forCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.txCharacteristicUUID]) {
            NSLog(@"Found TX characteristic");
            self.txCharacteristic = c;
        }
        else{
           NSLog(@"No RX TX characteristic Found");
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error receiving notification for characteristic %@: %@", characteristic, error);
        return;
    }
   
    if (characteristic == self.rxCharacteristic) {
         NSLog(@"Received data on a characteristic,值为:%@",[characteristic value]);
        
        //
    }

}

#pragma mark - tableView的数据源和代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    CBPeripheral *peripheral = self.peripherals[indexPath.row];
    if ([peripheral.identifier.UUIDString isEqualToString:myUUID]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - 连这个",peripheral.name];
    } else {
        cell.textLabel.text = peripheral.name;
    }
    cell.detailTextLabel.text = peripheral.identifier.UUIDString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBPeripheral *peripheral = self.peripherals[indexPath.row];
    [MBProgressHUD showMessage:[NSString stringWithFormat:@"正在连接%@",peripheral.name] toView:nil];
    [self.mgr connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
}

@end
