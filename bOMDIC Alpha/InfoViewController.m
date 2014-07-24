//
//  InfoViewController.m
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/22.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import "InfoViewController.h"
#import "Peripheral.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
}

- (void)viewWillAppear:(BOOL)animated
{

    Peripheral *sharedPeripheral = [Peripheral sharedPeripheral];
    _fwVerInSensorLabel.text = sharedPeripheral.deviceFirmwareRevision;
    _manufactureNameLabel.text = sharedPeripheral.deviceManufactureName;
    _modelNumberLabel.text = sharedPeripheral.deviceModelNumber;
    _serialNumberLabel.text = sharedPeripheral.deviceSerialNumber;
    _hardwareVerLabel.text = sharedPeripheral.deviceHardwareRevision;
    _softwareVerLabel.text = sharedPeripheral.deviceSoftwareRevision;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
