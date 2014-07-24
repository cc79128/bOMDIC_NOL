//
//  Peripheral.m
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/23.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import "Peripheral.h"

@interface Peripheral (Private)
-(UIView*) createMatchListTable;
-(void) showMatchList;

-(void) connectToPeripheral : (CBPeripheral*) peripheral;
-(void) reconnectToPheriphral;

-(void) setRuntimeMatchListTableView : (UITableView*) tableview;
-(UITableView*) getRuntimeMatchListTableView;

-(void) setRuntiumAlertView : (CustomIOS7AlertView*) alertview;
-(CustomIOS7AlertView*) getRuntimeAlertView;
-(void) EAEDCheck;
-(void) updatePeripheralScan;
@end

@interface Peripheral ()
@property (nonatomic, strong) CBPeripheral *myPeripheral;
@end

@implementation Peripheral {
    CBCentralManager *myCentralManager;
    NSMutableDictionary *characteristicDic;
    int currentHeaderIndex;
    NSMutableData *appendData;
    
    NSMutableArray *matchListArray;
    
    BOOL isReconnect;
    
    NSTimer *updatePeripheralScanTimer;
}

@synthesize flagSensorRequestOneFWSegment, flagSensorFWUpdateFinish, flagAppResetFlashForOTARequest, progressOTA, OTABinVer,deviceFirmwareRevision,deviceHardwareRevision,deviceManufactureName,deviceModelNumber,deviceSerialNumber,deviceSoftwareRevision;

#define kilojoule 239
#define KcalPerKJoule 0.239
#define MAGICTWGPSDISTTUNE 1.15
#define OTADEBUGB0 FALSE
#define OTADEBUGD0 FALSE

static const char RUNTIMEMATCHLISTTABLEVIEWPOINTER;
static const char RUNTIMEMALERTVIEWPOINTER;
static const char DISCOVERCOMPLETIONPOINTER;
NSString * fName; //Fw file name for OTA

#pragma mark - shared function

+(id) sharedPeripheral {
    static dispatch_once_t predicate;
    static Peripheral *sharedPeriphral = nil;
    dispatch_once(&predicate, ^{
        sharedPeriphral = [ [Peripheral alloc] init];
    });
    return sharedPeriphral;
}


#pragma mark - life cycle

- (id)init {
    if (self = [super init]) {
        _isConnectedToPeriphral = NO;
        
        //iOS7 only
        //myCentralManager = [ [CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
        myCentralManager = [ [CBCentralManager alloc] initWithDelegate:self queue:nil];
        characteristicDic = [ [NSMutableDictionary alloc] init];
        matchListArray = [[NSMutableArray alloc] init];
        
        //for record to file
        heartrateRecordArray = [NSMutableArray new];
        staminaRecordArray = [NSMutableArray new];
        staminaRowDataRecordArray = [NSMutableArray new];
        ECGOutputRecordArray = [NSMutableArray new];
        ECGRowDataRecordArray = [NSMutableArray new];
        
        // OTA
        flagAppResetFlashForOTARequest = FALSE;
        //OTABinVer = @"BMA41T";
        //OTABinVer = @"BMA41T0617";
        //OTABinVer = @"BMA40T0617";
        OTABinVer = @"BMA42A0619";
        fName = [[NSBundle mainBundle] pathForResource:OTABinVer ofType:@"bin"];
        
    }
    return self;
}

-(void) discoverPheriphral : (void (^)(BOOL isConnect)) completion {
    isReconnect = NO;
    objc_setAssociatedObject(self, &DISCOVERCOMPLETIONPOINTER, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:FALSE]};
    //NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber  numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    //只找有 180d 服務的device
    [myCentralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180d"]] options:options];
    
    //連接固定裝置，取消清單
    [self showMatchList];
}

-(void) disconnectFromPheriphral {
    if (self.myPeripheral) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ConnectedPeriphral"];
        [myCentralManager cancelPeripheralConnection:self.myPeripheral];
    }
    
    
    
}

-(void) connectToPeripheral : (CBPeripheral*) peripheral {
    
    [self disconnectFromPheriphral];
    
    self.myPeripheral = peripheral;
    self.myPeripheral.delegate = self;
    
    [myCentralManager connectPeripheral:self.myPeripheral options:nil];
    [myCentralManager stopScan];
    [updatePeripheralScanTimer invalidate];
    
    //do not need
    if (!isReconnect) [[self getRuntimeAlertView] close];
}

-(void) reconnectToPheriphral {
    isReconnect = YES;
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:FALSE]};
    //只找有 180d 服務的device
    [myCentralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180d"]] options:options];
}

/*
-(void) manualReconnectToPheriphral {
    [self connectToPeripheral:self.myPeripheral];
}
*/

-(void) setRuntimeMatchListTableView : (UITableView*) tableview {
    objc_setAssociatedObject(self, &RUNTIMEMATCHLISTTABLEVIEWPOINTER, tableview, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UITableView*) getRuntimeMatchListTableView {
    return objc_getAssociatedObject(self, &RUNTIMEMATCHLISTTABLEVIEWPOINTER);
}

-(void) setRuntiumAlertView : (CustomIOS7AlertView*) alertview {
    objc_setAssociatedObject(self, &RUNTIMEMALERTVIEWPOINTER, alertview, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CustomIOS7AlertView*) getRuntimeAlertView {
    return objc_getAssociatedObject(self, &RUNTIMEMALERTVIEWPOINTER);
}

-(UIView*) createMatchListTable {
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 219)];
    
    UITableView *matchListTableView = [[UITableView alloc] initWithFrame:containerView.bounds];
    [matchListTableView setDelegate:self];
    [matchListTableView setDataSource:self];
    [matchListTableView registerClass:[DiscoveringCell class] forCellReuseIdentifier:@"DiscoveringCell"];
    [matchListTableView registerClass:[PeripheralCell class] forCellReuseIdentifier:@"PeripheralCell"];
    [containerView addSubview:matchListTableView];
    
    [self setRuntimeMatchListTableView:matchListTableView];
    
    return containerView;
}

-(void) showMatchList {
    
    [matchListArray removeAllObjects];
    
    CustomIOS7AlertView *alertView = [[CustomIOS7AlertView alloc] init];
    [alertView setContainerView:[self createMatchListTable]];
    [alertView setButtonTitles:@[@"Cancel"]];
    [alertView setOnButtonTouchUpInside:^(CustomIOS7AlertView *alertView, int buttonIndex) {
        [myCentralManager stopScan];
        [updatePeripheralScanTimer invalidate];
        [alertView close];
    }];
    [alertView setUseMotionEffects:true];
    [alertView show];
    
    [self setRuntiumAlertView:alertView];
    
    updatePeripheralScanTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updatePeripheralScan) userInfo:nil repeats:YES];
}

-(void) updatePeripheralScan {

    [myCentralManager stopScan];
    
    NSMutableArray *tempMatchListArray = [[NSMutableArray alloc] init];
    
    //decrease lifetime of peripheral in scan list
    for (int i=0; i<[matchListArray count]; i++) {
        NSDictionary *eachPeripheral = [matchListArray objectAtIndex:i];
        NSInteger prevLT = [[eachPeripheral objectForKey:@"lifetime"] integerValue];
        NSInteger LT = prevLT - 1;
        
        NSMutableDictionary *tempPeripheral = [eachPeripheral mutableCopy];
        [tempPeripheral setValue:[NSNumber numberWithInteger:LT] forKey:@"lifetime"];
        [matchListArray replaceObjectAtIndex:i withObject:tempPeripheral];
        
        if (LT >= 0) {
            [tempMatchListArray addObject:tempPeripheral];
        }
    }
    
    //remove timeout peripheralin scan list
    [matchListArray removeAllObjects];
    matchListArray = [tempMatchListArray mutableCopy];
    
    //只找有 180d 服務的device
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:FALSE]};
    [myCentralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180d"]] options:options];
    
    [[self getRuntimeMatchListTableView] reloadData];

}

#pragma mark - UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView : (UITableView*) tableView {
    return 1;
}

-(NSInteger) tableView : (UITableView*) tableView numberOfRowsInSection : (NSInteger) section {
    return [matchListArray count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == [matchListArray count]) {
        static NSString *CellIdentifier = @"DiscoveringCell";
        DiscoveringCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        [cell.discoveringActivity startAnimating];
        return cell;
    } else {
        static NSString *CellIdentifier = @"PeripheralCell";
        PeripheralCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSDictionary *eachPeripheral = [matchListArray objectAtIndex:indexPath.row];
        
        cell.nameLabel.text = ((CBPeripheral*)[eachPeripheral objectForKey:@"peripheral"]).name;
        cell.uuidLabel.text = [((CBPeripheral*)[eachPeripheral objectForKey:@"peripheral"]).identifier UUIDString];
        cell.rssiLabel.text = [NSString stringWithFormat:@"%@", [eachPeripheral objectForKey:@"RSSI"]];
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != [matchListArray count]) {
        NSDictionary *eachPeripheral = [matchListArray objectAtIndex:indexPath.row];
        [self connectToPeripheral:((CBPeripheral*)[eachPeripheral objectForKey:@"peripheral"])];
    }
}


#pragma mark - CBCentralManager delegate

-(void) centralManagerDidUpdateState : (CBCentralManager*) central {
    NSLog(@"%s : %d",__FUNCTION__, central.state);
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"Power ON!");
            //[self discoverPheriphral];
            
            break;
        default:
            NSLog(@"default");
            break;
    }
}

-(void) centralManager : (CBCentralManager*) central didDiscoverPeripheral : (CBPeripheral*) peripheral advertisementData : (NSDictionary*) advertisementData RSSI : (NSNumber*)RSSI {
    
    NSLog(@"Discover Peripheral: Peripheral=%@, Data=%@, RSSI=%@, UUID=%@", peripheral.name, advertisementData, RSSI, [peripheral.identifier UUIDString]);
    
    if (isReconnect) {
        
        if ([[peripheral.identifier UUIDString] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"ConnectedPeriphral"]]) {
            [self connectToPeripheral:peripheral];
        }
        
    } else {
        
        int foundIndex = -1;
        
        for (int i=0; i<[matchListArray count]; i++) {
            NSDictionary *eachPeripheral = [matchListArray objectAtIndex:i];
            if ([[peripheral.identifier UUIDString] isEqualToString:[((CBPeripheral*)[eachPeripheral objectForKey:@"peripheral"]).identifier UUIDString]]) {
                foundIndex = i;
            }
        }
        
        if (foundIndex == -1) {
            // add new periphreal into matchlist
            [matchListArray addObject:@{@"peripheral": peripheral, @"advertisementData": advertisementData, @"RSSI": RSSI, @"lifetime": [NSNumber numberWithInteger:1]}];
        } else {
            // update existing periphreal & reset lifetime
            [matchListArray replaceObjectAtIndex:foundIndex
                                          withObject:@{@"peripheral": peripheral, @"advertisementData": advertisementData, @"RSSI": RSSI, @"lifetime": [NSNumber numberWithInteger:1]}];
        }
        
        
        [[self getRuntimeMatchListTableView] reloadData];
        
        /*
         if ([[peripheral.identifier UUIDString] isEqualToString:@"D2D4345D-7EC6-2E75-B620-2A49190DC1C5"]) {
         [self connectToPeripheral:peripheral];
         }
         */
        
    }
    
}

-(void) centralManager : (CBCentralManager*) central didConnectPeripheral : (CBPeripheral*) peripheral {
    NSLog(@"Connected!");
    
    
     [heartrateRecordArray removeAllObjects];
     [staminaRecordArray removeAllObjects];
     [staminaRowDataRecordArray removeAllObjects];
     [ECGOutputRecordArray removeAllObjects];
     [ECGRowDataRecordArray removeAllObjects];
     
    
    //把 ID 記起來
    [ [NSUserDefaults standardUserDefaults] setObject:[peripheral.identifier UUIDString] forKey:@"ConnectedPeriphral"];
    _isConnectedToPeriphral = YES;
    [peripheral discoverServices:nil];
    
    if (!isReconnect) {
        void (^completion)(BOOL isConnect) = objc_getAssociatedObject(self, &DISCOVERCOMPLETIONPOINTER);
        completion(NO);
    }
}

-(void) centralManager : (CBCentralManager*) central didFailToConnectPeripheral : (CBPeripheral*) peripheral error : (NSError*) error {
    _isConnectedToPeriphral = NO;
    NSLog(@"Connected fail");
    
    if (!isReconnect) {
        void (^completion)(BOOL isConnect) = objc_getAssociatedObject(self, &DISCOVERCOMPLETIONPOINTER);
        completion(YES);
    }
}

-(void) centralManager : (CBCentralManager*) central didDisconnectPeripheral : (CBPeripheral*) peripheral error : (NSError*) error {
    NSLog(@"disconnect");
    _isConnectedToPeriphral = NO;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ConnectedPeriphral"]) {
        NSLog(@"reconnect");
        [self reconnectToPheriphral];
    }
}

#pragma mark - CBPeripheral Delegate

-(void) peripheral : (CBPeripheral*) peripheral didDiscoverServices : (NSError*) error {
    
    NSLog(@"service count = %d",[peripheral.services count]);
    for (int i=0; i<[peripheral.services count]; i++) {
        
        CBService *service = [peripheral.services objectAtIndex:i];
        
        NSLog(@"Discovered service %@, CBUUID=%@", service, service.UUID);
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180f"]]) { //battery
            [peripheral discoverCharacteristics:nil forService:[peripheral.services objectAtIndex:i]];
            NSLog(@"Battery Service!");
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:@"180d"]]){ //heartRate
            [peripheral discoverCharacteristics:nil forService:[peripheral.services objectAtIndex:i]];
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:@"180a"]]){ //Device Info
            [peripheral discoverCharacteristics:nil forService:[peripheral.services objectAtIndex:i]];
            NSLog(@"Device Info Service");
        }
    }
}


-(void) peripheral : (CBPeripheral*) peripheral didDiscoverCharacteristicsForService : (CBService*) service error : (NSError*) error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@, CBUUID=%@, isNotify=%d", characteristic, characteristic.UUID, characteristic.isNotifying);
    }
    
    for (int i=0; i<[service.characteristics count]; i++) {
        
        CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a37"]]) { //notify
            //讀取數值
            //[peripheral readValueForCharacteristic:[service.characteristics objectAtIndex:0]];
            //追蹤數值
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            
            // timer for ECG Analysis & ECG Display Check
            _EAEDtenMsTicks = 200;
            
            _EAEDCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                               target:self
                                                             selector:@selector(EAEDCheck)
                                                             userInfo:nil
                                                              repeats:YES];
            
            _isECGAnalysisOpen = 0;
            _isECGDisplayOpen = 0;
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a38"]]){ //read
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a39"]]){ //write
            //NSString *valueStr = [ [NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            NSLog(@"2A39 : %@",characteristic.descriptors);
            [characteristicDic setObject:characteristic forKey:@"2a39"];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"7900"]]){ //notify
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"7901"]]){ //notify, ECG data
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            _isCompleteOneSecECG = 0;
            
            
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"7902"]]){ //write
            [characteristicDic setObject:characteristic forKey:@"7902"];
            /*
             unsigned char bytes[] = {0x0f, 0x1e, 0x4e, 0x78, 0x50};
             NSData* expectedData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
             
             //uint16_t val = 2;
             //NSData * valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
             [_myPeripheral writeValue:expectedData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
             NSLog(@"Found a Temperature Measurement Interval Characteristic - Write interval value");
             */
            
            
            //重設 stamina
            [self resetStamina];
            
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a19"]]){ // battery level
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a29"]]){ // read device info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a24"]]){ // model number info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a25"]]){ // serial number info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a27"]]){ // hardware revision info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a26"]]){ // firmware revision info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a28"]]){ // software revision info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a23"]]){ // system ID info
            [peripheral readValueForCharacteristic:characteristic];
            //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

-(void) peripheral : (CBPeripheral*) peripheral didUpdateValueForCharacteristic : (CBCharacteristic*) characteristic error : (NSError*) error {
    
    
    
    //NSLog(@"update uuid =%@, isConnected = %d",characteristic.UUID,_isConnectedToPeriphral);
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a37"]]) { //心跳
        
        NSData *data = characteristic.value;
        const char *byte = [data bytes];
        
        if (byte){
            //unsigned int length = [data length];
            //NSLog(@"data:%d, length=%d",byte[1],length);
            
            //NSLog(@"energy = %d",byte[3]+byte[2]);
            //char tempByte = byte[0];
            _signalQuality = (byte[0]>>1)&1;
            unsigned char uHR = byte[1];
            //save unsigned HR!
            NSString *HRStr = [NSString stringWithFormat:@"%d",uHR];
            NSLog(@"Heart Rate is, %@", HRStr);
            //save to array
            [heartrateRecordArray addObject:HRStr];
            
            _heartrateHistoryArray = heartrateRecordArray;
            
            _heartRate = HRStr;
            
            //unsigned char Byte3 = byte[3];
            //unsigned char Byte2 = byte[2];
            
            NSInteger KJoules = (unsigned char)byte[3]*256+(unsigned char)byte[2];
            float Kcal = KJoules * KcalPerKJoule;
            
            NSString *caloryStr = [NSString stringWithFormat:@"%d",(int)Kcal];
            _calories = caloryStr;
            
            
        }
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"7900"]]){ //stamina
        _EAEDtenMsTicks = 200;
        _isECGAnalysisOpen = 1;
        
        NSData *data = characteristic.value;
        
        const signed char *byte = [data bytes];
        unsigned int length = [data length];
        
        if (byte){
            unsigned char level = (byte[0] >> 4) & 0x0f;
            _levelOfStamina = (NSInteger) level;
            
            if (length>=3){
                //_ecgZoom = (unsigned int)byte[2];
                _rxEcgZoom = (unsigned int)byte[2];
                for (int i=0; i<length; i++) {
                    //NSLog(@"i:%d, stamina = %x, length=%d",i,byte[i],length);
                    NSString *rowdata = [NSString stringWithFormat:@"i:%d, rowdata:%x, length=%d",i,byte[i],length];
                    [staminaRowDataRecordArray addObject:rowdata];
                }
                
                
                NSLog(@"stamina data:%d, length=%d, quality=%d, ecgZoom=%d, oneECG=%d, Kcal=%@",byte[5],length,_signalQuality,_ecgZoom,_isCompleteOneSecECG, _calories);
                
                if (length >= 6) {
                    //正常的 7900 至少會有7個bytes jeff
                    //正常的 7900 至少會有6個bytes fixed by scott
                    NSString *staminaStr = [NSString stringWithFormat:@"%d",byte[5]];
                    _stamina = staminaStr;
                    
                    
                    
                    //save to file
                    NSString *staminaToArray = [NSString stringWithFormat:@"%d",byte[5]];
                    [staminaRecordArray addObject:staminaToArray];
                    
                    _staminaHistoryArray = staminaRecordArray;
                }
                else{
                    _stamina = @"0";
                }
            }
        }
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a19"]]){ //battery level
        
        NSData *data = characteristic.value;
        
        //NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        const char *byte = [data bytes];
        
        //unsigned int length = [data length];
        //NSLog(@"battery level data:%d, length=%d",byte[0],length);
        if (byte){
            NSString *batteryStr = [NSString stringWithFormat:@"%d",byte[0]];
            _battery_Level = batteryStr;
        }
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a29"]]){ //manufacture name
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        deviceManufactureName = dataStr;
        //NSLog(@"Manufacturer Name String 2a29 Data:%@",data);
        NSLog(@"[2a29] Manufacturer Name:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a24"]]){ //model number
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        deviceModelNumber = dataStr;
        //NSLog(@"Model number String 2a24 Data:%@",data);
        NSLog(@"[2a24] Model number:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a25"]]){ //serial number
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        deviceSerialNumber = dataStr;
        //NSLog(@"Serial number String 2a25 Data:%@",data);
        NSLog(@"[2a25] Serial number:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a27"]]){ //Hardware revision
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        deviceHardwareRevision = dataStr;
        //NSLog(@"Hardware revision String 2a27 Data:%@",data);
        NSLog(@"[2a27] Hardware revision:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a26"]]){ //Firmware revision
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        deviceFirmwareRevision = dataStr;
        //NSLog(@"Firmware revision String 2a29 Data:%@",data);
        NSLog(@"[2a29] Firmware revision:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a28"]]){ //Software revision
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        deviceSoftwareRevision = dataStr;
        //NSLog(@"Software revision String 2a28 Data:%@",data);
        NSLog(@"[2a28] Software revision:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2a23"]]){ //System ID
        
        NSData *data = characteristic.value;
        NSString *dataStr = [ [NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        //NSLog(@"System ID String 2a23 Data:%@",data);
        NSLog(@"[2a23] System ID:%@",dataStr);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"7901"]]){
        
        _isECGDisplayOpen = 1;
        
        NSData *data = characteristic.value;
        
        if (data) {
            
            const unsigned char *byte = [data bytes];
            unsigned int length = [data length];
            
            for (int i=0; i<length; i++) {
                NSString *rowdata = [NSString stringWithFormat:@"index:%d, rowdata:%x",i,byte[i]];
                // need to change a place ?
                [ECGRowDataRecordArray addObject:rowdata];
            }
            
            //NSLog(@"currentHeaderIndex = %d, header=%d, data length=%d",currentHeaderIndex,byte[0],length);
            if (byte[0] <= 17){
                
                if (byte[0] == 1) { // 編號第1號封包
                    
                    currentHeaderIndex = 1;
                    appendData = [ [NSMutableData alloc] init];
                    
                    //去除 header 接在 appenData 後面
                    
                    unsigned char dataByte[20];
                    [data getBytes:dataByte range:NSMakeRange(1,length-1)];
                    [appendData appendBytes:dataByte length:length-1];
                    
                    //NSLog(@"appendData length=%d",appendData.length);
                    
                }
                else if(byte[0] == currentHeaderIndex){ //確保依序接上
                    
                    unsigned char dataByte[20];
                    [data getBytes:dataByte range:NSMakeRange(1,length-1)];
                    [appendData appendBytes:dataByte length:length-1];
                    
                    //NSLog(@"appendData length=%d",appendData.length);
                    
                    if(byte[0] == 17){ //全部接完後存起來
                        
                        //NSLog(@"appendData : %@",appendData);
                        _ECGRawData = appendData;
                        
                        _isCompleteOneSecECG = 1;
                        
                        _ecgZoom = _rxEcgZoom;
                        //NSLog(@"RawData = %@",_ECGRawData);
                        
                        
                        NSString *convertedString = [[NSString alloc] initWithData:appendData encoding:NSUTF8StringEncoding];
                        NSData *base64Data = [ [NSData alloc] initWithBase64EncodedString:convertedString options:0];
                        const unsigned char *byte64 = [base64Data bytes];
                        //NSLog(@"base64Data = %@, length=%d",base64Data,base64Data.length);
                        for (int i =0; i<base64Data.length; i++) {
                            //NSLog(@"byte %d : %d",i,byte64[i]);
                            NSString *ECGToFile = [NSString stringWithFormat:@"index:%d, data:%d",i,byte64[i]];
                            [ECGOutputRecordArray addObject:ECGToFile];
                        }
                        
                        
                        
                        //NSLog(@"decode data = %@, length=%d",convertedString,convertedString.length);
                        
                    }
                    
                }
                currentHeaderIndex++;
                
            }
            else if (byte[0] == 0xD3){
                
                _genderInSensor = byte[1] & 0x01;
                _ageInSensor = (unsigned char)byte[2];
                _heightInSensor = (unsigned char)byte[3];
                _weightInSensor = (unsigned char)byte[4];
                _maxHRInSensor = (unsigned char)byte[5];
                _restHRInSensor = (unsigned char)byte[6];
                
            }
            else {
                _dataFromOTA = byte[0];
                if(_dataFromOTA == 0xD0){
                    flagSensorRequestOneFWSegment = TRUE;
                    
                    // retrive addr requested by OTA
                    if (length == 3) {
                        _addrRequestFromOTA = (NSUInteger)byte[1]*256 + (NSUInteger)byte[2];
                        
                        NSLog(@"Data From OTA : %02x req addr: %04x",_dataFromOTA, _addrRequestFromOTA);
                    }
                }
                if (flagAppResetFlashForOTARequest == TRUE){
                    [self setOTAUpdatetoDevice];
                }
            }
            
            if (OTADEBUGB0 || OTADEBUGD0) {
                NSLog(@"7901 Data:%@",data);
            }
            
        }
        
        
    }
}


-(void) peripheral : (CBPeripheral*) peripheral didUpdateNotificationStateForCharacteristic : (CBCharacteristic*) characteristic error : (NSError*) error {
    if (error) {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    }
    else{
        NSLog(@"Subscribing %@ value",characteristic.UUID);
    }
}

-(void) peripheral : (CBPeripheral*) peripheral didWriteValueForCharacteristic : (CBCharacteristic*) characteristic error : (NSError*) error {
    if (error) {
        NSLog(@"Error writing characteristic value: %@", [error localizedDescription]);
    }
    else {
        //NSLog(@"write data to %@ success",characteristic.UUID)
    }
}

#pragma mark - Sensor Data Processing

-(void) EAEDCheck {
    
    
    if (self.isConnectedToPeriphral) {
        // timeout & didnot receive ECG analysis
        if (_EAEDtenMsTicks == 0) {
            
            [self toggleECGAnalysis];
            [self toggleECGDisplay];
            // wait another period
            _EAEDtenMsTicks = 200;
            
        }
        else if (_EAEDtenMsTicks > 0) {
            _EAEDtenMsTicks--;
        }
        
    }
    
}

-(void) setOTAUpdatetoDevice {
    
    NSData * binData = [[NSData alloc] init];
    
    if (fName) {
        binData = [NSData dataWithContentsOfFile:fName];
    }
    
    unsigned int writeAddr = 0x0000;
    
    if (self.dataFromOTA == 0xB0) {
        // find the end of Firmware Binary
        //unsigned int binLength = 0x160;
        unsigned int binTotalLength = [binData length];
        unsigned int binAvbLength = binTotalLength;
        const unsigned char ffBinByte[16]={0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff};//16 0xff bytes
        NSData *ffData = [NSData dataWithBytes:ffBinByte length:16];
        
        for (int i=binTotalLength; i>0; i-=16)
        {
            NSData * chkBinDataLine = [binData subdataWithRange:NSMakeRange(i-16,16)];
            if (![chkBinDataLine isEqualToData:ffData]) {
                binAvbLength = i;
                break;
            }
            
        }
        unsigned int binLength = binAvbLength;
        
        NSData * avbBinData = [binData subdataWithRange:NSMakeRange(0,binLength)];
        const unsigned char *avbBinByte = [avbBinData bytes];
        unsigned int chksumInt = 0;
        for (int i = 0; i<binLength; i++) {
            chksumInt += avbBinByte[i];
        }
        chksumInt = 256 - (chksumInt % 256);
        
        if (OTADEBUGB0) { chksumInt = 0; }
        
        
        NSString *OTABootCheckHead = @"B0";
        _finalOTAAddr = binLength - 1;
        
        NSMutableString *mutString = [OTABootCheckHead mutableCopy];
        [mutString appendString:[NSString stringWithFormat:@"%04x",_finalOTAAddr]];
        [mutString appendString:[NSString stringWithFormat:@"%02x",chksumInt]];
        NSData * segFWData = Nil;//no payload
        // send OTA update response
        [self setDatatoDevice:mutString withNSData:segFWData];
        
        //[self disconnectFromPheriphral]; // for OTA exception test
        
        writeAddr = 0x0000;
        self.flagSensorRequestOneFWSegment = FALSE;
        
        NSLog(@"OTA start command: %@", mutString);
    }
    else if (self.dataFromOTA == 0xD0 && self.flagSensorRequestOneFWSegment == TRUE){
        // prepare firmware segments
        writeAddr = _addrRequestFromOTA;
        
        NSString *OTADataUpdateHead = @"D0";
        NSData * segFWData = [binData subdataWithRange:NSMakeRange(writeAddr,16)]; // a pkt has 16 byte FW segment
        
        NSMutableString *mutString = [OTADataUpdateHead mutableCopy];
        
        if (!OTADEBUGD0) {
            [mutString appendString:[NSString stringWithFormat:@"%04x",writeAddr]];
        }
        else {
            [mutString appendString:[NSString stringWithFormat:@"%04x",0x0010]];
        }
        
        [self setDatatoDevice:mutString withNSData:segFWData];
        
        progressOTA = (NSUInteger)((float)writeAddr / (float)(_finalOTAAddr - 0xF) *100 );
        NSLog(@"progressOTA is:%d%%",progressOTA);

        
        //reset flagSensorRequestOneFWSegment
        self.flagSensorRequestOneFWSegment = FALSE;
        
        //NSLog(@"write Data to addr: %@", [NSString stringWithFormat:@"%04x",writeAddr]);
        
        //writeAddr += 0x0010;
    }
    else if (self.dataFromOTA == 0x1D){
        //writeAddr = 0x0000;
        self.flagSensorRequestOneFWSegment = FALSE;
        self.flagAppResetFlashForOTARequest = FALSE;
        NSLog(@"OTA Done");
    }
    else if (self.dataFromOTA == 0x1E){
        //writeAddr = 0x0000;
        self.flagSensorRequestOneFWSegment = FALSE;
        self.flagAppResetFlashForOTARequest = FALSE;
        NSLog(@"OTA Boot Timeout");
        
    }
    else if (self.dataFromOTA == 0xCF){
        //writeAddr = 0x0000;
        self.flagSensorRequestOneFWSegment = FALSE;
        //self.flagAppResetFlashForOTARequest = FALSE;
        NSLog(@"OTA Format Error");
        
    }
    else if (self.dataFromOTA == 0xFA){
        //writeAddr = 0x0000;
        self.flagSensorRequestOneFWSegment = FALSE;
        //self.flagAppResetFlashForOTARequest = FALSE;
        NSLog(@"OTA Done CheckSum Error");
        //[self disconnectFromPheriphral]; // for OTA exception test
    }
    else{
        NSLog(@"OTA exceptions with command:0x%@",[NSString stringWithFormat:@"%02x",self.dataFromOTA]);
    }
}


-(void) resetStamina {
    NSLog(@"resetStamina");
    unsigned char bytes[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x03};
    NSData* expectedData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [self.myPeripheral writeValue:expectedData forCharacteristic:[characteristicDic objectForKey:@"7902"] type:CBCharacteristicWriteWithResponse];
}

-(void) toggleECGDisplay {
    NSLog(@"toggleECGDisplay");
    unsigned char bytes[] = {0xED};
    NSData* expectedData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [self.myPeripheral writeValue:expectedData forCharacteristic:[characteristicDic objectForKey:@"7902"] type:CBCharacteristicWriteWithResponse];
}

-(void) toggleECGAnalysis {
    NSLog(@"toggleECGAnalysis");
    unsigned char bytes[] = {0xEA};
    NSData* expectedData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [self.myPeripheral writeValue:expectedData forCharacteristic:[characteristicDic objectForKey:@"7902"] type:CBCharacteristicWriteWithResponse];
}

-(void) resetEnergy {
    NSLog(@"resetEnergy");
    uint16_t val = 1;
    NSData * valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
    [self.myPeripheral writeValue:valData forCharacteristic:[characteristicDic objectForKey:@"2a39"] type:CBCharacteristicWriteWithResponse];
}

-(void) setFEtoDevice {
    NSString *cmdHead = @"FE";
    NSMutableString *mutString = [cmdHead mutableCopy];
    NSData * segFWData = Nil;//no payload
    [self setDatatoDevice:mutString withNSData:segFWData];
}

-(void) setB1toDevice {
    NSString *cmdHead = @"B1";
    NSMutableString *mutString = [cmdHead mutableCopy];
    NSData * segFWData = Nil;//no payload
    [self setDatatoDevice:mutString withNSData:segFWData];
}

-(void) setB2toDevice {
    NSString *cmdHead = @"B2";
    NSMutableString *mutString = [cmdHead mutableCopy];
    NSData * segFWData = Nil;//no payload
    [self setDatatoDevice:mutString withNSData:segFWData];
}

-(void) setB3toDevice {
    NSString *cmdHead = @"B3";
    NSMutableString *mutString = [cmdHead mutableCopy];
    NSData * segFWData = Nil;//no payload
    [self setDatatoDevice:mutString withNSData:segFWData];
}

-(void) setDatatoDevice:(NSMutableString *)mutString withNSData:(NSData *)loadNSData {
    
    unsigned char bytes[[mutString length]/2];//every two hex numbers in NSString will form a byte in NSData
    
    for (int i =0; i<[mutString length]; i+=2) {
        NSString* subString = [mutString substringWithRange:NSMakeRange(i,2)];
        
        unsigned int outVal;
        unsigned char mCode;
        
        NSScanner* scanner = [NSScanner scannerWithString:subString];
        [scanner scanHexInt:&outVal];
        mCode = outVal;
        bytes[i/2] = mCode;
        
    }
    NSMutableData* expectedMutData = [NSMutableData dataWithBytes:bytes length:sizeof(bytes)];
    //NSData *expectedLoadData = [[NSData alloc] initWithData:loadNSData];
    if (loadNSData) {
        [expectedMutData appendData:loadNSData];
    }
    //NSLog(@"set Data Done: %@", expectedMutData);
    
    [self.myPeripheral writeValue:expectedMutData forCharacteristic:[characteristicDic objectForKey:@"7902"] type:CBCharacteristicWriteWithResponse];
    
    NSLog(@"set Data Done: %@", expectedMutData);
    
}

-(void) updateUserSetting {
    NSString *updateUserSettingHead = @"D3";
    NSMutableString *mutString = [updateUserSettingHead mutableCopy];
    NSData * segFWData = Nil;//no payload
    // send updateUserSetting command
    [self setDatatoDevice:mutString withNSData:segFWData];
}


@end
