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
    
    updatePeripheralScanTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(updatePeripheralScan) userInfo:nil repeats:YES];
}

-(void) updatePeripheralScan {

    //[matchListArray removeAllObjects];
    [myCentralManager stopScan];
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:FALSE]};
    //只找有 180d 服務的device
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
            [matchListArray addObject:@{@"peripheral": peripheral, @"advertisementData": advertisementData, @"RSSI": RSSI}];
        } else {
            
            [matchListArray replaceObjectAtIndex:foundIndex
                                          withObject:@{@"peripheral": peripheral, @"advertisementData": advertisementData, @"RSSI": RSSI}];
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
    /*
     // timer for ECG Analysis & ECG Display Check
     _EADAtenMsTicks = 200;
     _EAEDCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
     target:self
     selector:@selector(EAEDCheck)
     userInfo:nil
     repeats:YES];
     
     _isECGAnalysisOpen = 0;
     _isECGDisplayOpen = 0;
     */
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




@end
