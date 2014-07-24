//
//  Peripheral.h
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/23.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <objc/runtime.h>

#import "CustomIOS7AlertView.h"
#import "DiscoveringCell.h"
#import "PeripheralCell.h"

@interface Peripheral : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>{
    NSMutableArray *heartrateRecordArray;
    NSMutableArray *staminaRecordArray;
    NSMutableArray *staminaRowDataRecordArray;
    NSMutableArray *ECGRowDataRecordArray;
    NSMutableArray *ECGOutputRecordArray;
    
}

+(id) sharedPeripheral;

-(void) discoverPheriphral : (void (^)(BOOL isConnect)) completion;
-(void) disconnectFromPheriphral;
//-(void) reconnectToPheriphral;
//-(void) manualReconnectToPheriphral;
-(void) resetStamina;
-(void) resetEnergy;
-(void) toggleECGDisplay;
-(void) toggleECGAnalysis;
//-(NSString *) saveRecordToFile;
-(void) setDatatoDevice:(NSMutableString *)mutString withNSData:(NSData *)loadNSData;
-(void) setOTAUpdatetoDevice;
//-(void) staminaTest;
-(void) updateUserSetting;

// test command
-(void) setFEtoDevice;
-(void) setB1toDevice;
-(void) setB2toDevice;
-(void) setB3toDevice;

@property (readonly, nonatomic) NSString *heartRate;
@property (readonly, nonatomic) NSString *battery_Level;
@property (readonly, nonatomic) NSString *stamina;
@property (readonly, nonatomic) NSString *calories;
@property (readonly, nonatomic) NSData *ECGRawData;
@property (readonly, nonatomic) NSArray *heartrateHistoryArray;
@property (readonly, nonatomic) NSArray *staminaHistoryArray;
@property (readonly, nonatomic) NSArray *estSpdIncHistoryArray;
@property (readonly, nonatomic) NSArray *testStaminaHistoryArray;
@property (readonly, nonatomic) NSArray *testHeartrateHistoryArray;
@property (readonly, nonatomic) BOOL isConnectedToPeriphral;
@property (readonly, nonatomic) BOOL isCompleteOneSecECG;
@property (readonly, nonatomic) NSInteger isECGAnalysisOpen;
@property (readonly, nonatomic) NSInteger isECGDisplayOpen;
@property (readonly, nonatomic) BOOL signalQuality;
@property (readonly, nonatomic) NSInteger ecgZoom;
@property NSInteger EAEDtenMsTicks;
@property (nonatomic) NSTimer  *EAEDCheckTimer;
@property (readonly, nonatomic) NSInteger levelOfStamina;


//for OTA flags
@property (readonly, nonatomic) NSInteger dataFromOTA;
@property (readonly, nonatomic) NSUInteger addrRequestFromOTA;
@property BOOL flagSensorRequestOneFWSegment;
@property BOOL flagSensorFWUpdateFinish;
@property BOOL flagAppResetFlashForOTARequest;
@property (readonly, nonatomic) NSString *OTABinVer;
@property (readonly, nonatomic) NSUInteger progressOTA;
@property (readonly, nonatomic) NSUInteger finalOTAAddr;


//for real linechart display
@property (readonly, nonatomic) NSInteger ageInSensor;
@property (readonly, nonatomic) NSInteger weightInSensor;
@property (readonly, nonatomic) NSInteger heightInSensor;
@property (readonly, nonatomic) NSInteger maxHRInSensor;
@property (readonly, nonatomic) NSInteger restHRInSensor;
@property (readonly, nonatomic) BOOL genderInSensor;

// device info 180a
@property (readonly, nonatomic) NSString *deviceManufactureName;
@property (readonly, nonatomic) NSString *deviceModelNumber;
@property (readonly, nonatomic) NSString *deviceSerialNumber;
@property (readonly, nonatomic) NSString *deviceHardwareRevision;
@property (readonly, nonatomic) NSString *deviceFirmwareRevision;
@property (readonly, nonatomic) NSString *deviceSoftwareRevision;
@property (readonly, nonatomic) NSString *deviceSystemID;


@end
